//
//  PaymentViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 6/30/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt
import UIKit

class PaymentViewModel {
    let disposeBag = DisposeBag()

    private var walletService: WalletService
    private var paymentService: PaymentService

    let accountDetail: Variable<AccountDetail>

    let isFetching = Variable(false)
    let isError = Variable(false)

    let walletItems = Variable<[WalletItem]?>(nil)
    let selectedWalletItem = Variable<WalletItem?>(nil)
    let wouldBeSelectedWalletItemIsExpired = Variable(false)

    let amountDue: Variable<Double>
    let paymentAmount: Variable<Double>
    let paymentDate: Variable<Date>

    let termsConditionsSwitchValue = Variable(false)
    let overpayingSwitchValue = Variable(false)
    let activeSeveranceSwitchValue = Variable(false)

    let paymentId = Variable<String?>(nil)

    var confirmationNumber: String?

    init(walletService: WalletService,
         paymentService: PaymentService,
         accountDetail: AccountDetail,
         billingHistoryItem: BillingHistoryItem?) {
        self.walletService = walletService
        self.paymentService = paymentService
        self.accountDetail = Variable(accountDetail)
        
        if let billingHistoryItem = billingHistoryItem { // Editing a payment
            paymentId.value = billingHistoryItem.paymentId
            selectedWalletItem.value = WalletItem(maskedWalletItemAccountNumber: billingHistoryItem.maskedWalletItemAccountNumber,
                                                  paymentMethodType: billingHistoryItem.paymentMethodType,
                                                  isEditingItem: true)
        }

        amountDue = Variable(accountDetail.billingInfo.netDueAmount ?? 0)
        paymentAmount = Variable(billingHistoryItem?.amountPaid ?? 0)
        paymentDate = Variable(billingHistoryItem?.date ?? .now) // May be updated later...see computeDefaultPaymentDate()
    }

    // MARK: - Service Calls

    func fetchData(initialFetch: Bool, onSuccess: (() -> ())?, onError: (() -> ())?) {
        isFetching.value = true
        walletService.fetchWalletItems()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] walletItems in
                guard let self = self else { return }
                self.isFetching.value = false
                
                self.walletItems.value = walletItems
                guard let walletItems = self.walletItems.value else { return }
                let defaultWalletItem = walletItems.first(where: { $0.isDefault })

                if initialFetch {
                    self.computeDefaultPaymentDate()
                    if self.paymentId.value == nil { // If not modifiying payment
                        if self.accountDetail.value.isCashOnly {
                            if defaultWalletItem?.bankOrCard == .card { // Select the default item IF it's a credit card
                                self.selectedWalletItem.value = defaultWalletItem!
                            } else if let firstCard = walletItems.first(where: { $0.bankOrCard == .card }) {
                                // If no default item, choose the first credit card
                                self.selectedWalletItem.value = firstCard
                            }
                        } else {
                            if defaultWalletItem != nil { // Choose the default item
                                self.selectedWalletItem.value = defaultWalletItem!
                            } else if walletItems.count > 0 { // If no default item, choose the first item
                                self.selectedWalletItem.value = walletItems.first
                            }
                        }
                    }
                }

                if let walletItem = self.selectedWalletItem.value, walletItem.isExpired {
                    self.selectedWalletItem.value = nil
                    self.wouldBeSelectedWalletItemIsExpired.value = true
                }

                onSuccess?()
            }, onError: { [weak self] _ in
                self?.isFetching.value = false
                self?.isError.value = true
                onError?()
            }).disposed(by: disposeBag)
    }

    func schedulePayment(onDuplicate: @escaping (String, String) -> Void,
                         onSuccess: @escaping () -> Void,
                         onError: @escaping (ServiceError) -> Void) {
        self.paymentService.schedulePayment(accountNumber: self.accountDetail.value.accountNumber,
                                            paymentAmount: self.paymentAmount.value,
                                            paymentDate: self.paymentDate.value,
                                            walletId: AccountsStore.shared.customerIdentifier,
                                            walletItem: self.selectedWalletItem.value!)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] confirmationNumber in
                self?.confirmationNumber = confirmationNumber
                onSuccess()
            }, onError: { err in
                onError(err as! ServiceError)
            })
            .disposed(by: self.disposeBag)
    }

    func cancelPayment(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        paymentService.cancelPayment(accountNumber: accountDetail.value.accountNumber,
                                     paymentId: paymentId.value!)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onSuccess()
            }, onError: { err in
                onError(err.localizedDescription)
            })
            .disposed(by: disposeBag)
    }

    func modifyPayment(onSuccess: @escaping () -> Void, onError: @escaping (ServiceError) -> Void) {
        self.paymentService.updatePayment(paymentId: self.paymentId.value!,
                                          accountNumber: self.accountDetail.value.accountNumber,
                                          paymentAmount: self.paymentAmount.value,
                                          paymentDate: self.paymentDate.value,
                                          walletId: AccountsStore.shared.customerIdentifier,
                                          walletItem: self.selectedWalletItem.value!)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onSuccess()
            }, onError: { err in
                onError(err as! ServiceError)
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Payment Date Stuff
    
    func computeDefaultPaymentDate() {
        if paymentId.value != nil { return } // We don't want the date being set/reset during the edit workflow
        
        if Environment.shared.opco == .bge {
            paymentDate.value = .now
        } else {
            let acctDetail = accountDetail.value
            let billingInfo = acctDetail.billingInfo
            
            // Covers precarious states 6, 5, and 4 (in that order) on the Billing Scenarios table
            if (acctDetail.isFinaled && billingInfo.pastDueAmount > 0) ||
                (acctDetail.isCutOutIssued && billingInfo.disconnectNoticeArrears > 0) ||
                (acctDetail.isCutOutNonPay && billingInfo.restorationAmount > 0) {
                paymentDate.value = .now
            }
            
            // All the other states boil down to the due date being in the future
            if let dueDate = billingInfo.dueByDate {
                paymentDate.value = isDueDateInTheFuture ? dueDate : .now
            } else { // Should never get here?
                paymentDate.value = .now
            }
        }
    }
    
    var canEditPaymentDate: Bool {        
        let accountDetail = self.accountDetail.value
        let billingInfo = accountDetail.billingInfo
        
        // Existing requirement from before Paymentus
        if Environment.shared.opco == .bge && accountDetail.isActiveSeverance {
            return false
        }
        
        // Precarious state 6: BGE can future date, ComEd/PECO cannot
        if accountDetail.isFinaled && billingInfo.pastDueAmount > 0 {
            return Environment.shared.opco == .bge
        }
        
        // Precarious states 4 and 5 cannot future date
        if (accountDetail.isCutOutIssued && billingInfo.disconnectNoticeArrears > 0) ||
            (accountDetail.isCutOutNonPay && billingInfo.restorationAmount > 0) {
            return false
        }
        
        // Precarious state 3
        if !accountDetail.isCutOutIssued && billingInfo.disconnectNoticeArrears > 0 {
            return Environment.shared.opco == .bge || isDueDateInTheFuture
        }
        
        // All the other states boil down to the due date being in the future
        return isDueDateInTheFuture
    }
    
    private var isDueDateInTheFuture: Bool {
        let startOfTodayDate = Calendar.opCo.startOfDay(for: .now)
        if let dueDate = accountDetail.value.billingInfo.dueByDate {
            if dueDate <= startOfTodayDate {
                return false
            }
        }
        return true
    }
    
    private(set) lazy var shouldShowPaymentDateView: Driver<Bool> =
        Driver.combineLatest(self.hasWalletItems, self.paymentId.asDriver()) {
            $0 || $1 != nil
        }

    private(set) lazy var paymentDateString: Driver<String> = paymentDate.asDriver()
        .map { $0.mmDdYyyyString }

    // MARK: - Shared Drivers

    private(set) lazy var paymentAmountString = paymentAmount.asDriver()
        .map { $0.currencyString }

    private(set) lazy var paymentFieldsValid: Driver<Bool> = Driver
        .combineLatest(shouldShowContent, paymentAmountErrorMessage) {
            return $0 && $1 == nil
        }

    // MARK: - Other Make Payment Drivers
    
    private(set) lazy var makePaymentNextButtonEnabled: Driver<Bool> = Driver
        .combineLatest(selectedWalletItem.asDriver(), paymentFieldsValid) {
            return $0 != nil && $1
        }

    private(set) lazy var isCashOnlyUser: Driver<Bool> = self.accountDetail.asDriver().map { $0.isCashOnly }

    private(set) lazy var isActiveSeveranceUser: Driver<Bool> = self.accountDetail.asDriver().map { $0.isActiveSeverance }

    private(set) lazy var shouldShowContent: Driver<Bool> =
        Driver.combineLatest(self.isFetching.asDriver(),
                             self.isError.asDriver())
        { !$0 && !$1 }

    private(set) lazy var shouldShowPaymentAccountView: Driver<Bool> =
        Driver.combineLatest(self.selectedWalletItem.asDriver(),
                             self.wouldBeSelectedWalletItemIsExpired.asDriver())
        {
            if $1 {
                return true
            }
            return $0 != nil
        }

    private(set) lazy var hasWalletItems: Driver<Bool> =
        Driver.combineLatest(self.walletItems.asDriver(),
                             self.isCashOnlyUser,
                             self.selectedWalletItem.asDriver())
        {
            guard let walletItems: [WalletItem] = $0 else { return false }
            if $1 { // If only bank accounts, treat cash only user as if they have no wallet items
                for item in walletItems {
                    if item.bankOrCard == .card {
                        return true
                    }
                }
                if let selectedWalletItem = $2, selectedWalletItem.isTemporary, selectedWalletItem.bankOrCard == .card {
                    return true
                }
                return false
            } else {
                if let selectedWalletItem = $2, selectedWalletItem.isTemporary {
                    return true
                }
                return walletItems.count > 0
            }
        }

    private(set) lazy var shouldShowPaymentAmountTextField: Driver<Bool> = Driver
        .combineLatest(hasWalletItems, paymentId.asDriver())
        { $0 || $1 != nil }

    private(set) lazy var paymentAmountErrorMessage: Driver<String?> = {
        return Driver.combineLatest(selectedWalletItem.asDriver(),
                                    accountDetail.asDriver(),
                                    paymentAmount.asDriver(),
                                    amountDue.asDriver())
        { (walletItem, accountDetail, paymentAmount, amountDue) -> String? in
            guard let walletItem = walletItem else { return nil }
            if walletItem.bankOrCard == .bank {
                let minPayment = accountDetail.billingInfo.minPaymentAmount
                let maxPayment = accountDetail.billingInfo.maxPaymentAmount(bankOrCard: .bank)
                if Environment.shared.opco == .bge {
                    if paymentAmount < minPayment {
                        return NSLocalizedString("Minimum payment allowed is \(minPayment.currencyString)", comment: "")
                    } else if paymentAmount > maxPayment {
                        return NSLocalizedString("Maximum payment allowed is \(maxPayment.currencyString)", comment: "")
                    }
                } else {
                    if paymentAmount < minPayment {
                        return NSLocalizedString("Minimum payment allowed is \(minPayment.currencyString)", comment: "")
                    } else if paymentAmount > amountDue {
                        return NSLocalizedString("Payment must be less than or equal to total amount due", comment: "")
                    } else if paymentAmount > maxPayment {
                        return NSLocalizedString("Maximum payment allowed is \(maxPayment.currencyString)", comment: "")
                    }
                }
            } else {
                let minPayment = accountDetail.billingInfo.minPaymentAmount
                let maxPayment = accountDetail.billingInfo.maxPaymentAmount(bankOrCard: .card)
                if Environment.shared.opco == .bge {
                    if paymentAmount < minPayment {
                        return NSLocalizedString("Minimum payment allowed is \(minPayment.currencyString)", comment: "")
                    } else if paymentAmount > maxPayment {
                        return NSLocalizedString("Maximum payment allowed is \(maxPayment.currencyString)", comment: "")
                    }
                } else {
                    if paymentAmount < minPayment {
                        return NSLocalizedString("Minimum payment allowed is \(minPayment.currencyString)", comment: "")
                    } else if paymentAmount > amountDue {
                        return NSLocalizedString("Payment must be less than or equal to total amount due", comment: "")
                    } else if paymentAmount > maxPayment {
                        return NSLocalizedString("Maximum payment allowed is \(maxPayment.currencyString)", comment: "")
                    }
                }
            }
            return nil
        }
    }()

    private(set) lazy var shouldShowSelectPaymentAmount: Driver<Bool> = self.selectedWalletItem.asDriver().map { [weak self] in
        guard let self = self else { return false }
        guard let bankOrCard = $0?.bankOrCard else { return false }

        if self.paymentAmounts.isEmpty {
            return false
        }

        let min = self.accountDetail.value.billingInfo.minPaymentAmount
        let max = self.accountDetail.value.billingInfo.maxPaymentAmount(bankOrCard: bankOrCard)
        for paymentAmount in self.paymentAmounts {
            guard let amount = paymentAmount.0 else { continue }
            if amount < min || amount > max {
                return false
            }
        }
        return true
    }

    /**
     Some funky logic going on here. Basically, there are three cases in which we just return []

     1. No pastDueAmount
     2. netDueAmount == pastDueAmount, no other precarious amounts exist
     3. netDueAmount == pastDueAmount == other precarious amount (restorationAmount, amtDpaReinst, disconnectNoticeArrears)

     In these cases we don't give the user multiple payment amount options, just the text field.
    */
    lazy var paymentAmounts: [(Double?, String)] = {
        let billingInfo = accountDetail.value.billingInfo

        guard let netDueAmount = billingInfo.netDueAmount,
            let pastDueAmount = billingInfo.pastDueAmount,
            pastDueAmount > 0 else {
            return []
        }

        let totalAmount: (Double?, String)
        if pastDueAmount == netDueAmount {
            totalAmount = (netDueAmount, NSLocalizedString("Total Past Due Amount", comment: ""))
        } else {
            totalAmount = (netDueAmount, NSLocalizedString("Total Amount Due", comment: ""))
        }

        let pastDue: (Double?, String) = (pastDueAmount, NSLocalizedString("Past Due Amount", comment: ""))
        let other: (Double?, String) = (nil, NSLocalizedString("Enter Custom Amount", comment: ""))

        var amounts: [(Double?, String)] = [totalAmount, other]
        var precariousAmounts = [(Double?, String)]()
        if let restorationAmount = billingInfo.restorationAmount, restorationAmount > 0 &&
            Environment.shared.opco != .bge && accountDetail.value.isCutOutNonPay {
            guard pastDueAmount != netDueAmount || restorationAmount != netDueAmount else {
                return []
            }

            if pastDueAmount != netDueAmount && pastDueAmount != restorationAmount {
                precariousAmounts.append(pastDue)
            }

            precariousAmounts.append((restorationAmount, NSLocalizedString("Restoration Amount", comment: "")))
        } else if let arrears = billingInfo.disconnectNoticeArrears, arrears > 0 {
            guard pastDueAmount != netDueAmount || arrears != netDueAmount else {
                return []
            }

            if pastDueAmount != netDueAmount && pastDueAmount != arrears {
                precariousAmounts.append(pastDue)
            }

            precariousAmounts.append((arrears, NSLocalizedString("Turn-Off Notice Amount", comment: "")))
        } else if let amtDpaReinst = billingInfo.amtDpaReinst, amtDpaReinst > 0 && Environment.shared.opco != .bge {
            guard pastDueAmount != netDueAmount || amtDpaReinst != netDueAmount else {
                return []
            }

            if pastDueAmount != netDueAmount && pastDueAmount != amtDpaReinst {
                precariousAmounts.append(pastDue)
            }

            precariousAmounts.append((amtDpaReinst, NSLocalizedString("Amount Due to Catch Up on Agreement", comment: "")))
        } else {
            guard pastDueAmount != netDueAmount else {
                return []
            }

            precariousAmounts.append(pastDue)
        }

        amounts.insert(contentsOf: precariousAmounts, at: 1)
        return amounts
    }()

    private(set) lazy var paymentAmountFeeLabelText: Driver<String?> =
        self.selectedWalletItem.asDriver().map { [weak self] in
            guard let self = self, let walletItem = $0 else { return nil }
            if walletItem.bankOrCard == .bank {
                return NSLocalizedString("No convenience fee will be applied.", comment: "")
            } else {
                return String.localizedStringWithFormat("A %@ convenience fee will be applied by Paymentus, our payment partner.", self.convenienceFee.currencyString)
            }
        }

    private(set) lazy var paymentAmountFeeFooterLabelText: Driver<String?> =
        self.selectedWalletItem.asDriver().map { [weak self] in
            guard let self = self, let walletItem = $0 else { return "" }
            if walletItem.bankOrCard == .bank {
                return NSLocalizedString("No convenience fee will be applied.", comment: "")
            } else  {
                return String.localizedStringWithFormat("Your payment includes a %@ convenience fee.", self.convenienceFee.currencyString)
            }
    }

    private(set) lazy var shouldShowStickyFooterView: Driver<Bool> = Driver.combineLatest(self.hasWalletItems, self.shouldShowContent)
        { $0 && $1 }

    private(set) lazy var selectedWalletItemImage: Driver<UIImage?> = selectedWalletItem.asDriver().map {
        guard let walletItem: WalletItem = $0 else { return nil }
        return walletItem.paymentMethodType.imageMini
    }

    private(set) lazy var selectedWalletItemMaskedAccountString: Driver<String> = selectedWalletItem.asDriver().map {
        guard let walletItem: WalletItem = $0 else { return "" }
        return "**** \(walletItem.maskedWalletItemAccountNumber ?? "")"
    }

    private(set) lazy var selectedWalletItemNickname: Driver<String?> = selectedWalletItem.asDriver().map {
        guard let walletItem = $0, let nickname = walletItem.nickName else { return nil }
        return nickname
    }

    private(set) lazy var showSelectedWalletItemNickname: Driver<Bool> = selectedWalletItemNickname.isNil().not()

    private(set) lazy var selectedWalletItemA11yLabel: Driver<String> =
        Driver.combineLatest(selectedWalletItem.asDriver(),
                             wouldBeSelectedWalletItemIsExpired.asDriver()) {
        guard let walletItem: WalletItem = $0 else { return "" }
        if $1 {
            return NSLocalizedString("Select Payment Method", comment: "")
        }

        var a11yLabel = walletItem.bankOrCard == .bank ?
            NSLocalizedString("Bank account", comment: "") :
            NSLocalizedString("Credit card", comment: "")

        if let nicknameText = walletItem.nickName, !nicknameText.isEmpty {
            a11yLabel += ", \(nicknameText)"
        }

        if let last4Digits = walletItem.maskedWalletItemAccountNumber {
            a11yLabel += String(format: NSLocalizedString(", Account number ending in, %@", comment: ""), last4Digits)
        }

        return a11yLabel
    }

    var convenienceFee: Double {
        return accountDetail.value.billingInfo.convenienceFee
    }

    private(set) lazy var amountDueCurrencyString: Driver<String?> = amountDue.asDriver()
        .map { $0.currencyString }

    private(set) lazy var dueDate: Driver<String?> = accountDetail.asDriver().map {
        $0.billingInfo.dueByDate?.mmDdYyyyString ?? "--"
    }

    private(set) lazy var shouldShowAddBankAccount: Driver<Bool> = Driver
        .combineLatest(isCashOnlyUser, hasWalletItems, paymentId.asDriver())
        { !$0 && !$1 && $2 == nil }

    private(set) lazy var shouldShowAddCreditCard: Driver<Bool> = Driver
        .combineLatest(hasWalletItems, paymentId.asDriver())
        { !$0 && $1 == nil }

    private(set) lazy var shouldShowAddPaymentMethodView: Driver<Bool> = Driver
        .combineLatest(shouldShowAddBankAccount, shouldShowAddCreditCard)
        { $0 || $1 }

    var walletFooterLabelText: String {
        return NSLocalizedString("All payments and associated convenience fees are processed by Paymentus Corporation. Payment methods saved to My Wallet are stored by Paymentus Corporation.", comment: "")
    }
    
    private(set) lazy var shouldShowPastDueLabel: Driver<Bool> = accountDetail.asDriver().map { [weak self] in
        if Environment.shared.opco == .bge || self?.paymentId.value != nil {
            return false
        }

        guard let pastDueAmount = $0.billingInfo.pastDueAmount,
            let netDueAmount = $0.billingInfo.netDueAmount,
            let dueDate = $0.billingInfo.dueByDate else {
                return false
        }
        let startOfTodayDate = Calendar.opCo.startOfDay(for: .now)
        if pastDueAmount > 0 && pastDueAmount != netDueAmount && dueDate > startOfTodayDate {
            // Past due amount but with a new bill allows user to future date, so we should hide
            return false
        }

        return pastDueAmount > 0
    }

    private(set) lazy var shouldShowCancelPaymentButton: Driver<Bool> = paymentId.asDriver().map {
        return $0 != nil
    }

    // MARK: - Review Payment Drivers

    private(set) lazy var reviewPaymentSubmitButtonEnabled: Driver<Bool> = Driver
        .combineLatest(termsConditionsSwitchValue.asDriver(),
                       isOverpaying,
                       overpayingSwitchValue.asDriver(),
                       isActiveSeveranceUser,
                       activeSeveranceSwitchValue.asDriver())
        {
            if !$0 {
                return false
            }
            if $1 && !$2 {
                return false
            }
            if $3 && !$4 {
                return false
            }
            return true
        }

    private(set) lazy var reviewPaymentShouldShowConvenienceFeeBox: Driver<Bool> =
        self.selectedWalletItem.asDriver().map { $0?.bankOrCard == .card }

    private(set) lazy var isOverpaying: Driver<Bool> = {
        switch Environment.shared.opco {
        case .bge:
            return Driver.combineLatest(amountDue.asDriver(), paymentAmount.asDriver(), resultSelector: <)
        case .comEd, .peco:
            return Driver.just(false)
        }
    }()

    private(set) lazy var isOverpayingCard: Driver<Bool> =
        Driver.combineLatest(isOverpaying, self.selectedWalletItem.asDriver()) {
            $0 && $1?.bankOrCard == .card
        }

    private(set) lazy var isOverpayingBank: Driver<Bool> =
        Driver.combineLatest(isOverpaying, self.selectedWalletItem.asDriver()) {
            $0 && $1?.bankOrCard == .bank
        }

    private(set) lazy var overpayingValueDisplayString: Driver<String?> = Driver
        .combineLatest(amountDue.asDriver(), paymentAmount.asDriver())
        { ($1 - $0).currencyString }

    private(set) lazy var shouldShowOverpaymentSwitchView: Driver<Bool> = isOverpaying

    private(set) lazy var shouldShowAutoPayEnrollButton: Driver<Bool> = accountDetail.asDriver().map {
        !$0.isAutoPay && $0.isAutoPayEligible && !StormModeStatus.shared.isOn
    }

    private(set) lazy var totalPaymentLabelText: Driver<String> = isOverpayingBank.map {
        $0 ? NSLocalizedString("Payment Amount", comment: ""): NSLocalizedString("Total Payment", comment: "")
    }

    private(set) lazy var totalPaymentDisplayString: Driver<String?> = Driver
        .combineLatest(paymentAmount.asDriver(), reviewPaymentShouldShowConvenienceFeeBox)
        .map { [weak self] paymentAmount, showConvenienceFeeBox in
            guard let self = self else { return nil }
            if showConvenienceFeeBox {
                return (paymentAmount + self.convenienceFee).currencyString
            } else {
                return paymentAmount.currencyString
            }
    }

    var reviewPaymentFooterLabelText: String {
        return NSLocalizedString("All payments and associated convenience fees are processed by Paymentus Corporation. Payment methods saved to My Wallet are stored by Paymentus Corporation. You will receive an email confirming that your payment was submitted successfully. If you receive an error message, please check for your email confirmation to verify you’ve successfully submitted payment.", comment: "")
    }

    // MARK: - Payment Confirmation

    private(set) lazy var shouldShowConvenienceFeeLabel: Driver<Bool> =
        self.selectedWalletItem.asDriver().map { $0?.bankOrCard == .card }
    
    var showConfirmationFooterText: Bool {
        return !confirmationFooterText.string.isEmpty
    }
    
    var confirmationFooterText: NSAttributedString {
        let accountDetail = self.accountDetail.value
        let billingInfo = accountDetail.billingInfo
        
        // Only show text in these precarious situations
        guard (Environment.shared.opco == .bge && accountDetail.isActiveSeverance) ||
            (accountDetail.isFinaled && billingInfo.pastDueAmount > 0) ||
            (billingInfo.restorationAmount > 0 && accountDetail.isCutOutNonPay) ||
            (billingInfo.disconnectNoticeArrears > 0 && accountDetail.isCutOutIssued) else {
            return NSAttributedString(string: "")
        }
        
        let boldText = NSLocalizedString("IMPORTANT: ", comment: "")
        let bodyText: String
        switch Environment.shared.opco {
        case .bge:
            bodyText = """
            If your service has been interrupted due to a past due balance and the submitted payment satisfies the required amount, your service will be restored.
            
            Your service will be restored between 4 and 72 hours.
            
            Breaker Policy: BGE requires your breakers to be in the off position.
            
            Gas Off:  If your natural gas service has been interrupted, a restoration appointment must be scheduled. An adult (18 years or older) must be at the property and provide access to light the pilots on all gas appliances. If an adult is not present or cannot provide the access required, the gas service will NOT be restored. This policy ensures public safety.
            """
        case .comEd:
            bodyText = """
            If your service has been interrupted due to a past due balance and the submitted payment satisfies the required restoral amount, your service will be restored:
            
            Typically within 30 minutes if you have a smart meter
            
            Typically by end of the next business day if you do not have a smart meter
            """
        case .peco:
            bodyText = """
            If your service has been interrupted due to a past due balance and the submitted payment satisfies the required amount, your service will be restored.
            
            Your service will be restored between 4 and 72 hours.
            
            Breaker Policy: PECO requires your breakers to be in the off position.
            
            Gas Off:  If your natural gas service has been interrupted, a restoration appointment must be scheduled. An adult (18 years or older) must be at the property and provide access to light the pilots on all gas appliances. If an adult is not present or cannot provide the access required, the gas service will NOT be restored. This policy ensures public safety.
            """
        }
        
        let localizedText = String.localizedStringWithFormat("%@%@", boldText, bodyText)
        let attributedText = NSMutableAttributedString(string: localizedText,
                                                       attributes: [.foregroundColor: UIColor.blackText,
                                                                    .font: OpenSans.regular.of(textStyle: .footnote)])
        attributedText.addAttribute(.font,
                                    value: OpenSans.bold.of(textStyle: .footnote),
                                    range: NSRange(location: 0, length: boldText.count))
        
        return attributedText
    }

    var errorPhoneNumber: String {
        switch Environment.shared.opco {
        case .bge:
            return "1-800-685-0123"
        case .comEd:
            return "1-800-334-7661"
        case .peco:
            return "1-800-494-4000"
        }
    }

}
