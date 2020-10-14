//
//  TapToPayViewModel.swift
//  Mobile
//
//  Created by Adarsh Maurya on 24/09/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

class TapToPayViewModel {
    let disposeBag = DisposeBag()
    
    private let kMaxUsernameChars = 255
    
    private let walletService: WalletService
    private let paymentService: PaymentService
    
    let accountDetail: BehaviorRelay<AccountDetail>
    let billingHistoryItem: BillingHistoryItem?
    
    let isFetching = BehaviorRelay(value: false)
    let isError = BehaviorRelay(value: false)
    let enablePaymentDateButton = BehaviorRelay(value: false)
    
    let walletItems = BehaviorRelay<[WalletItem]?>(value: nil)
    let selectedWalletItem = BehaviorRelay<WalletItem?>(value: nil)
    
    let amountDue: BehaviorRelay<Double>
    let paymentAmount: BehaviorRelay<Double>
    let paymentDate: BehaviorRelay<Date>
    let selectedDate: BehaviorRelay<Date>
    
    let editpaymentAmountValue = BehaviorRelay<Double>(value: 0)
    
    let paymentId = BehaviorRelay<String?>(value: nil)
    let wouldBeSelectedWalletItemIsExpired = BehaviorRelay(value: false)
    
    let overpayingSwitchValue = BehaviorRelay(value: false)
    
    let emailAddress = BehaviorRelay(value: "")
    let phoneNumber = BehaviorRelay(value: "")
    
    init(walletService: WalletService,
         paymentService: PaymentService,
         accountDetail: AccountDetail,
         billingHistoryItem: BillingHistoryItem?) {
        self.walletService = walletService
        self.paymentService = paymentService
        self.accountDetail = BehaviorRelay(value: accountDetail)
        self.billingHistoryItem = billingHistoryItem
        
        if let billingHistoryItem = billingHistoryItem { // Editing a payment
            paymentId.accept(billingHistoryItem.paymentId)
            selectedWalletItem.accept(WalletItem(maskedWalletItemAccountNumber: billingHistoryItem.maskedWalletItemAccountNumber,
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
        walletService.fetchWalletItems()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] walletItems in
                guard let self = self else { return }
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
                }, onError: { [weak self] _ in
                    self?.isFetching.accept(false)
                    self?.isError.accept(true)
                    onError?()
            }).disposed(by: disposeBag)
    }
    
    // MARK: - Payment Date Stuff
    
    // See the "Billing Scenarios (Grid View)" document on Confluence for these rules
    func computeDefaultPaymentDate() {
        paymentDate.accept(.now)
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
    
    private(set) lazy var paymentDateString: Driver<String> = paymentDate.asDriver()
        .map {
            return  $0.isInToday(calendar: .opCo) ? ("Today, " + $0.fullMonthDayAndYearString) :  $0.mmDdYyyyString
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
    
    private(set) lazy var shouldShowSameDayPaymentWarning: Driver<Bool> =
        self.paymentDate.asDriver().map { date in
            return date.isInToday(calendar: .opCo)
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
    private(set) lazy var enablePaymentDate: Driver<Bool> =
        self.enablePaymentDateButton.asDriver().map {_ in
            return self.canEditPaymentDate
    }
    
    private(set) lazy var walletItem: Observable<WalletItem?> = self.walletItems.map { $0?.first(where: { $0.isDefault }) }
    
    private lazy var accountDetailDriver: Driver<AccountDetail> =
        accountDetail.asDriver(onErrorDriveWith: .empty())
    
    private lazy var walletItemDriver: Driver<WalletItem?> = walletItem.asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var reviewPaymentShouldShowConvenienceFee: Driver<Bool> =
        self.selectedWalletItem.asDriver().map { $0?.bankOrCard == .card }
    
    private(set) lazy var isActiveSeveranceUser: Driver<Bool> = self.accountDetailDriver.map { $0.isActiveSeverance }
    
    private(set) lazy var totalPaymentDisplayString: Driver<String?> = Driver
        .combineLatest(paymentAmount.asDriver(), reviewPaymentShouldShowConvenienceFee)
        .map { [weak self] paymentAmount, showConvenienceFeeBox in
            guard let self = self else { return nil }
            if showConvenienceFeeBox {
                return (paymentAmount + self.convenienceFee).currencyString
            } else {
                return paymentAmount.currencyString
            }
    }
    
    var convenienceFee: Double {
        return accountDetail.value.billingInfo.convenienceFee
    }
    
    private(set) lazy var convenienceDisplayString: Driver<String?> =
        Driver.combineLatest(self.selectedWalletItem.asDriver(), walletItemDriver) { selectedWalletItem, walletItem in
            guard let walletItem = walletItem else {
                return NSLocalizedString("with no convenience fee", comment: "")
                
            }
            if selectedWalletItem?.bankOrCard == .bank {
                return NSLocalizedString("with no convenience fee", comment: "")
            } else {
                return String.localizedStringWithFormat("with a %@ convenience fee included, applied by Paymentus, our payment partner.", self.convenienceFee.currencyString)
            }
    }
    
    private(set) lazy var dueAmountDescriptionText: Driver<NSAttributedString> = accountDetailDriver.map {
        let billingInfo = $0.billingInfo
        var attributes: [NSAttributedString.Key: Any] = [.font: SystemFont.regular.of(textStyle: .caption1),
                                                         .foregroundColor: UIColor.deepGray]
        let string: String
        guard let dueAmount = billingInfo.netDueAmount else { return NSAttributedString() }
        attributes[.foregroundColor] = UIColor.deepGray
        attributes[.font] = SystemFont.semibold.of(size: 17)
        if billingInfo.pastDueAmount > 0 {
            if billingInfo.pastDueAmount == billingInfo.netDueAmount {
                string = String.localizedStringWithFormat("You have %@ due immediately", dueAmount.currencyString)
                attributes[.foregroundColor] = UIColor.errorRed
                attributes[.font] = SystemFont.semibold.of(size: 17)
            } else {
                string = String.localizedStringWithFormat("You have %@ due by %@", dueAmount.currencyString, billingInfo.dueByDate?.fullMonthDayAndYearString ?? "--")
            }
        }  else {
            string = String.localizedStringWithFormat("You have %@ due by %@", dueAmount.currencyString, billingInfo.dueByDate?.fullMonthDayAndYearString ?? "--")
        }
        
        return NSAttributedString(string: string, attributes: attributes)
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
    
    private(set) lazy var isCashOnlyUser: Driver<Bool> = self.accountDetailDriver.map { $0.isCashOnly }
    
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
    
    private(set) lazy var shouldShowContent: Driver<Bool> =
        Driver.combineLatest(self.isFetching.asDriver(),
                             self.isError.asDriver())
        { !$0 && !$1 }
    private(set) lazy var shouldShowStickyFooterView: Driver<Bool> = Driver.combineLatest(self.hasWalletItems, self.shouldShowContent)
    { $0 && $1 }
    
    // MARK: - Review Payment Drivers
    
    private(set) lazy var reviewPaymentSubmitButtonEnabled: Driver<Bool> = Driver
        .combineLatest(
            self.emailIsValidBool.asDriver(),
            self.phoneNumberHasTenDigits.asDriver(),
            self.hasWalletItems.asDriver(),
            self.shouldShowPaymentMethodExpiredButton.asDriver(),
            isOverpaying,
            overpayingSwitchValue.asDriver())
        {
            if !$0 || !$1 || !$2 || $3{
                return false
            }
            if $4 && !$5 {
                return false
            }
            
            return true
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
    
    private(set) lazy var shouldShowPaymentMethodExpiredButton: Driver<Bool> =
        self.wouldBeSelectedWalletItemIsExpired.asDriver()
    
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
    
    private(set) lazy var paymentAmountErrorMessage: Driver<String?> = {
        return Driver.combineLatest(selectedWalletItem.asDriver(),
                                    accountDetail.asDriver(),
                                    editpaymentAmountValue.asDriver(),
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
    
    private(set) lazy var paymentFieldsValid: Driver<Bool> = Driver
        .combineLatest(shouldShowContent, paymentAmountErrorMessage, isPaymentDateValid) {
            return $0 && $1 == nil && $2
    }
    
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
        { "Overpaying: "+($1 - $0).currencyString }
    
    private(set) lazy var shouldShowOverpaymentSwitchView: Driver<Bool> = isOverpaying
}
