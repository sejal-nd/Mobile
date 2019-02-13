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

    var oneTouchPayItem: WalletItem?

    let paymentDetail = Variable<PaymentDetail?>(nil)
    let paymentId = Variable<String?>(nil)
    let allowEdits = Variable(true)
    let allowCancel = Variable(false)

    var confirmationNumber: String?

    init(walletService: WalletService,
         paymentService: PaymentService,
         accountDetail: AccountDetail,
         paymentDetail: PaymentDetail?,
         billingHistoryItem: BillingHistoryItem?) {
        self.walletService = walletService
        self.paymentService = paymentService
        self.accountDetail = Variable(accountDetail)
        self.paymentDetail.value = paymentDetail
        if let billingHistoryItem = billingHistoryItem {
            self.paymentId.value = billingHistoryItem.paymentId
            self.allowEdits.value = billingHistoryItem.flagAllowEdits
            self.allowCancel.value = billingHistoryItem.flagAllowDeletes
        }

        self.paymentDate = Variable(.now) // May be updated later...see computeDefaultPaymentDate()

        amountDue = Variable(accountDetail.billingInfo.netDueAmount ?? 0)
        paymentAmount = Variable(billingHistoryItem?.amountPaid ?? accountDetail.billingInfo.netDueAmount ?? 0)
    }

    // MARK: - Service Calls

    func fetchWalletItems() -> Observable<Void> {
        return walletService.fetchWalletItems()
            .map { walletItems in
                self.walletItems.value = walletItems
                self.oneTouchPayItem = walletItems.first(where: { $0.isDefault == true })
            }
    }

    func fetchPaymentDetails(paymentId: String) -> Observable<Void> {
        return paymentService.fetchPaymentDetails(accountNumber: accountDetail.value.accountNumber,
                                                  paymentId: paymentId)
            .map { paymentDetail in
                self.paymentDetail.value = paymentDetail
            }
    }

    func fetchData(initialFetch: Bool, onSuccess: (() -> ())?, onError: (() -> ())?) {
        var observables = [fetchWalletItems()]

        if let paymentId = paymentId.value, paymentDetail.value == nil {
            observables.append(fetchPaymentDetails(paymentId: paymentId))
        }

        isFetching.value = true
        Observable.zip(observables)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.isFetching.value = false

                guard let walletItems = self.walletItems.value else { return }

                if initialFetch {
                    if self.paymentId.value != nil { // Modifiying Payment
                        if let paymentDetail = self.paymentDetail.value {
                            self.paymentAmount.value = paymentDetail.paymentAmount
                            self.paymentDate.value = paymentDetail.paymentDate!
                            for item in walletItems {
                                if item.walletItemID == paymentDetail.walletItemId {
                                    self.selectedWalletItem.value = item
                                    break
                                }
                            }
                        }
                    } else {
                        if self.accountDetail.value.isCashOnly {
                            if let otpItem = self.oneTouchPayItem { // Default to OTP item IF it's a credit card
                                if otpItem.bankOrCard == .card {
                                    self.selectedWalletItem.value = otpItem
                                }
                            } else if walletItems.count > 0 { // If no OTP item, default to first card wallet item
                                for item in walletItems {
                                    if item.bankOrCard == .card {
                                        self.selectedWalletItem.value = item
                                        break
                                    }
                                }
                            }
                        } else {
                            if let otpItem = self.oneTouchPayItem { // Default to One Touch Pay item
                                self.selectedWalletItem.value = otpItem
                            } else if walletItems.count > 0 { // If no OTP item, default to first wallet item
                                self.selectedWalletItem.value = walletItems[0]
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
        let paymentType: PaymentType = self.selectedWalletItem.value!.bankOrCard == .bank ? .check : .credit
        let payment = Payment(accountNumber: self.accountDetail.value.accountNumber,
                              existingAccount: !self.selectedWalletItem.value!.isTemporary,
                              maskedWalletAccountNumber: self.selectedWalletItem.value!.maskedWalletItemAccountNumber!,
                              paymentAmount: self.paymentAmount.value,
                              paymentType: paymentType,
                              paymentDate: self.paymentDate.value,
                              walletId: AccountsStore.shared.customerIdentifier,
                              walletItemId: self.selectedWalletItem.value!.walletItemID!)
        
        self.paymentService.schedulePayment(payment: payment)
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
                                     paymentId: paymentId.value!,
                                     paymentDetail: paymentDetail.value!)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onSuccess()
            }, onError: { err in
                onError(err.localizedDescription)
            })
            .disposed(by: disposeBag)
    }

    func modifyPayment(onSuccess: @escaping () -> Void, onError: @escaping (ServiceError) -> Void) {
        let paymentType: PaymentType = self.selectedWalletItem.value!.bankOrCard == .bank ? .check : .credit
        let payment = Payment(accountNumber: self.accountDetail.value.accountNumber,
                              existingAccount: true,
                              maskedWalletAccountNumber: self.selectedWalletItem.value!.maskedWalletItemAccountNumber!,
                              paymentAmount: self.paymentAmount.value,
                              paymentType: paymentType,
                              paymentDate: self.paymentDate.value,
                              walletId: AccountsStore.shared.customerIdentifier,
                              walletItemId: self.selectedWalletItem.value!.walletItemID!)

        self.paymentService.updatePayment(paymentId: self.paymentId.value!, payment: payment)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onSuccess()
            }, onError: { err in
                onError(err as! ServiceError)
            })
            .disposed(by: self.disposeBag)
    }

    // MARK: - Shared Drivers

    private(set) lazy var paymentAmountString = paymentAmount.asDriver()
        .map { $0.currencyString }

    private(set) lazy var bankWorkflow: Driver<Bool> = self.selectedWalletItem.asDriver().map {
        guard let walletItem = $0 else { return false }
        return walletItem.bankOrCard == .bank
    }

    private(set) lazy var cardWorkflow: Driver<Bool> = self.selectedWalletItem.asDriver().map {
        guard let walletItem = $0 else { return false }
        return walletItem.bankOrCard == .card
    }

    private(set) lazy var paymentFieldsValid: Driver<Bool> = Driver
        .combineLatest(shouldShowContent, paymentAmountErrorMessage) {
            return $0 && $1 == nil
        }

    // MARK: - Make Payment Drivers
    private(set) lazy var makePaymentNextButtonEnabled: Driver<Bool> = Driver
        .combineLatest(selectedWalletItem.asDriver(), paymentFieldsValid) {
            return $0 != nil && $1
        }

    private(set) lazy var isCashOnlyUser: Driver<Bool> = self.accountDetail.asDriver().map { $0.isCashOnly }

    private(set) lazy var isActiveSeveranceUser: Driver<Bool> = self.accountDetail.asDriver().map { $0.isActiveSeverance }

    private(set) lazy var shouldShowNextButton: Driver<Bool> =
        Driver.combineLatest(self.paymentId.asDriver(),
                             self.allowEdits.asDriver())
        {
            if $0 != nil {
                return $1
            }
            return true
        }

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

    private(set) lazy var shouldShowPaymentAmountTextField: Driver<Bool> =
        Driver.combineLatest(self.hasWalletItems,
                             self.allowEdits.asDriver())
        { $0 && $1 }

    private(set) lazy var paymentAmountErrorMessage: Driver<String?> = {
        return Driver.combineLatest(bankWorkflow,
                                    cardWorkflow,
                                    accountDetail.asDriver(),
                                    paymentAmount.asDriver(),
                                    amountDue.asDriver())
        { (bankWorkflow, cardWorkflow, accountDetail, paymentAmount, amountDue) -> String? in
            if bankWorkflow {
                let minPayment = accountDetail.billingInfo.minPaymentAmount()
                let maxPayment = accountDetail.billingInfo.maxPaymentAmount(bankOrCard: .bank)
                if Environment.shared.opco == .bge {
                    // BGE BANK
                    if paymentAmount < minPayment {
                        return NSLocalizedString("Minimum payment allowed is \(minPayment.currencyString)", comment: "")
                    } else if paymentAmount > maxPayment {
                        return NSLocalizedString("Maximum payment allowed is \(maxPayment.currencyString)", comment: "")
                    }
                } else {
                    // COMED/PECO BANK
                    if paymentAmount < minPayment {
                        return NSLocalizedString("Minimum payment allowed is \(minPayment.currencyString)", comment: "")
                    } else if paymentAmount > amountDue {
                        return NSLocalizedString("Payment must be less than or equal to total amount due", comment: "")
                    } else if paymentAmount > maxPayment {
                        return NSLocalizedString("Maximum payment allowed is \(maxPayment.currencyString)", comment: "")
                    }
                }
            } else if cardWorkflow {
                let minPayment = accountDetail.billingInfo.minPaymentAmount()
                let maxPayment = accountDetail.billingInfo.maxPaymentAmount(bankOrCard: .card)
                if Environment.shared.opco == .bge {
                    // BGE CREDIT CARD
                    if paymentAmount < minPayment {
                        return NSLocalizedString("Minimum payment allowed is \(minPayment.currencyString)", comment: "")
                    } else if paymentAmount > maxPayment {
                        return NSLocalizedString("Maximum payment allowed is \(maxPayment.currencyString)", comment: "")
                    }
                } else {
                    // COMED/PECO CREDIT CARD
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

        let min = self.accountDetail.value.billingInfo.minPaymentAmount()
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

    private(set) lazy var paymentAmountFeeLabelText: Driver<String?> = Driver
        .combineLatest(bankWorkflow, cardWorkflow)
    { [weak self] (bankWorkflow, cardWorkflow) -> String? in
        guard let self = self else { return nil }
        if bankWorkflow {
            return NSLocalizedString("No convenience fee will be applied.", comment: "")
        } else if cardWorkflow {
            if Environment.shared.opco == .bge {
                return NSLocalizedString(self.accountDetail.value.billingInfo.convenienceFeeString(isComplete: true), comment: "")
            } else {
                return String.localizedStringWithFormat("A %@ convenience fee will be applied by Paymentus, our payment partner.", self.convenienceFee.currencyString)
            }
        }
        return ""
    }

    private(set) lazy var paymentAmountFeeFooterLabelText: Driver<String> = Driver
        .combineLatest(bankWorkflow, cardWorkflow, accountDetail.asDriver())
        { [weak self] (bankWorkflow, cardWorkflow, accountDetail) -> String in
            guard let self = self else { return "" }
            if bankWorkflow {
                return NSLocalizedString("No convenience fee will be applied.", comment: "")
            } else if cardWorkflow {
                return String(format: NSLocalizedString("Your payment includes a %@ convenience fee.", comment: ""),
                              Environment.shared.opco == .bge && !accountDetail.isResidential ? self.convenienceFee.percentString! : self.convenienceFee.currencyString)
            }
            return ""
    }

    private(set) lazy var shouldShowPaymentDateView: Driver<Bool> = Driver.combineLatest(self.hasWalletItems, self.paymentId.asDriver())
    { $0 || $1 != nil }

    private(set) lazy var shouldShowStickyFooterView: Driver<Bool> = Driver.combineLatest(self.hasWalletItems, self.shouldShowContent)
    { $0 && $1 }

    private(set) lazy var selectedWalletItemImage: Driver<UIImage?> = selectedWalletItem.asDriver().map {
        guard let walletItem: WalletItem = $0 else { return nil }
        if walletItem.bankOrCard == .bank {
            return #imageLiteral(resourceName: "opco_bank_mini")
        } else {
            return #imageLiteral(resourceName: "opco_credit_card_mini")
        }
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
        switch Environment.shared.opco {
        case .bge:
            return self.accountDetail.value.isResidential ?
                accountDetail.value.billingInfo.residentialFee! :
                accountDetail.value.billingInfo.commercialFee!
        case .comEd, .peco:
            return accountDetail.value.billingInfo.convenienceFee!
        }
    }

    private(set) lazy var amountDueCurrencyString: Driver<String?> = amountDue.asDriver()
        .map { $0.currencyString }

    private(set) lazy var dueDate: Driver<String?> = accountDetail.asDriver().map {
        $0.billingInfo.dueByDate?.mmDdYyyyString ?? "--"
    }

    private(set) lazy var shouldShowAddBankAccount: Driver<Bool> = Driver
        .combineLatest(isCashOnlyUser, hasWalletItems, allowEdits.asDriver())
        { !$0 && !$1 && $2 }

    private(set) lazy var shouldShowAddCreditCard: Driver<Bool> = Driver
        .combineLatest(hasWalletItems, allowEdits.asDriver())
        { !$0 && $1 }

    private(set) lazy var shouldShowAddPaymentMethodView: Driver<Bool> = Driver
        .combineLatest(shouldShowAddBankAccount, shouldShowAddCreditCard)
        { $0 || $1 }

    private(set) lazy var walletFooterLabelText: Driver<String> = hasWalletItems.asDriver().map {
        if Environment.shared.opco == .bge {
            if $0 {
                return NSLocalizedString("Any payment made for less than the total amount due or after the indicated due date may result in your service being disconnected. Payments may take up to two business days to reflect on your account.", comment: "")
            } else {
                return NSLocalizedString("We accept: VISA, MasterCard, Discover, and American Express. Business customers cannot use VISA.\n\nAny payment made for less than the total amount due or after the indicated due date may result in your service being disconnected. Payments may take up to two business days to reflect on your account.", comment: "")
            }
        } else {
            return NSLocalizedString("All payments and associated convenience fees are processed by Paymentus Corporation. Payment methods saved to My Wallet are stored by Paymentus Corporation.", comment: "")
        }
    }

    private(set) lazy var isFixedPaymentDate: Driver<Bool> = Driver
        .combineLatest(accountDetail.asDriver(), allowEdits.asDriver())
        { [weak self] (accountDetail, allowEdits) in
            guard let self = self else { return false }
            if Environment.shared.opco == .bge && accountDetail.isActiveSeverance {
                return true
            }
            
            if !allowEdits {
                return true
            }
            
            let startOfTodayDate = Calendar.opCo.startOfDay(for: .now)
            if let dueDate = accountDetail.billingInfo.dueByDate {
                if dueDate <= startOfTodayDate {
                    return true
                }
            }
            
            return false
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

    private(set) lazy var paymentDateString: Driver<String> = paymentDate.asDriver()
        .map { $0.mmDdYyyyString }

    private(set) lazy var shouldShowCancelPaymentButton: Driver<Bool> = Driver
        .combineLatest(paymentId.asDriver(), allowCancel.asDriver())
        {
            if $0 != nil {
                return $1
            }
            return false
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

    private(set) lazy var reviewPaymentShouldShowConvenienceFeeBox: Driver<Bool> = cardWorkflow

    private(set) lazy var isOverpaying: Driver<Bool> = {
        switch Environment.shared.opco {
        case .bge:
            return Driver.combineLatest(amountDue.asDriver(), paymentAmount.asDriver(), resultSelector: <)
        case .comEd, .peco:
            return Driver.just(false)
        }
    }()

    private(set) lazy var isOverpayingCard: Driver<Bool> = Driver.combineLatest(isOverpaying, cardWorkflow) { $0 && $1 }

    private(set) lazy var isOverpayingBank: Driver<Bool> = Driver.combineLatest(isOverpaying, bankWorkflow) { $0 && $1 }

    private(set) lazy var overpayingValueDisplayString: Driver<String?> = Driver
        .combineLatest(amountDue.asDriver(), paymentAmount.asDriver())
        { ($1 - $0).currencyString }

    private(set) lazy var shouldShowOverpaymentSwitchView: Driver<Bool> = isOverpaying

    private(set) lazy var convenienceFeeDisplayString: Driver<String?> = paymentAmount.asDriver().map { [weak self] in
            guard let self = self else { return nil }
            if Environment.shared.opco == .bge && !self.accountDetail.value.isResidential {
                return (($0 / 100) * self.convenienceFee).currencyString
            } else {
                return self.convenienceFee.currencyString
            }
    }

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
                switch Environment.shared.opco {
                case .bge:
                    if self.accountDetail.value.isResidential {
                        return (paymentAmount + self.convenienceFee).currencyString
                    } else {
                        return ((1 + self.convenienceFee / 100) * paymentAmount).currencyString
                    }
                case .comEd, .peco:
                    return (paymentAmount + self.convenienceFee).currencyString
                }
            } else {
                return paymentAmount.currencyString
            }
    }

    var reviewPaymentFooterLabelText: String {
        return NSLocalizedString("All payments and associated convenience fees are processed by Paymentus Corporation. Payment methods saved to My Wallet are stored by Paymentus Corporation. You will receive an email confirming that your payment was submitted successfully. If you receive an error message, please check for your email confirmation to verify you’ve successfully submitted payment.", comment: "")
    }

    // MARK: - Payment Confirmation

    private(set) lazy var shouldShowConvenienceFeeLabel: Driver<Bool> = cardWorkflow

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
