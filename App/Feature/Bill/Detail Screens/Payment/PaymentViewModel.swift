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
    
    private let kMaxUsernameChars = 255
    
    

    let accountDetail: BehaviorRelay<AccountDetail>
    let billingHistoryItem: BillingHistoryItem?
    
    let isFetching = BehaviorRelay(value: false)
    let isError = BehaviorRelay(value: false)

    let walletItems = BehaviorRelay<[WalletItem]?>(value: nil)
    let selectedWalletItem = BehaviorRelay<WalletItem?>(value: nil)
    let wouldBeSelectedWalletItemIsExpired = BehaviorRelay(value: false)

    let amountDue: BehaviorRelay<Double>
    let paymentAmount: BehaviorRelay<Double>
    let paymentDate: BehaviorRelay<Date>
    let selectedDate: BehaviorRelay<Date>

    let termsConditionsSwitchValue = BehaviorRelay(value: false)
    let overpayingSwitchValue = BehaviorRelay(value: false)
    let activeSeveranceSwitchValue = BehaviorRelay(value: false)

    let paymentId = BehaviorRelay<String?>(value: nil)
    
    let emailAddress = BehaviorRelay(value: "")
    let phoneNumber = BehaviorRelay(value: "")

    var confirmationNumber: String?

    init(accountDetail: AccountDetail,
         billingHistoryItem: BillingHistoryItem?) {
        self.accountDetail = BehaviorRelay(value: accountDetail)
        self.billingHistoryItem = billingHistoryItem
        
        if let billingHistoryItem = billingHistoryItem { // Editing a payment
            paymentId.accept(billingHistoryItem.paymentID)
            selectedWalletItem.accept(WalletItem(walletItemId: billingHistoryItem.walletItemID,
                                                 maskedAccountNumber: billingHistoryItem.maskedAccountNumber,
                                                 nickName: NSLocalizedString("Current Payment Method", comment: ""),
                                                 paymentMethodType: billingHistoryItem.paymentMethodType,
                                                 isEditingItem: true))
        }

        let netDueAmount: Double = accountDetail.billingInfo.netDueAmount ?? 0
        amountDue = BehaviorRelay(value: netDueAmount)
        
        // If editing, default to the amount paid. If not editing, default to total amount due
        paymentAmount = BehaviorRelay(value: billingHistoryItem?.amountPaid ?? netDueAmount)
        
        // May be updated later...see computeDefaultPaymentDate()
        paymentDate = BehaviorRelay(value: billingHistoryItem?.date ?? .now)
        
        // Default it to current Date
        selectedDate =  BehaviorRelay(value: .now)
    }

    // MARK: - Service Calls

    func fetchData(initialFetch: Bool, onSuccess: (() -> ())?, onError: (() -> ())?) {
        isFetching.accept(true)
        
        WalletService.fetchWalletItems { [weak self] result in
            switch result {
            case .success(let walletItemContainer):
                guard let self = self else { return }
                let walletItems = walletItemContainer.walletItems
                self.isFetching.accept(false)
                
                self.walletItems.accept(walletItems)
                let defaultWalletItem = walletItems.first(where: { $0.isDefault })
                
                if initialFetch {
                    if self.paymentId.value == nil { // If not modifiying payment
                        self.computeDefaultPaymentDate()
                        if self.accountDetail.value.isCashOnly {
                            if defaultWalletItem?.bankOrCard == .card { // Select the default item IF it's a credit card
                                self.selectedWalletItem.accept(defaultWalletItem!)
                            } else if let firstCard = walletItems.first(where: { $0.bankOrCard == .card }) {
                                // If no default item, choose the first credit card
                                self.selectedWalletItem.accept(firstCard)
                            }
                        } else {
                            if defaultWalletItem != nil { // Choose the default item
                                self.selectedWalletItem.accept(defaultWalletItem!)
                            } else if walletItems.count > 0 { // If no default item, choose the first item
                                self.selectedWalletItem.accept(walletItems.first)
                            }
                        }
                    }
                }
                
                if let walletItem = self.selectedWalletItem.value, walletItem.isExpired {
                    self.selectedWalletItem.accept(nil)
                    self.wouldBeSelectedWalletItemIsExpired.accept(true)
                }
                
                onSuccess?()
            case .failure:
                self?.isFetching.accept(false)
                self?.isError.accept(true)
                onError?()
            }
            
        }
    }

    func schedulePayment(onDuplicate: @escaping (String, String) -> Void,
                         onSuccess: @escaping () -> Void,
                         onError: @escaping (NetworkingError) -> Void) {

        let walletItem = self.selectedWalletItem.value!
        let scheduleRequest = ScheduledPaymentUpdateRequest(paymentAmount: paymentAmount.value,
                                                            paymentDate: paymentDate.value,
                                                            walletItem: walletItem,
                                                            alternateEmail: self.emailAddress.value,
                                                            alternatePhoneNumber: self.extractDigitsFrom(self.phoneNumber.value))
        PaymentService.schedulePayment(accountNumber: accountDetail.value.accountNumber, request: scheduleRequest) { [weak self] result in
            switch result {
            case .success(let confirmationNumber):
                self?.confirmationNumber = confirmationNumber.confirmationNumber
                onSuccess()
            case .failure(let error):
                onError(error)
            }
        }
    }

    func cancelPayment(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        let cancelRequest = SchedulePaymentCancelRequest(paymentAmount: paymentAmount.value)
        
        PaymentService.cancelSchduledPayment(accountNumber: accountDetail.value.accountNumber, paymentId: paymentId.value ?? "", request: cancelRequest) { result in
            switch result {
            case .success:
                onSuccess()
            case .failure(let error):
                onError(error.description)
            }
            
        }
    }

    func modifyPayment(onSuccess: @escaping () -> Void, onError: @escaping (NetworkingError) -> Void) {
        let walletItem = self.selectedWalletItem.value!
        let updateRequest = ScheduledPaymentUpdateRequest(paymentAmount: paymentAmount.value, paymentDate: paymentDate.value, paymentId: paymentId.value!, walletItem: walletItem)
        PaymentService.updateScheduledPayment(paymentId: paymentId.value ?? "", accountNumber: accountDetail.value.accountNumber, request: updateRequest) { [weak self] result in
            switch result {
            case .success(let confirmationNumber):
                self?.confirmationNumber = confirmationNumber.confirmationNumber
                onSuccess()
            case .failure(let error):
                onError(error)
            }
        }
    }
    
    // MARK: - Payment Date Stuff

    // See the "Billing Scenarios (Grid View)" document on Confluence for these rules
    func computeDefaultPaymentDate() {
        if Environment.shared.opco == .bge {
            paymentDate.accept(.now)
        } else {
            let acctDetail = accountDetail.value
            let billingInfo = acctDetail.billingInfo
            
            // Covers precarious states 6, 5, and 4 (in that order) on the Billing Scenarios table
            if (acctDetail.isFinaled && billingInfo.pastDueAmount > 0) ||
                (acctDetail.isCutOutIssued && billingInfo.disconnectNoticeArrears > 0) ||
                (acctDetail.isCutOutNonPay && billingInfo.restorationAmount > 0) {
                paymentDate.accept(.now)
            }
            
            // All the other states boil down to the due date being in the future
            if let dueDate = billingInfo.dueByDate {
                paymentDate.accept(Environment.shared.opco.isPHI ? .now : isDueDateInTheFuture ? dueDate : .now)
            } else { // Should never get here?
                paymentDate.accept(.now)
            }
        }
    }
    
    // See the "Billing Scenarios (Grid View)" document on Confluence for these rules
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
        
        // If not one of the above precarious states...
        if Environment.shared.opco == .bge { // BGE can always future date
            return true
        } else { // ComEd/PECO can only future date if the due date has not passed
            return isDueDateInTheFuture
        }
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
    
    private(set) lazy var emailIsValidBool: Driver<Bool> =
        self.emailAddress.asDriver().map { text -> Bool in
            if text.count > self.kMaxUsernameChars {
                return false
            }
            if text.count == .zero {
                return true
            }
            
            if text.contains(" ") {
                return false
            }
            
            let components = text.components(separatedBy: "@")
            
            if components.count != 2 {
                return false
            }
            
            let urlComponents = components[1].components(separatedBy: ".")
            
            if urlComponents.count < 2 {
                return false
            } else if urlComponents[0].isEmpty || urlComponents[1].isEmpty {
                return false
            }
            
            return true
    }
    
    private(set) lazy var emailIsValid: Driver<String?> =
        self.emailAddress.asDriver().map { text -> String? in
            if !text.isEmpty {
                if text.count > self.kMaxUsernameChars {
                    return "Maximum of 255 characters allowed"
                }
                
                if text.contains(" ") {
                    return "Invalid email address"
                }
                
                let components = text.components(separatedBy: "@")
                
                if components.count != 2 {
                    return "Invalid email address"
                }
                
                let urlComponents = components[1].components(separatedBy: ".")
                
                if urlComponents.count < 2 {
                    return "Invalid email address"
                } else if urlComponents[0].isEmpty || urlComponents[1].isEmpty {
                    return "Invalid email address"
                }
            }
            
            return nil
    }
    
    private(set) lazy var phoneNumberHasTenDigits: Driver<Bool> =
        self.phoneNumber.asDriver().map { [weak self] text -> Bool in
            guard let self = self else { return false }
            let digitsOnlyString = self.extractDigitsFrom(text)
            return digitsOnlyString.count == 10 || digitsOnlyString.count == 0
    }
    
    private func extractDigitsFrom(_ string: String) -> String {
        return string.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
    }
    
    private(set) lazy var shouldShowPaymentDateView: Driver<Bool> =
        Driver.combineLatest(self.hasWalletItems, self.paymentId.asDriver()) {
            $0 || $1 != nil
        }

    private(set) lazy var paymentDateString: Driver<String> = paymentDate.asDriver()
        .map { $0.mmDdYyyyString }
    
    private(set) lazy var paymentDateA11yString: Driver<String> = paymentDate.asDriver()
        .map { String.localizedStringWithFormat("Payment Date,%@", $0.mmDdYyyyString) }
    
    func shouldCalendarDateBeEnabled(_ date: Date) -> Bool {
        let components = Calendar.opCo.dateComponents([.year, .month, .day], from: date)
        guard let opCoTimeDate = Calendar.opCo.date(from: components) else { return false }
        
        if paymentId.value != nil && date.isInToday(calendar: .opCo) {
            // 193496: Paymentus does not allow a scheduled payment to be updated to today's date
            return false
        }
        
        let today = Calendar.opCo.startOfDay(for: .now)
        switch Environment.shared.opco {
        case .ace, .bge, .delmarva, .pepco:
            let minDate = today
            var maxDate: Date
            switch selectedWalletItem.value?.bankOrCard {
            case .card?:
                maxDate = Calendar.opCo.date(byAdding: .day, value: 90, to: today) ?? today
            case .bank?:
                maxDate = Calendar.opCo.date(byAdding: .day, value: 180, to: today) ?? today
            default:
                return false
            }
            
            return DateInterval(start: minDate, end: maxDate).contains(opCoTimeDate)
        case .comEd, .peco:
            if let dueDate = accountDetail.value.billingInfo.dueByDate {
                let startOfDueDate = Calendar.opCo.startOfDay(for: dueDate)
                return DateInterval(start: today, end: startOfDueDate).contains(opCoTimeDate)
            }
        }
        return false // Will never execute
    }
    
    // Must combine selectedWalletItem because the date validation relies on bank vs card
    private(set) lazy var isPaymentDateValid: Driver<Bool> = Driver
        .combineLatest(paymentDate.asDriver(), selectedWalletItem.asDriver())
        .map { [weak self] paymentDate, _ in
            guard let self = self else { return false }
            if !self.canEditPaymentDate { // If fixed payment date, no need for validation
                return true
            }
            return self.shouldCalendarDateBeEnabled(paymentDate)
        }
    
    /// This will identify whether the payment date is in future
    private(set) lazy var isSelectedPaymentDateBeyondDueDate: Driver<Bool> =
        selectedDate.asDriver().map { [weak self] date in
            guard let self = self else { return false }
            return Environment.shared.opco.isPHI && (self.accountDetail.value.billingInfo.dueByDate < date) && self.canEditPaymentDate
       }
    
      
    private(set) lazy var shouldShowSameDayPaymentWarning: Driver<Bool> =
        self.paymentDate.asDriver().map { date in
            return date.isInToday(calendar: .opCo)
        }
    
    // MARK: - Shared Drivers

    private(set) lazy var paymentAmountString = paymentAmount.asDriver()
        .map { $0.currencyString }

    private(set) lazy var paymentFieldsValid: Driver<Bool> = Driver
        .combineLatest(shouldShowContent, paymentAmountErrorMessage, isPaymentDateValid) {
            return $0 && $1 == nil && $2
        }

    // MARK: - Other Make Payment Drivers
    
    private(set) lazy var makePaymentContinueButtonEnabled: Driver<Bool> = Driver
        .combineLatest(selectedWalletItem.asDriver(), paymentFieldsValid) {
            return $0 != nil && $1
        }

    private(set) lazy var isCashOnlyUser: Driver<Bool> = self.accountDetail.asDriver().map { $0.isCashOnly }

    private(set) lazy var isActiveSeveranceUser: Driver<Bool> = self.accountDetail.asDriver().map { $0.isActiveSeverance }

    private(set) lazy var shouldShowContent: Driver<Bool> =
        Driver.combineLatest(self.isFetching.asDriver(),
                             self.isError.asDriver())
        { !$0 && !$1 }

    private(set) lazy var shouldShowPaymentMethodButton: Driver<Bool> =
        self.selectedWalletItem.asDriver().isNil().not()
    
    private(set) lazy var shouldShowPaymentMethodExpiredButton: Driver<Bool> =
        self.wouldBeSelectedWalletItemIsExpired.asDriver()

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
                if Environment.shared.opco == .bge || Environment.shared.opco.isPHI {
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
                if Environment.shared.opco == .bge || Environment.shared.opco.isPHI {
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
     Some funky logic going on here. Basically, there are 4 cases in which we just return []

     1. No pastDueAmount
     2. netDueAmount == pastDueAmount, no other precarious amounts exist
     3. netDueAmount == pastDueAmount == other precarious amount (restorationAmount, amtDpaReinst, disconnectNoticeArrears)
     4. We're editing a payment

     In these cases we don't give the user multiple payment amount options, just the text field.
    */
    lazy var paymentAmounts: [(Double?, String)] = {
        let billingInfo = accountDetail.value.billingInfo

        guard let netDueAmount = billingInfo.netDueAmount,
            let pastDueAmount = billingInfo.pastDueAmount,
            pastDueAmount > 0,
            paymentId.value == nil else {
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

    private(set) lazy var paymentMethodFeeLabelText: Driver<String?> =
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
        return "**** \(walletItem.maskedAccountNumber?.last4Digits() ?? "")"
    }

    private(set) lazy var selectedWalletItemNickname: Driver<String?> = selectedWalletItem.asDriver().map {
        guard let walletItem = $0, let nickname = walletItem.nickName else { return nil }
        return nickname
    }

    private(set) lazy var showSelectedWalletItemNickname: Driver<Bool> = selectedWalletItemNickname.isNil().not()

    private(set) lazy var selectedWalletItemA11yLabel: Driver<String> =
        self.selectedWalletItem.asDriver().map {
            guard let walletItem: WalletItem = $0 else { return "" }
            return walletItem.accessibilityDescription()
        }

    var convenienceFee: Double {
        return accountDetail.value.billingInfo.convenienceFee
    }

    private(set) lazy var amountDueCurrencyString: Driver<String?> = amountDue.asDriver()
        .map { max(0, $0).currencyString }

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
                       activeSeveranceSwitchValue.asDriver(),
                       self.emailIsValidBool.asDriver(),
                       self.phoneNumberHasTenDigits.asDriver())
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
            if !$5 || !$6 {
                return false
            }
            return true
    }

    private(set) lazy var reviewPaymentShouldShowConvenienceFeeBox: Driver<Bool> =
        self.selectedWalletItem.asDriver().map { $0?.bankOrCard == .card }

    private(set) lazy var isOverpaying: Driver<Bool> = {
        switch Environment.shared.opco {
        case .ace, .bge, .delmarva, .pepco:
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

    private(set) lazy var totalPaymentLabelText: Driver<String> = isOverpayingBank.map {_ in
       NSLocalizedString("Total Payment", comment: "")
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
        let opco = Environment.shared.opco
        
        // Only show text in these precarious situations
        guard (opco == .bge && accountDetail.isActiveSeverance) ||
            (accountDetail.isFinaled && (opco == .bge || billingInfo.pastDueAmount > 0)) ||
            (billingInfo.restorationAmount > 0 && accountDetail.isCutOutNonPay) ||
            (billingInfo.disconnectNoticeArrears > 0 && accountDetail.isCutOutIssued) else {
            return NSAttributedString(string: "")
        }
        
        let boldText: String
        let bodyText: String
        switch Environment.shared.opco {
        case .bge:
            boldText = ""
            bodyText = """
            If service is off and your balance was paid after 3pm, or on a Sunday or Holiday, your service will be restored the next business day.
            
            Please ensure that circuit breakers are off. If applicable, remove any fuses prior to reconnection of the service, remove any flammable materials from heat sources, and unplug any sensitive electronics and large appliances.
            
            If an electric smart meter is installed at the premise, BGE will first attempt to restore the service remotely. If both gas and electric services are off, or if BGE does not have access to the meters, we may contact you to make arrangements when an adult will be present.
            """
        case .comEd:
            boldText = NSLocalizedString("IMPORTANT: ", comment: "")
            bodyText = """
            If your service has been interrupted due to a past due balance and the submitted payment satisfies the required restoral amount, your service will be restored:
            
            Typically within 30 minutes if you have a smart meter
            
            Typically by end of the next business day if you do not have a smart meter
            """
        case .peco:
            boldText = NSLocalizedString("IMPORTANT: ", comment: "")
            bodyText = """
            If your service has been interrupted due to a past due balance and the submitted payment satisfies the required amount, your service will be restored.
            
            Your service will be restored between 4 and 72 hours.
            
            Breaker Policy: PECO requires your breakers to be in the off position.
            
            Gas Off:  If your natural gas service has been interrupted, a restoration appointment must be scheduled. An adult (18 years or older) must be at the property and provide access to light the pilots on all gas appliances. If an adult is not present or cannot provide the access required, the gas service will NOT be restored. This policy ensures public safety.
            """
        case .pepco:
            boldText = NSLocalizedString("todo: ", comment: "")
            bodyText = """
            todo
            """
        case .ace:
            boldText = NSLocalizedString("todo: ", comment: "")
            bodyText = """
            todo
            """
        case .delmarva:
            boldText = NSLocalizedString("todo: ", comment: "")
            bodyText = """
            todo
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
        case .pepco:
            return "202-833-7500"
        case .ace:
            return "1-800-642-3780"
        case .delmarva:
            return "1-800-375-7117"
        }
    }

}
