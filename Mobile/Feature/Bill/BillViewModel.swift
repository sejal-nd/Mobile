//
//  BillViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 4/20/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

enum FetchingAccountState {
	case refresh, switchAccount
}

enum MakePaymentStatusTextRouting {
    case activity, autoPay, nowhere
}

class BillViewModel {
    
    let disposeBag = DisposeBag()
    
    private let accountService: AccountService
    private let authService: AuthenticationService
    private let usageService: UsageService

    let fetchAccountDetail = PublishSubject<FetchingAccountState>()
    let refreshTracker = ActivityTracker()
    let switchAccountsTracker = ActivityTracker()
    let usageBillImpactLoading = PublishSubject<Bool>()
    var usageBillImpactInnerLoading = false
    
    let electricGasSelectedSegmentIndex = BehaviorRelay(value: 0)
    let compareToLastYear = BehaviorRelay(value: false)
    
    private func tracker(forState state: FetchingAccountState) -> ActivityTracker {
        switch state {
        case .refresh: return refreshTracker
        case .switchAccount: return switchAccountsTracker
        }
    }
    
    required init(accountService: AccountService, authService: AuthenticationService, usageService: UsageService) {
        self.accountService = accountService
        self.authService = authService
        self.usageService = usageService
    }
    
    private lazy var fetchTrigger = Observable
        .merge(fetchAccountDetail,
               RxNotifications.shared.accountDetailUpdated.mapTo(FetchingAccountState.switchAccount),
               RxNotifications.shared.recentPaymentsUpdated.mapTo(FetchingAccountState.switchAccount))
    
    // Awful maintenance mode check
    private lazy var maintenanceModeEvents: Observable<Event<Maintenance>> = fetchTrigger
        .toAsyncRequest(activityTracker: { [weak self] in self?.tracker(forState: $0) },
                        requestSelector: { [unowned self] _ in self.authService.getMaintenanceMode() })
    
    private(set) lazy var dataEvents: Observable<Event<(AccountDetail, PaymentItem?)>> = maintenanceModeEvents
        .filter { !($0.element?.allStatus ?? false) && !($0.element?.billStatus ?? false) }
        .withLatestFrom(self.fetchTrigger)
        .toAsyncRequest(activityTracker: { [weak self] in
            self?.tracker(forState: $0)
        }, requestSelector: { [weak self] _ -> Observable<(AccountDetail, PaymentItem?)> in
            guard let self = self, AccountsStore.shared.currentIndex != nil else { return .empty() }
            let account = AccountsStore.shared.currentAccount
            let accountDetail = self.accountService.fetchAccountDetail(account: account)
            let scheduledPayment = self.accountService.fetchScheduledPayments(accountNumber: account.accountNumber).map { $0.last }
            return Observable.zip(accountDetail, scheduledPayment)
        })
        .do(onNext: { _ in UIAccessibility.post(notification: .screenChanged, argument: nil) })
    
    private lazy var usageBillImpactEvents: Observable<Event<BillComparison>> = Observable
        .combineLatest(dataEvents.elements().map { $0.0 }.filter { $0.isEligibleForUsageData },
                       compareToLastYear.asObservable(),
                       electricGasSelectedSegmentIndex.asObservable())
        .toAsyncRequest { [weak self] (accountDetail, compareToLastYear, electricGasIndex) in
            guard let self = self else { return .empty() }
            if !self.usageBillImpactInnerLoading {
                self.usageBillImpactLoading.onNext(true)
            }
            let isGas = self.isGas(accountDetail: accountDetail, electricGasSelectedIndex: electricGasIndex)
            return self.usageService.fetchBillComparison(accountNumber: accountDetail.accountNumber,
                                                         premiseNumber: accountDetail.premiseNumber!,
                                                         yearAgo: compareToLastYear,
                                                         gas: isGas)
        }
    
    private(set) lazy var accountDetailError: Driver<ServiceError?> = dataEvents.errors()
        .map { $0 as? ServiceError }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showLoadedState: Driver<Void> = dataEvents
        .filter { $0.element != nil && $0.element?.0.prepaidStatus != .active }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showUsageBillImpactFullLoading: Driver<Void> =
        Driver.combineLatest(self.usageBillImpactLoading.asDriver(onErrorJustReturn: false),
                             self.switchAccountsTracker.asDriver())
            .filter { $0 && !$1 }
            .mapTo(())
    
//    private(set) lazy var showUsageBillImpactEmptyState: Driver<Void> = dataEvents.elements()
//        .map { $0.0 }
//        .filter {
//            return !$0.isEligibleForUsageData && $0.isResidential
//        }
//        .mapTo(())
//        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showUsageBillImpactFullError: Driver<Void> = usageBillImpactEvents.errors()
        .do(onNext: { [weak self] _ in
            self?.usageBillImpactLoading.onNext(false)
        })
        .filter { [weak self] _ in
            guard let self = self else { return false }
            return !self.usageBillImpactInnerLoading
        }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showUsageBillImpactInnerError: Driver<Void> = usageBillImpactEvents.errors()
        .filter { [weak self] _ in
            guard let self = self else { return false }
            return self.usageBillImpactInnerLoading
        }
        .do(onNext: { [weak self] _ in
            self?.usageBillImpactInnerLoading = false
        })
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showUsageBillImpactContent: Driver<Void> = usageBillImpactEvents
        .filter { $0.element != nil }
        .do(onNext: { [weak self] _ in
            self?.usageBillImpactLoading.onNext(false)
            self?.usageBillImpactInnerLoading = false
        })
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showPrepaidState: Driver<Void> = currentAccountDetail
        .filter { $0.prepaidStatus == .active }
        .mapTo(())
    
	func fetchAccountDetail(isRefresh: Bool) {
		fetchAccountDetail.onNext(isRefresh ? .refresh: .switchAccount)
    }
    
    private(set) lazy var data = dataEvents.elements()
    
    private(set) lazy var currentAccountDetail: Driver<AccountDetail> = data
        .map { $0.0 }
        .asDriver(onErrorDriveWith: Driver.empty())
    

    private(set) lazy var currentBillComparison: Driver<BillComparison> = usageBillImpactEvents
        .elements()
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var scheduledPayment: Driver<PaymentItem?> = data
        .map { $0.1 }
        .asDriver(onErrorDriveWith: Driver.empty())
	
    // MARK: - Show/Hide Views
    
    private(set) lazy var showMaintenanceMode: Driver<Void> = maintenanceModeEvents.elements()
        .filter { $0.billStatus }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showAlertBanner: Driver<Bool> = {
        let showFromResponse = Driver
            .merge(self.dataEvents.errors().mapTo(false).asDriver(onErrorDriveWith: .empty()),
                   self.alertBannerText.isNil().not())
        return Driver.combineLatest(showFromResponse, self.switchAccountsTracker.asDriver()) { $0 && !$1 }
            .startWith(false)
    }()
        
    private(set) lazy var showBillNotReady: Driver<Bool> = currentAccountDetail.map {
        return $0.billingInfo.billDate == nil && ($0.billingInfo.netDueAmount == nil || $0.billingInfo.netDueAmount == 0)
    }
    
    private(set) lazy var showCreditScenario: Driver<Bool> = currentAccountDetail.map {
        guard let netDueAmount = $0.billingInfo.netDueAmount else { return false }
        return netDueAmount < 0 && Environment.shared.opco == .bge
    }
    
    private(set) lazy var showTotalAmountAndLedger: Driver<Bool> =
        Driver.combineLatest(self.showBillNotReady, self.showCreditScenario) { !$0 && !$1 }

    private(set) lazy var showPastDue: Driver<Bool> = currentAccountDetail
        .map { accountDetail -> Bool in
            let pastDueAmount = accountDetail.billingInfo.pastDueAmount
            return pastDueAmount > 0 && pastDueAmount != accountDetail.billingInfo.netDueAmount
    }
    
    private(set) lazy var showCurrentBill: Driver<Bool> = currentAccountDetail
        .map { accountDetail -> Bool in
            let currentDueAmount = accountDetail.billingInfo.currentDueAmount
            return currentDueAmount > 0 && currentDueAmount != accountDetail.billingInfo.netDueAmount
    }
        
    private(set) lazy var showPendingPayment: Driver<Bool> = currentAccountDetail.map {
        $0.billingInfo.pendingPaymentsTotal > 0
    }
    
    private(set) lazy var showRemainingBalanceDue: Driver<Bool> = currentAccountDetail.map {
        $0.billingInfo.pendingPaymentsTotal > 0 && $0.billingInfo.remainingBalanceDue > 0
    }
    
    private(set) lazy var showPaymentReceived: Driver<Bool> = currentAccountDetail.map {
        $0.billingInfo.lastPaymentAmount > 0 && $0.billingInfo.netDueAmount ?? 0 == 0
    }
    
    let showAmountDueTooltip = Environment.shared.opco == .peco
    
    private(set) lazy var showMakeAPaymentButton: Driver<Bool> = currentAccountDetail.map {
        $0.billingInfo.netDueAmount > 0 || Environment.shared.opco == .bge
    }
    
    private(set) lazy var showBillPaidFakeButton: Driver<Bool> =
        Driver.combineLatest(self.showMakeAPaymentButton, self.showBillNotReady) { !$0 && !$1 }
    
    private(set) lazy var showPaymentStatusText = paymentStatusText.isNil().not()
    
    private(set) lazy var showAutoPay: Driver<Bool> = currentAccountDetail.map {
        $0.isAutoPay || $0.isBGEasy || $0.isAutoPayEligible
    }
    
    private(set) lazy var showPaperless: Driver<Bool> = currentAccountDetail.map {
        // ComEd/PECO commercial customers should always see the button
        if !$0.isResidential && Environment.shared.opco != .bge {
            return true
        }
        
        switch $0.eBillEnrollStatus {
        case .canEnroll, .canUnenroll: return true
        case .ineligible, .finaled: return false
        }
    }
    
    private(set) lazy var showBudget: Driver<Bool> = currentAccountDetail.map {
        return $0.isBudgetBillEligible ||
            $0.isBudgetBillEnrollment ||
            Environment.shared.opco == .bge
    }
    
    //MARK: - Banner Alert Text
    
    private(set) lazy var alertBannerText: Driver<String?> = currentAccountDetail.map { accountDetail in
        let billingInfo = accountDetail.billingInfo
        
        // Finaled
        if billingInfo.pastDueAmount > 0 && accountDetail.isFinaled {
            if billingInfo.pastDueAmount == billingInfo.netDueAmount {
                return String.localizedStringWithFormat("%@ is past due and must be paid immediately. Your account has been finaled and is no longer connected to your premise address.", billingInfo.pastDueAmount?.currencyString ?? "--")
            } else {
                return String.localizedStringWithFormat("%@ is past due and must be paid immediately. Your account has been finaled and is no longer connected to your premise address.", billingInfo.pastDueAmount?.currencyString ?? "--")
            }
        }
        
        // Restore Service
        if let restorationAmount = accountDetail.billingInfo.restorationAmount,
            restorationAmount > 0 &&
            accountDetail.isCutOutNonPay &&
            Environment.shared.opco != .bge {
            if restorationAmount == billingInfo.netDueAmount {
                return NSLocalizedString("The total amount must be paid immediately to restore service. We cannot guarantee that your service will be reconnected same day.", comment: "")
            } else {
                return String.localizedStringWithFormat("%@ of the total must be paid immediately to restore service. We cannot guarantee that your service will be reconnected same day.", restorationAmount.currencyString)
            }
        }
        
        // Avoid Shutoff
        if let arrears = billingInfo.disconnectNoticeArrears, arrears > 0 {
            let amountString = arrears.currencyString
            let date = billingInfo.turnOffNoticeExtendedDueDate ?? billingInfo.turnOffNoticeDueDate
            let days = date?.interval(ofComponent: .day, fromDate: Calendar.opCo.startOfDay(for: .now)) ?? 0
            let dateString = date?.mmDdYyyyString ?? "--"
            
            switch (days > 0, accountDetail.isCutOutIssued, arrears == billingInfo.netDueAmount) {
            case (true, true, true):
                let format = "The total amount must be paid by %@ to avoid shutoff. We cannot guarantee your service will not be shut off the same day as the payment."
                return String.localizedStringWithFormat(format, dateString)
            case (true, true, false):
                let format = "%@ of the total must be paid by %@ to avoid shutoff. We cannot guarantee your service will not be shut off the same day as the payment."
                return String.localizedStringWithFormat(format, amountString, dateString)
            case (true, false, true):
                let format = "The total amount must be paid by %@ to avoid shutoff."
                return String.localizedStringWithFormat(format, dateString)
            case (true, false, false):
                let format = "%@ of the total must be paid by %@ to avoid shutoff."
                return String.localizedStringWithFormat(format, amountString, dateString)
            case (false, true, true):
                return NSLocalizedString("The total amount must be paid immediately to avoid shutoff. We cannot guarantee your service will not be shut off the same day as the payment.", comment: "")
            case (false, true, false):
                let format = "%@ of the total must be paid immediately to avoid shutoff. We cannot guarantee your service will not be shut off the same day as the payment."
                return String.localizedStringWithFormat(format, amountString)
            case (false, false, true):
                return NSLocalizedString("The total amount must be paid immediately to avoid shutoff.", comment: "")
            case (false, false, false):
                let format = "%@ of the total must be paid immediately to avoid shutoff."
                return String.localizedStringWithFormat(format, amountString)
            }
        }
        
        // Catch Up
        if let dueByDate = billingInfo.dueByDate,
            let amtDpaReinst = billingInfo.amtDpaReinst,
            Environment.shared.opco != .bge && amtDpaReinst > 0 {
            let days = dueByDate.interval(ofComponent: .day, fromDate: Calendar.opCo.startOfDay(for: .now))
            let amountString = amtDpaReinst.currencyString
            
            let string: String
            switch (days > 0 && Environment.shared.opco != .peco, billingInfo.amtDpaReinst == billingInfo.netDueAmount) {
            case (true, true):
                let format = "The total amount must be paid by %@ to catch up on your DPA."
                return String.localizedStringWithFormat(format, dueByDate.mmDdYyyyString)
            case (true, false):
                let format = "%@ of the total must be paid by %@ to catch up on your DPA."
                return String.localizedStringWithFormat(format, amountString, dueByDate.mmDdYyyyString)
            case (false, true):
                return NSLocalizedString("The total amount must be paid immediately to catch up on your DPA.", comment: "")
            case (false, false):
                let format = "%@ of the total must be paid immediately to catch up on your DPA."
                return String.localizedStringWithFormat(format, amountString)
            }
        }
        
        // Past Due
        if let pastDueAmount = billingInfo.pastDueAmount, pastDueAmount > 0 {
            if pastDueAmount == billingInfo.netDueAmount {
                return NSLocalizedString("Your bill is past due.", comment: "")
            } else {
                let format = "%@ of the total is due immediately.".localized()
                return String(format: format, pastDueAmount.currencyString)
            }
        }
        
        return nil
    }
    
    private(set) lazy var alertBannerA11yText: Driver<String?> = alertBannerText.map {
        $0?.replacingOccurrences(of: "shutoff", with: "shut-off")
    }
    
    //MARK: - MultiPremise Handling
    
    private(set) lazy var showMultipremiseHeader: Driver<Bool> = currentAccountDetail.map { _ in
        return AccountsStore.shared.currentAccount.isMultipremise
    }
    
    private(set) lazy var premiseAddressString: Driver<String?> = currentAccountDetail.map { _ in
        AccountsStore.shared.currentAccount.currentPremise?.addressLineString
    }
    
    //MARK: - Total Amount Due
    
    private(set) lazy var totalAmountText: Driver<String> = currentAccountDetail.map {
        guard let netDueAmount = $0.billingInfo.netDueAmount else { return "--" }
        
        switch Environment.shared.opco {
        case .bge: // For credit scenario we want to show the positive number
            return abs(netDueAmount).currencyString
        case .comEd, .peco:
            return max(netDueAmount, 0).currencyString
        }
    }
    
    private(set) lazy var totalAmountDescriptionText: Driver<NSAttributedString> = currentAccountDetail.map {
        let billingInfo = $0.billingInfo
        var attributes: [NSAttributedString.Key: Any] = [.font: SystemFont.regular.of(textStyle: .caption1),
                                                         .foregroundColor: UIColor.deepGray]
        let string: String
        if billingInfo.pastDueAmount > 0 {
            if billingInfo.pastDueAmount == billingInfo.netDueAmount {
                string = "Total Amount Due Immediately".localized()
                attributes[.foregroundColor] = UIColor.errorRed
                attributes[.font] = SystemFont.semibold.of(textStyle: .caption1)
            } else {
                string = NSLocalizedString("Total Amount Due", comment: "")
            }
        } else if billingInfo.amtDpaReinst > 0 {
            string = NSLocalizedString("Total Amount Due", comment: "")
        } else if billingInfo.lastPaymentAmount > 0 && billingInfo.netDueAmount ?? 0 == 0 {
            string = NSLocalizedString("Total Amount Due", comment: "")
        } else {
            string = String.localizedStringWithFormat("Total Amount Due By %@", billingInfo.dueByDate?.mmDdYyyyString ?? "--")
        }
        
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    //MARK: - Past Due
    private(set) lazy var pastDueText: Driver<String> = currentAccountDetail
        .map { accountDetail in
            let billingInfo = accountDetail.billingInfo
            if Environment.shared.opco != .bge && billingInfo.amtDpaReinst > 0 &&
                billingInfo.amtDpaReinst == billingInfo.pastDueAmount {
                return NSLocalizedString("Catch Up on Agreement Amount", comment: "")
            } else {
                return NSLocalizedString("Past Due Amount", comment: "")
            }
    }
    
    private(set) lazy var pastDueAmountText: Driver<String> = currentAccountDetail.map {
        if Environment.shared.opco != .bge && $0.billingInfo.amtDpaReinst > 0 &&
            $0.billingInfo.amtDpaReinst == $0.billingInfo.pastDueAmount {
            return $0.billingInfo.amtDpaReinst?.currencyString ?? "--"
        } else {
            return $0.billingInfo.pastDueAmount?.currencyString ?? "--"
        }
    }
    
    private(set) lazy var pastDueDateText: Driver<NSAttributedString> = currentAccountDetail
        .map { accountDetail in
            let billingInfo = accountDetail.billingInfo
            if let date = billingInfo.dueByDate,
                Environment.shared.opco != .bge &&
                billingInfo.amtDpaReinst > 0 &&
                billingInfo.amtDpaReinst == billingInfo.pastDueAmount {
                let string = String.localizedStringWithFormat("Due by %@", date.mmDdYyyyString)
                return NSAttributedString(string: string, attributes: [.foregroundColor: UIColor.middleGray,
                                                                       .font: SystemFont.regular.of(textStyle: .caption1)])
            } else {
                let string = "Due Immediately".localized()
                return NSAttributedString(string: string, attributes: [.foregroundColor: UIColor.errorRed,
                                                                       .font: SystemFont.semibold.of(textStyle: .caption1)])
            }
    }
    
    //MARK: - Current Bill
    private(set) lazy var currentBillAmountText: Driver<String> = currentAccountDetail.map {
        $0.billingInfo.currentDueAmount?.currencyString ?? "--"
    }
    
    private(set) lazy var currentBillDateText: Driver<String> = currentAccountDetail.map {
        String.localizedStringWithFormat("Due by %@", $0.billingInfo.dueByDate?.mmDdYyyyString ?? "--")
    }
    
    //MARK: - Payment Received
    private(set) lazy var paymentReceivedAmountText: Driver<String> = currentAccountDetail.map {
        $0.billingInfo.lastPaymentAmount?.currencyString ?? "--"
    }
    
    private(set) lazy var paymentReceivedDateText: Driver<String?> = currentAccountDetail.map {
        guard let dateString = $0.billingInfo.lastPaymentDate?.mmDdYyyyString else { return nil }
        let localizedText = NSLocalizedString("Payment Date %@", comment: "")
        return String(format: localizedText, dateString)
    }
    
    //MARK: - Pending Payments
    let pendingPaymentsText: String = {
        switch Environment.shared.opco {
        case .bge:
            return NSLocalizedString("Payments Processing", comment: "")
        case .comEd, .peco:
            return NSLocalizedString("Pending Payments", comment: "")
        }
    }()
    
    private(set) lazy var pendingPaymentsTotalAmountText: Driver<String> = currentAccountDetail.map {
        (-$0.billingInfo.pendingPaymentsTotal).currencyString
    }
    
    //MARK: - Remaining Balance Due
    let remainingBalanceDueText = NSLocalizedString("Remaining Balance Due", comment: "")
    
    private(set) lazy var remainingBalanceDueAmountText: Driver<String> = currentAccountDetail.map {
        if $0.billingInfo.pendingPaymentsTotal == $0.billingInfo.netDueAmount ?? 0 {
            return 0.currencyString
        } else {
            return $0.billingInfo.remainingBalanceDue?.currencyString ?? "--"
        }
    }
    
    //MARK: - Catch Up
    private(set) lazy var showCatchUpDisclaimer: Driver<Bool> = currentAccountDetail.map {
        !$0.isLowIncome && $0.billingInfo.amtDpaReinst > 0 && Environment.shared.opco == .comEd
    }
    
    private(set) lazy var catchUpDisclaimerText: Driver<String> = currentAccountDetail.map {
        let localizedText = NSLocalizedString("You are entitled to one free reinstatement per plan. Any additional reinstatement will incur a %@ fee on your next bill.", comment: "")
        return String(format: localizedText, $0.billingInfo.atReinstateFee?.currencyString ?? "--")
    }
    
    //MARK: - Payment Status
    private(set) lazy var paymentStatusText: Driver<String?> = data
        .map { accountDetail, scheduledPayment in
            if Environment.shared.opco == .bge && accountDetail.isBGEasy {
                return NSLocalizedString("You are enrolled in BGEasy", comment: "")
            } else if accountDetail.isAutoPay {
                return NSLocalizedString("You are enrolled in AutoPay", comment: "")
            } else if let scheduledPaymentAmount = scheduledPayment?.amount,
                let scheduledPaymentDate = scheduledPayment?.date,
                scheduledPaymentAmount > 0 {
                return String(format: NSLocalizedString("Thank you for scheduling your %@ payment for %@", comment: ""), scheduledPaymentAmount.currencyString, scheduledPaymentDate.mmDdYyyyString)
            } else if let lastPaymentAmount = accountDetail.billingInfo.lastPaymentAmount,
                let lastPaymentDate = accountDetail.billingInfo.lastPaymentDate,
                lastPaymentAmount > 0,
                let billDate = accountDetail.billingInfo.billDate,
                billDate < lastPaymentDate {
                return String(format: NSLocalizedString("Thank you for %@ payment on %@", comment: ""), lastPaymentAmount.currencyString, lastPaymentDate.mmDdYyyyString)
            }
            return nil
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var makePaymentScheduledPaymentAlertInfo: Observable<(String?, String?, AccountDetail)> = data
        .map { accountDetail, scheduledPayment in
            if Environment.shared.opco == .bge && accountDetail.isBGEasy {
                return (NSLocalizedString("Existing Automatic Payment", comment: ""), NSLocalizedString("You are already " +
                    "enrolled in our BGEasy direct debit payment option. BGEasy withdrawals process on the due date " +
                    "of your bill from the bank account you originally submitted. You may make a one-time payment " +
                    "now, but it may result in duplicate payment processing. Do you want to continue with a " +
                    "one-time payment?", comment: ""), accountDetail)
            } else if accountDetail.isAutoPay {
                return (NSLocalizedString("Existing Automatic Payment", comment: ""), NSLocalizedString("You currently " +
                    "have automatic payments set up. To avoid a duplicate payment, please review your payment " +
                    "activity before proceeding. Would you like to continue making an additional payment?\n\nNote: " +
                    "If you recently enrolled in AutoPay and you have not yet received a new bill, you will need " +
                    "to submit a payment for your current bill if you have not already done so.", comment: ""), accountDetail)
            } else if let scheduledPaymentAmount = scheduledPayment?.amount,
                let scheduledPaymentDate = scheduledPayment?.date,
                scheduledPaymentAmount > 0 {
                let localizedTitle = NSLocalizedString("Existing Scheduled Payment", comment: "")
                return (localizedTitle, String(format: NSLocalizedString("You have a payment of %@ scheduled for %@. " +
                    "To avoid a duplicate payment, please review your payment activity before proceeding. Would " +
                    "you like to continue making an additional payment?", comment: ""),
                                               scheduledPaymentAmount.currencyString, scheduledPaymentDate.mmDdYyyyString), accountDetail)
            }
            return (nil, nil, accountDetail)
    }
    
    private(set) lazy var makePaymentStatusTextTapRouting: Driver<MakePaymentStatusTextRouting> = data
        .map { accountDetail, scheduledPayment in
            guard !accountDetail.isBGEasy else { return .nowhere }
            if accountDetail.isAutoPay {
                return .autoPay
            } else if scheduledPayment?.amount > 0 {
                return .activity
            }
            return .nowhere
        }
        .asDriver(onErrorDriveWith: .empty())
    
    //MARK: - Bill Breakdown
    
    private(set) lazy var hasBillBreakdownData: Driver<Bool> = currentAccountDetail.map {
        let supplyCharges = $0.billingInfo.supplyCharges ?? 0
        let taxesAndFees = $0.billingInfo.taxesAndFees ?? 0
        let deliveryCharges = $0.billingInfo.deliveryCharges ?? 0
        let totalCharges = supplyCharges + taxesAndFees + deliveryCharges
        return totalCharges > 0
    }
    
    // MARK: - Usage Bill Impact
    
    private(set) lazy var showElectricGasSegmentedControl: Driver<Bool> = currentAccountDetail.map {
        $0.serviceType?.uppercased() == "GAS/ELECTRIC"
    }
    
    // MARK: Up/Down Arrow Image Drivers
    
    private(set) lazy var reasonsWhyLabelText: Driver<String?> = currentBillComparison.map {
            guard let reference = $0.reference, let compared = $0.compared else {
                return NSLocalizedString("Reasons Why Your Bill is...", comment: "")
            }
            let currentCharges = reference.charges
            let prevCharges = compared.charges
            let difference = abs(currentCharges - prevCharges)
            if difference < 1 {
                return NSLocalizedString("Reasons Why Your Bill is About the Same", comment: "")
            } else {
                if currentCharges > prevCharges {
                    return NSLocalizedString("Reasons Why Your Bill is Higher", comment: "")
                } else {
                    return NSLocalizedString("Reasons Why Your Bill is Lower", comment: "")
                }
            }
        }
    
    private(set) lazy var differenceDescriptionLabelAttributedText: Driver<NSAttributedString?> =
        Driver.combineLatest(currentAccountDetail, currentBillComparison, compareToLastYear.asDriver())
        .filter { _ in self.usageBillImpactInnerLoading == false }.map { [weak self] accountDetail, billComparison, compareToLastYear in
            guard let self = self else { return nil }
            
            let isGas = self.isGas(accountDetail: accountDetail,
                                   electricGasSelectedIndex: self.electricGasSelectedSegmentIndex.value)
            let gasOrElectricString = isGas ? NSLocalizedString("gas", comment: "") : NSLocalizedString("electric", comment: "")
            
            guard let reference = billComparison.reference, let compared = billComparison.compared else {
                return NSAttributedString(string: String.localizedStringWithFormat("Data not available to explain likely reasons for changes in your %@ charges.", gasOrElectricString))
            }
                        
            let currentCharges = reference.charges
            let prevCharges = compared.charges
            let difference = abs(currentCharges - prevCharges)
            if difference < 1 { // About the same
                if compareToLastYear { // Last Year
                    return NSAttributedString(string: String.localizedStringWithFormat("Your %@ charges are about the same as last year.", gasOrElectricString))
                } else { // Previous Bill
                    return NSAttributedString(string: String.localizedStringWithFormat("Your %@ charges are about the same as your previous bill.", gasOrElectricString))
                }
            } else {
                if currentCharges > prevCharges {
                    let localizedString: String
                    if compareToLastYear { // Last Year
                        localizedString = String.localizedStringWithFormat("Your %@ charges are %@ more than last year.", gasOrElectricString, difference.currencyString)
                    } else { // Previous Bill
                        localizedString = String.localizedStringWithFormat("Your %@ charges are %@ more than your previous bill.", gasOrElectricString, difference.currencyString)
                    }
                    let attrString = NSMutableAttributedString(string: localizedString)
                    attrString.addAttribute(.font, value: OpenSans.semibold.of(textStyle: .callout), range: (localizedString as NSString).range(of: difference.currencyString))
                    return attrString
                } else {
                    let localizedString: String
                    if compareToLastYear { // Last Year
                        localizedString = String.localizedStringWithFormat("Your %@ charges are %@ less than last year.", gasOrElectricString, difference.currencyString)
                    } else { // Previous Bill
                        localizedString = String.localizedStringWithFormat("Your %@ charges are %@ less than your previous bill.", gasOrElectricString, difference.currencyString)
                    }
                    let attrString = NSMutableAttributedString(string: localizedString)
                    attrString.addAttribute(.font, value: OpenSans.semibold.of(textStyle: .callout), range: (localizedString as NSString).range(of: difference.currencyString))
                    return attrString
                }
            }
        }

    private(set) lazy var billPeriodArrowImage: Driver<UIImage?> = currentBillComparison.map {
        if $0.billPeriodCostDifference >= 1 {
            return #imageLiteral(resourceName: "ic_trendup.pdf")
        } else if $0.billPeriodCostDifference <= -1 {
            return #imageLiteral(resourceName: "ic_trenddown.pdf")
        } else {
            return #imageLiteral(resourceName: "ic_trendequal.pdf")
        }
    }
    
    private(set) lazy var billPeriodDetailLabelText: Driver<String?> =
        Driver.combineLatest(currentAccountDetail, currentBillComparison, electricGasSelectedSegmentIndex.asDriver())
        { [weak self] accountDetail, billComparison, electricGasSelectedIndex in
            guard let self = self else { return nil }
            
            guard let reference = billComparison.reference, let compared = billComparison.compared else {
                return NSLocalizedString("Data not available.", comment: "")
            }
            
            let isGas = self.isGas(accountDetail: accountDetail,
                                   electricGasSelectedIndex: electricGasSelectedIndex)
            let gasOrElectricityString = isGas ? NSLocalizedString("gas", comment: "") : NSLocalizedString("electricity", comment: "")
            
            let daysInCurrentBillPeriod = abs(reference.startDate.interval(ofComponent: .day, fromDate: reference.endDate))
            let daysInPreviousBillPeriod = abs(compared.startDate.interval(ofComponent: .day, fromDate: compared.endDate))
            let billPeriodDiff = abs(daysInCurrentBillPeriod - daysInPreviousBillPeriod)
            
            var localizedString: String!
            if billComparison.billPeriodCostDifference >= 1 {
                localizedString = NSLocalizedString("Your bill was about %@ more. You used more %@ because this bill period was %d days longer.", comment: "")
            } else if billComparison.billPeriodCostDifference <= -1 {
                localizedString = NSLocalizedString("Your bill was about %@ less. You used less %@ because this bill period was %d days shorter.", comment: "")
            } else {
                return NSLocalizedString("You spent about the same based on the number of days in your billing period.", comment: "")
            }
            return String(format: localizedString, abs(billComparison.billPeriodCostDifference).currencyString, gasOrElectricityString, billPeriodDiff)
        }
    
    private(set) lazy var weatherArrowImage: Driver<UIImage?> = currentBillComparison.map {
        if $0.weatherCostDifference >= 1 {
            return #imageLiteral(resourceName: "ic_trendup.pdf")
        } else if $0.weatherCostDifference <= -1 {
            return #imageLiteral(resourceName: "ic_trenddown.pdf")
        } else {
            return #imageLiteral(resourceName: "ic_trendequal.pdf")
        }
    }
    
    private(set) lazy var weatherDetailLabelText: Driver<String?> =
        Driver.combineLatest(currentAccountDetail, currentBillComparison, electricGasSelectedSegmentIndex.asDriver())
        { [weak self] accountDetail, billComparison, electricGasSelectedIndex in
            guard let self = self else { return nil }
            
            let isGas = self.isGas(accountDetail: accountDetail,
                                   electricGasSelectedIndex: electricGasSelectedIndex)
            let gasOrElectricityString = isGas ? NSLocalizedString("gas", comment: "") : NSLocalizedString("electricity", comment: "")
            
            var localizedString: String!
            if billComparison.weatherCostDifference >= 1 {
                localizedString = NSLocalizedString("Your bill was about %@ more. You used more %@ due to changes in weather.", comment: "")
            } else if billComparison.weatherCostDifference <= -1 {
                localizedString = NSLocalizedString("Your bill was about %@ less. You used less %@ due to changes in weather.", comment: "")
            } else {
                return NSLocalizedString("You spent about the same based on weather conditions.", comment: "")
            }
            return String(format: localizedString, abs(billComparison.weatherCostDifference).currencyString, gasOrElectricityString)
    }
    
    private(set) lazy var otherArrowImage: Driver<UIImage?> = currentBillComparison.map {
        if $0.otherCostDifference >= 1 {
            return #imageLiteral(resourceName: "ic_trendup.pdf")
        } else if $0.otherCostDifference <= -1 {
            return #imageLiteral(resourceName: "ic_trenddown.pdf")
        } else {
            return #imageLiteral(resourceName: "ic_trendequal.pdf")
        }
    }
    
    private(set) lazy var otherDetailLabelText: Driver<String?> =
        Driver.combineLatest(currentAccountDetail, currentBillComparison, electricGasSelectedSegmentIndex.asDriver())
        { [weak self] accountDetail, billComparison, electricGasSelectedIndex in
            guard let self = self else { return nil }
                        
            var localizedString: String!
            if billComparison.otherCostDifference >= 1 {
                localizedString = NSLocalizedString("Your bill was about %@ more. Your charges increased based on how you used energy. Your bill may be different for " +
                    "a variety of reasons, including:\n• Number of people and amount of time spent in your home\n• New appliances or electronics\n• Differences in rate " +
                    "plans or cost of energy", comment: "")
            } else if billComparison.otherCostDifference <= -1 {
                localizedString = NSLocalizedString("Your bill was about %@ less. Your charges decreased based on how you used energy. Your bill may be different for " +
                    "a variety of reasons, including:\n• Number of people and amount of time spent in your home\n• New appliances or electronics\n• Differences in rate " +
                    "plans or cost of energy", comment: "")
            } else {
                return NSLocalizedString("You spent about the same based on a variety reasons, including:\n• Number of people and amount of time spent in your home\n" +
                    "• New appliances or electronics\n• Differences in rate plans or cost of energy", comment: "")
            }
            return String(format: localizedString, abs(billComparison.otherCostDifference).currencyString)
    }
    
    private(set) lazy var noPreviousData: Driver<Bool> = currentBillComparison.map { $0.compared == nil }
    
    //MARK: - Enrollment
    
    private(set) lazy var showPaperlessEnrolledView: Driver<Bool> = currentAccountDetail.map {
        // Always hide for ComEd/PECO commercial customers
        if !$0.isResidential && Environment.shared.opco != .bge {
            return false
        }
        return $0.eBillEnrollStatus == .canUnenroll
    }
    
    private(set) lazy var showAutoPayEnrolledView: Driver<Bool> = currentAccountDetail.map {
        if $0.isBGEasy {
            return false
        }
        return $0.isAutoPay
    }
    
    private(set) lazy var autoPayDetailLabelText: Driver<NSAttributedString> = currentAccountDetail.map {
        if $0.isBGEasy {
            let text = NSLocalizedString("Enrolled in BGEasy.", comment: "")
            return NSAttributedString(string: text, attributes: [.foregroundColor: UIColor.successGreenText])
        } else {
            let text = NSLocalizedString("Set up automatic, recurring payments.", comment: "")
            return NSAttributedString(string: text, attributes: [.foregroundColor: UIColor.deepGray])
        }
    }
    
    private(set) lazy var autoPayAccessibilityLabel: Driver<String> = currentAccountDetail.map {
        if $0.isBGEasy {
            return NSLocalizedString("AutoPay. Enrolled in BGEasy.", comment: "")
        } else {
            return String.localizedStringWithFormat("AutoPay. Set up automatic, recurring payments.%@", $0.isAutoPay ? "Enrolled" : "")
        }
    }
    
    private(set) lazy var showBudgetEnrolledView: Driver<Bool> = currentAccountDetail.map {
        return $0.isBudgetBillEnrollment
    }
    
    // MARK: - Prepaid
    
    private(set) lazy var showPrepaidPending = Driver
        .combineLatest(currentAccountDetail, switchAccountsTracker.asDriver())
        { $0.prepaidStatus == .pending && !$1 }
        .startWith(false)
        .distinctUntilChanged()
    
    private(set) lazy var showPrepaidActive = Driver
        .combineLatest(currentAccountDetail, switchAccountsTracker.asDriver())
        { $0.prepaidStatus == .active && !$1 }
        .startWith(false)
        .distinctUntilChanged()
    
    var prepaidUrl: URL {
        return URL(string: Environment.shared.myAccountUrl)!
    }
    
    // MARK: - Helpers
    
    // If a gas only account, return true, if an electric only account, returns false, if both gas/electric, returns selected segemented control
    private func isGas(accountDetail: AccountDetail, electricGasSelectedIndex: Int) -> Bool {
        if accountDetail.serviceType?.uppercased() == "GAS" { // If account is gas only
            return true
        } else if Environment.shared.opco != .comEd && accountDetail.serviceType?.uppercased() == "GAS/ELECTRIC" {
            return electricGasSelectedIndex == 1
        }
        // Default to electric
        return false
    }
	
	// MARK: - Convenience functions
	
    private static func isEnrolledText(topText: String, bottomText: String) -> NSAttributedString {
        let mutableText = NSMutableAttributedString(string: topText + "\n" + bottomText)
        let topTextRange = NSMakeRange(0, topText.count)
        let bottomTextRange = NSMakeRange(topText.count + 1, bottomText.count)
        
        mutableText.addAttribute(.font, value: OpenSans.bold.of(size: 16), range: topTextRange)
        mutableText.addAttribute(.foregroundColor, value: UIColor.blackText, range: topTextRange)
        mutableText.addAttribute(.font, value: OpenSans.regular.of(size: 14), range: bottomTextRange)
        mutableText.addAttribute(.foregroundColor, value: UIColor.successGreenText, range: bottomTextRange)
        
        return mutableText
    }
    
    private static func canEnrollText(boldText: String) -> NSAttributedString {
        let text = NSLocalizedString("Would you like to enroll in ", comment: "")
        let mutableText = NSMutableAttributedString(string: text + boldText, attributes: [.foregroundColor: UIColor.blackText])
        
        mutableText.addAttribute(.font, value: OpenSans.regular.of(size: 16), range: NSMakeRange(0, text.count))
        mutableText.addAttribute(.font, value: OpenSans.bold.of(size: 16), range: NSMakeRange(text.count, boldText.count))
        
        return mutableText
    }
    
}




