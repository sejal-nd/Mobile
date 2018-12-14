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

    let fetchAccountDetail = PublishSubject<FetchingAccountState>()
    let refreshTracker = ActivityTracker()
    let switchAccountsTracker = ActivityTracker()
    
    private func tracker(forState state: FetchingAccountState) -> ActivityTracker {
        switch state {
        case .refresh: return refreshTracker
        case .switchAccount: return switchAccountsTracker
        }
    }
    
    required init(accountService: AccountService, authService: AuthenticationService) {
        self.accountService = accountService
        self.authService = authService
    }
    
    private lazy var fetchTrigger = Observable.merge(self.fetchAccountDetail,
                                                     RxNotifications.shared.accountDetailUpdated
                                                        .mapTo(FetchingAccountState.switchAccount))
    
    // Awful maintenance mode check
    private lazy var maintenanceModeEvents: Observable<Event<Maintenance>> = self.fetchTrigger
        .toAsyncRequest(activityTracker: { [weak self] in self?.tracker(forState: $0) },
                        requestSelector: { [unowned self] _ in self.authService.getMaintenanceMode() })
    
    
    private(set) lazy var dataEvents: Observable<Event<(AccountDetail, RecentPayments)>> = self.maintenanceModeEvents
        .filter { !($0.element?.billStatus ?? false) }
        .withLatestFrom(self.fetchTrigger)
        .toAsyncRequest(activityTracker: { [weak self] in
            self?.tracker(forState: $0)
            }, requestSelector: { [weak self] _ -> Observable<(AccountDetail, RecentPayments)> in
                guard let self = self, let account = AccountsStore.shared.currentAccount else { return .empty() }
                let accountDetail = self.accountService.fetchAccountDetail(account: account)
                let recentPayments = self.accountService.fetchRecentPayments(accountNumber: account.accountNumber)
                return Observable.zip(accountDetail, recentPayments)
        })
        .do(onNext: { _ in UIAccessibility.post(notification: .screenChanged, argument: nil) })
    
    private(set) lazy var accountDetailError: Driver<ServiceError?> = self.dataEvents.errors()
        .map { $0 as? ServiceError }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showLoadedState: Driver<Void> = self.dataEvents
        .filter { $0.error == nil }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
	func fetchAccountDetail(isRefresh: Bool) {
		fetchAccountDetail.onNext(isRefresh ? .refresh: .switchAccount)
    }
    
    private(set) lazy var data = dataEvents.elements()
    
    private(set) lazy var currentAccountDetail: Driver<AccountDetail> = data
        .map { $0.0 }
        .asDriver(onErrorDriveWith: Driver.empty())
    
    private(set) lazy var recentPayments: Driver<RecentPayments> = data
        .map { $0.1 }
        .asDriver(onErrorDriveWith: Driver.empty())
	
    // MARK: - Show/Hide Views -
    
    private(set) lazy var showMaintenanceMode: Driver<Void> = self.maintenanceModeEvents.elements()
        .filter { $0.billStatus }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var shouldShowAlertBanner: Driver<Bool> = {
        let showFromResponse = Driver
            .merge(self.dataEvents.errors().mapTo(false).asDriver(onErrorDriveWith: .empty()),
                   Driver.zip(self.shouldShowRestoreService, self.shouldShowAvoidShutoff).map { $0 || $1 })
        return Driver.combineLatest(showFromResponse, self.switchAccountsTracker.asDriver()) { $0 && !$1 }
            .startWith(false)
    }()
    
    private(set) lazy var shouldShowRestoreService: Driver<Bool> = self.currentAccountDetail.map {
        return $0.billingInfo.restorationAmount ?? 0 > 0 && $0.isCutOutNonPay && Environment.shared.opco != .bge
    }
    
    private(set) lazy var shouldShowAvoidShutoff: Driver<Bool> = {
        let showAvoidShutoff = self.currentAccountDetail.map { accountDetail -> Bool in
            (accountDetail.billingInfo.disconnectNoticeArrears ?? 0) > 0 && accountDetail.billingInfo.isDisconnectNotice
        }
        return Driver.zip(self.shouldShowRestoreService, showAvoidShutoff) { !$0 && $1 }
    }()
    
    private(set) lazy var shouldShowCatchUpAmount: Driver<Bool> = {
        let showCatchup = self.currentAccountDetail.map {
            $0.billingInfo.amtDpaReinst ?? 0 > 0
        }
        return Driver.zip(self.shouldShowRestoreService, self.shouldShowAvoidShutoff, showCatchup) { !$0 && !$1 && $2 }
    }()
    
    private(set) lazy var shouldShowCatchUpDisclaimer: Driver<Bool> = Driver.zip(self.currentAccountDetail, self.shouldShowCatchUpAmount)
    { !$0.isLowIncome && $1 && Environment.shared.opco == .comEd }
    
    private(set) lazy var shouldShowPastDue: Driver<Bool> = self.currentAccountDetail
        .map { accountDetail -> Bool in
            // shouldShowRestoreService
            if accountDetail.billingInfo.restorationAmount ?? 0 > 0 &&
                accountDetail.isCutOutNonPay &&
                Environment.shared.opco != .bge {
                return false
            }
            
            // shouldShowAvoidShutoff
            if (accountDetail.billingInfo.disconnectNoticeArrears ?? 0) > 0 && accountDetail.billingInfo.isDisconnectNotice {
                return false
            }
            
            // shouldShowCatchUpAmount
            if accountDetail.billingInfo.amtDpaReinst ?? 0 > 0 {
                return false
            }
            
            return accountDetail.billingInfo.pastDueAmount ?? 0 > 0
    }
    
    private(set) lazy var shouldShowTopContent: Driver<Bool> = Driver
        .combineLatest(self.switchAccountsTracker.asDriver(),
                       self.dataEvents.asDriver(onErrorDriveWith: .empty()))
        { !$0 && $1.error == nil }
        .startWith(false)
    
    private(set) lazy var pendingPaymentAmountDueBoxesAlpha: Driver<CGFloat> = self.recentPayments.map {
        guard let pendingPaymentAmount = $0.pendingPayments.first?.amount else { return 1.0 }
        return pendingPaymentAmount > 0 ? 0.5 : 1.0
    }
    
    private(set) lazy var shouldShowPendingPayment: Driver<Bool> = self.recentPayments.map {
        $0.pendingPayments.first?.amount ?? 0 > 0
    }
    
    private(set) lazy var shouldShowRemainingBalanceDue: Driver<Bool> = data
        .map { accountDetail, payments in
            return payments.pendingPayments.first?.amount ?? 0 > 0 &&
                accountDetail.billingInfo.remainingBalanceDue ?? 0 > 0  &&
                Environment.shared.opco != .bge
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var shouldShowRemainingBalancePastDue: Driver<Bool> = {
        let showRemainingPastDue = self.currentAccountDetail.map { accountDetail -> Bool in
            accountDetail.billingInfo.pastDueRemaining ?? 0 > 0
        }
        return Driver.zip(showRemainingPastDue, self.shouldShowPastDue) { $0 && $1 && Environment.shared.opco != .bge }
    }()
    
    private(set) lazy var shouldShowBillIssued: Driver<Bool> = self.currentAccountDetail.map { _ in
        //TODO: Bill Issued
        false
    }
    
    private(set) lazy var shouldShowPaymentReceived: Driver<Bool> = self.currentAccountDetail.map {
        $0.billingInfo.lastPaymentAmount ?? 0 > 0 && $0.billingInfo.netDueAmount ?? 0 == 0
    }
    
    private(set) lazy var shouldShowCredit: Driver<Bool> = self.currentAccountDetail.map {
        guard let netDueAmount = $0.billingInfo.netDueAmount else { return false }
        return netDueAmount < 0 && Environment.shared.opco == .bge
    }
    
    private(set) lazy var shouldShowAmountDueTooltip: Driver<Bool> = self.currentAccountDetail.map {
        $0.billingInfo.pastDueAmount ?? 0 <= 0 && Environment.shared.opco == .peco
    }
    
    private(set) lazy var shouldShowBillBreakdownButton: Driver<Bool> = self.currentAccountDetail
        .map { accountDetail in
            guard let serviceType = accountDetail.serviceType else { return false }
            
            // We need premiseNumber to make the usage API calls, so hide the button if we don't have it
            guard let premiseNumber = accountDetail.premiseNumber, !premiseNumber.isEmpty else { return false }
            
            if !accountDetail.isResidential || accountDetail.isBGEControlGroup || accountDetail.isFinaled {
                return false
            }
            
            // Must have valid serviceType
            if serviceType.uppercased() != "GAS" && serviceType.uppercased() != "ELECTRIC" && serviceType.uppercased() != "GAS/ELECTRIC" {
                return false
            }
            
            return true
    }
    
    private(set) lazy var shouldEnableMakeAPaymentButton: Driver<Bool> = self.currentAccountDetail.map {
        $0.billingInfo.netDueAmount ?? 0 > 0 || Environment.shared.opco == .bge
    }
    
    private(set) lazy var shouldShowAutoPay: Driver<Bool> = self.currentAccountDetail.map {
        $0.isAutoPay || $0.isBGEasy || $0.isAutoPayEligible
    }
    
    private(set) lazy var shouldShowPaperless: Driver<Bool> = self.currentAccountDetail.map {
        if !$0.isResidential && (Environment.shared.opco == .comEd || Environment.shared.opco == .peco) {
            return true
        }
        
        switch $0.eBillEnrollStatus {
        case .canEnroll, .canUnenroll: return true
        case .ineligible, .finaled: return false
        }
    }
    
    private(set) lazy var shouldShowBudget: Driver<Bool> = self.currentAccountDetail.map {
        return $0.isBudgetBillEligible ||
            $0.isBudgetBillEnrollment ||
            Environment.shared.opco == .bge
    }
    
    
	// MARK: - View Content
    
    
    //MARK: - Banner Alert Text
    
    private(set) lazy var alertBannerText: Driver<String?> = Driver.zip(self.restoreServiceAlertText,
                                                                     self.avoidShutoffAlertText,
                                                                     self.paymentFailedAlertText)
    { $0 ?? $1 ?? $2 }
    
    private(set) lazy var alertBannerA11yText: Driver<String?> = self.alertBannerText.map {
        $0?.replacingOccurrences(of: "shutoff", with: "shut-off")
    }
    
    private lazy var restoreServiceAlertText: Driver<String?> = self.currentAccountDetail.map {
        guard !($0.billingInfo.restorationAmount ?? 0 > 0 && $0.billingInfo.amtDpaReinst ?? 0 > 0) &&
            $0.isCutOutNonPay else {
                return nil
        }
        return NSLocalizedString("Your service is off due to non-payment.", comment: "")
    }
    
    private lazy var avoidShutoffAlertText: Driver<String?> = self.currentAccountDetail.map { accountDetail in
        guard let amountText = accountDetail.billingInfo.disconnectNoticeArrears?.currencyString,
            (accountDetail.billingInfo.disconnectNoticeArrears ?? 0 > 0 && accountDetail.billingInfo.isDisconnectNotice) else {
                    return nil
        }
        
        switch Environment.shared.opco {
        case .bge:
            guard let dateText = accountDetail.billingInfo.dueByDate?.mmDdYyyyString else { return nil }
            if accountDetail.billingInfo.disconnectNoticeArrears ?? 0 > 0 &&
                accountDetail.billingInfo.isDisconnectNotice {
                if let extensionDateText = accountDetail.billingInfo.turnOffNoticeExtendedDueDate?.mmDdYyyyString {
                    let localizedExtText = NSLocalizedString("A payment of %@ is due by %@", comment: "")
                    return String(format: localizedExtText, amountText, extensionDateText)
                } else if let turnOffDueDateText = accountDetail.billingInfo.turnOffNoticeDueDate?.mmDdYyyyString {
                    let localizedText = NSLocalizedString("Payment due to avoid service interruption is %@ due %@.", comment: "")
                    return String(format: localizedText, amountText, turnOffDueDateText)
                } else {
                    let localizedText = NSLocalizedString("Payment due to avoid service interruption is %@ due immediately.", comment: "")
                    return String(format: localizedText, amountText)
                }
            } else {
                let localizedText = NSLocalizedString("Payment due to avoid service interruption is %@ due %@.", comment: "")
                return String(format: localizedText, amountText, dateText)
            }
        case .comEd, .peco:
            let localizedText = NSLocalizedString("Payment due to avoid shutoff is %@ due immediately.", comment: "")
            return String(format: localizedText, amountText)
        }
    }
    
    private lazy var paymentFailedAlertText: Driver<String?> = self.currentAccountDetail.map { _ in
        //TODO: Implement this alert text
        let localizedText = NSLocalizedString("Your payment of %@ made with $@ failed processing. Please select an alternative payment account", comment: "")
        return nil
    }
    
    //MARK: - Total Amount Due
    
    private(set) lazy var totalAmountText: Driver<String> = self.currentAccountDetail.map {
        guard let netDueAmount = $0.billingInfo.netDueAmount else { return "--" }
        if Environment.shared.opco == .bge { // BGE should display the negative value if there is a credit
            return netDueAmount.currencyString ?? "--"
        }
        return max(netDueAmount, 0).currencyString ?? "--"
    }
    
    private(set) lazy var totalAmountDescriptionText: Driver<String> = self.currentAccountDetail.map {
        let billingInfo = $0.billingInfo
        if (billingInfo.pastDueAmount ?? 0) > 0 && billingInfo.pastDueAmount == billingInfo.netDueAmount { // Confluence Billing 11.10
            return NSLocalizedString("Total Amount Due Immediately", comment: "")
        } else if Environment.shared.opco == .bge {
            if let netDueAmount = billingInfo.netDueAmount {
                if netDueAmount < 0 {
                    return NSLocalizedString("No Amount Due - Credit Balance", comment: "")
                }
            }
        }
        
        let localizedText = NSLocalizedString("Total Amount Due By %@", comment: "")
        return String(format: localizedText, billingInfo.dueByDate?.mmDdYyyyString ?? "--")
    }
    
    //MARK: - Restore Service
    private(set) lazy var restoreServiceAmountText: Driver<String> = self.currentAccountDetail.map {
        $0.billingInfo.restorationAmount?.currencyString ?? "--"
    }
    
    //MARK: - Catch Up
    private(set) lazy var catchUpAmountText: Driver<String> = self.currentAccountDetail.map {
        $0.billingInfo.amtDpaReinst?.currencyString ?? "--"
    }
    
    private(set) lazy var catchUpDateText: Driver<String> = self.currentAccountDetail.map {
        let localizedText = NSLocalizedString("Due by %@", comment: "")
        return String(format: localizedText, $0.billingInfo.dueByDate?.mmDdYyyyString ?? "")
    }
    
    private(set) lazy var catchUpDisclaimerText: Driver<String> = self.currentAccountDetail.map {
        let localizedText = NSLocalizedString("You are entitled to one free reinstatement per plan. Any additional reinstatement will incur a %@ fee on your next bill.", comment: "")
        return String(format: localizedText, $0.billingInfo.atReinstateFee?.currencyString ?? "--")
    }
    
    //MARK: - Avoid Shutoff
    var avoidShutoffText: String {
        switch Environment.shared.opco {
        case .bge:
            return NSLocalizedString("Amount Due to Avoid Service Interruption", comment: "")
        case .comEd, .peco:
            return NSLocalizedString("Amount Due to Avoid Shutoff", comment: "")
        }
    }
    
    var avoidShutoffA11yText: String {
        return avoidShutoffText.replacingOccurrences(of: "Shutoff", with: "shut-off")
    }
    
    private(set) lazy var avoidShutoffAmountText: Driver<String> = self.currentAccountDetail.map {
        $0.billingInfo.disconnectNoticeArrears?.currencyString ?? "--"
    }
    
    private(set) lazy var avoidShutoffDueDateText: Driver<String> = self.currentAccountDetail.map { accountDetail in
        switch Environment.shared.opco {
        case .bge:
            let dueDate = accountDetail.billingInfo.turnOffNoticeExtendedDueDate ??
                accountDetail.billingInfo.turnOffNoticeDueDate ??
                accountDetail.billingInfo.dueByDate
            
            if accountDetail.billingInfo.disconnectNoticeArrears ?? 0 > 0 &&
                accountDetail.billingInfo.isDisconnectNotice &&
                dueDate == nil {
                return NSLocalizedString("Due Immediately", comment: "")
            }
            
            let localizedText = NSLocalizedString("Due by %@", comment: "")
            return String(format: localizedText, dueDate?.mmDdYyyyString ?? "--")
        case .comEd, .peco:
            return NSLocalizedString("Due Immediately", comment: "")
        }
    }
    
    //MARK: - Past Due
    private(set) lazy var pastDueAmountText: Driver<String> = self.currentAccountDetail.map {
        $0.billingInfo.pastDueAmount?.currencyString ?? "--"
    }
    
    //MARK: - Pending Payments
    private(set) lazy var pendingPaymentAmounts: Driver<[Double]> = self.recentPayments.map {
        // In a later release, we can use the whole pendingPayments array for BGE processing payments
        [$0.pendingPayments.first].compactMap { $0?.amount }
    }
    
    //MARK: - Remaining Balance Due
    var remainingBalanceDueText: String? {
        switch Environment.shared.opco {
        case .bge:
            return nil
        case .comEd, .peco:
            return NSLocalizedString("Remaining Balance Due", comment: "")
        }
    }
    
    private(set) lazy var remainingBalanceDueAmountText: Driver<String> = data
        .map { accountDetail, payments in
            if payments.pendingPayments.first?.amount == accountDetail.billingInfo.netDueAmount {
                return 0.currencyString ?? "--"
            } else {
                return accountDetail.billingInfo.remainingBalanceDue?.currencyString ?? "--"
            }
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var remainingBalanceDueDateText: Driver<String> = self.currentAccountDetail.map {
        guard let dateString = $0.billingInfo.dueByDate?.mmDdYyyyString else { return "--" }
        let localizedText = NSLocalizedString("Due by %@", comment: "")
        return String(format: localizedText, dateString)
    }
    
    //MARK: - Remaining Balance Past Due
    var remainingBalancePastDueText: String? {
        switch Environment.shared.opco {
        case .bge:
            return nil
        case .comEd, .peco:
            return NSLocalizedString("Remaining Past Balance Due ", comment: "")
        }
    }
    
    private(set) lazy var remainingBalancePastDueAmountText: Driver<String?> = self.currentAccountDetail.map {
        $0.billingInfo.pastDueRemaining?.currencyString ?? "--"
    }
    
    //MARK: - Bill Issued
    private(set) lazy var billIssuedAmountText: Driver<String?> = self.currentAccountDetail.map { _ in
        nil //TODO: Bill Issued
    }
    
    private(set) lazy var billIssuedDateText: Driver<String?> = self.currentAccountDetail.map { _ in
        nil //TODO: Bill Issued
    }
    
    //MARK: - Payment Received
    private(set) lazy var paymentReceivedAmountText: Driver<String> = self.currentAccountDetail.map {
        $0.billingInfo.lastPaymentAmount?.currencyString ?? "--"
    }
    
    private(set) lazy var paymentReceivedDateText: Driver<String?> = self.currentAccountDetail.map {
        guard let dateString = $0.billingInfo.lastPaymentDate?.mmDdYyyyString else { return nil }
        let localizedText = NSLocalizedString("Payment Date %@", comment: "")
        return String(format: localizedText, dateString)
    }
    
    //MARK: - Credit
    private(set) lazy var creditAmountText: Driver<String> = self.currentAccountDetail.map {
        guard let netDueAmount = $0.billingInfo.netDueAmount else { return "--" }
        return abs(netDueAmount).currencyString ?? "--"
    }
    
    //MARK: - Payment Status
    private(set) lazy var paymentStatusText: Driver<String?> = data
        .map { accountDetail, payments -> String? in
            if Environment.shared.opco == .bge && accountDetail.isBGEasy {
                return NSLocalizedString("You are enrolled in BGEasy", comment: "")
            } else if accountDetail.isAutoPay {
                return NSLocalizedString("You are enrolled in AutoPay", comment: "")
            } else if let pendingPaymentAmount = payments.pendingPayments.first?.amount, let amountString = pendingPaymentAmount.currencyString, pendingPaymentAmount > 0 {
                let localizedText: String
                switch Environment.shared.opco {
                case .bge:
                    localizedText = NSLocalizedString("You have a payment of %@ processing", comment: "")
                case .comEd, .peco:
                    localizedText = NSLocalizedString("You have a pending payment of %@", comment: "")
                }
                return String(format: localizedText, amountString)
            } else if let scheduledPaymentAmount = payments.scheduledPayment?.amount,
                let scheduledPaymentDate = payments.scheduledPayment?.date,
                let amountString = scheduledPaymentAmount.currencyString,
                scheduledPaymentAmount > 0 {
                return String(format: NSLocalizedString("Thank you for scheduling your %@ payment for %@", comment: ""), amountString, scheduledPaymentDate.mmDdYyyyString)
            } else if let lastPaymentAmount = accountDetail.billingInfo.lastPaymentAmount,
                let lastPaymentDate = accountDetail.billingInfo.lastPaymentDate,
                let amountString = lastPaymentAmount.currencyString,
                lastPaymentAmount > 0,
                let billDate = accountDetail.billingInfo.billDate,
                billDate < lastPaymentDate {
                return String(format: NSLocalizedString("Thank you for %@ payment on %@", comment: ""), amountString, lastPaymentDate.mmDdYyyyString)
            }
            return nil
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var makePaymentScheduledPaymentAlertInfo: Observable<(String?, String?, AccountDetail)> = data
        .map { accountDetail, payments in
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
            } else if let scheduledPaymentAmount = payments.scheduledPayment?.amount,
                let scheduledPaymentDate = payments.scheduledPayment?.date,
                let amountString = scheduledPaymentAmount.currencyString, scheduledPaymentAmount > 0 {
                let localizedTitle = NSLocalizedString("Existing Scheduled Payment", comment: "")
                return (localizedTitle, String(format: NSLocalizedString("You have a payment of %@ scheduled for %@. " +
                    "To avoid a duplicate payment, please review your payment activity before proceeding. Would " +
                    "you like to continue making an additional payment?", comment: ""),
                                               amountString, scheduledPaymentDate.mmDdYyyyString), accountDetail)
            }
            return (nil, nil, accountDetail)
    }
    
    private(set) lazy var makePaymentStatusTextTapRouting: Driver<MakePaymentStatusTextRouting> = data
        .map { accountDetail, payments in
            guard !accountDetail.isBGEasy else { return .nowhere }
            
            if accountDetail.isAutoPay {
                return .autoPay
            } else if payments.scheduledPayment?.amount ?? 0 > 0 &&
                payments.pendingPayments.first?.amount ?? 0 <= 0 {
                return .activity
            }
            return .nowhere
        }
        .asDriver(onErrorDriveWith: .empty())
    
    //MARK: - Bill Breakdown
    
    private(set) lazy var hasBillBreakdownData: Driver<Bool> = self.currentAccountDetail.map {
        let supplyCharges = $0.billingInfo.supplyCharges ?? 0
        let taxesAndFees = $0.billingInfo.taxesAndFees ?? 0
        let deliveryCharges = $0.billingInfo.deliveryCharges ?? 0
        let totalCharges = supplyCharges + taxesAndFees + deliveryCharges
        return totalCharges > 0
    }
    
    private(set) lazy var billBreakdownButtonTitle: Driver<String> = self.hasBillBreakdownData.map {
        if $0 {
            return NSLocalizedString("Bill Breakdown", comment: "")
        } else {
            return NSLocalizedString("View Usage", comment: "")
        }
    }
    
    //MARK: - Enrollment
    
    private(set) lazy var autoPayButtonText: Driver<NSAttributedString> = self.currentAccountDetail.map {
        if $0.isAutoPay || $0.isBGEasy {
            let text = NSLocalizedString("AutoPay", comment: "")
            let enrolledText = $0.isBGEasy ?
                NSLocalizedString("enrolled in BGEasy", comment: "") :
                NSLocalizedString("enrolled", comment: "")
            return BillViewModel.isEnrolledText(topText: text, bottomText: enrolledText)
        } else {
            return BillViewModel.canEnrollText(boldText: NSLocalizedString("AutoPay?", comment: ""))
        }
    }
    
    private(set) lazy var paperlessButtonText: Driver<NSAttributedString?> = self.currentAccountDetail
        .map { accountDetail in
            if !accountDetail.isResidential && (Environment.shared.opco == .comEd || Environment.shared.opco == .peco) {
                return BillViewModel.canEnrollText(boldText: NSLocalizedString("Paperless eBill?", comment: ""))
            }
            
            if accountDetail.isEBillEnrollment {
                return BillViewModel.isEnrolledText(topText: NSLocalizedString("Paperless eBill", comment: ""),
                                                    bottomText: NSLocalizedString("enrolled", comment: ""))
            }
            switch accountDetail.eBillEnrollStatus {
            case .canEnroll:
                return BillViewModel.canEnrollText(boldText: NSLocalizedString("Paperless eBill?", comment: ""))
            case .canUnenroll:
                return BillViewModel.isEnrolledText(topText: NSLocalizedString("Paperless eBill", comment: ""),
                                                    bottomText: NSLocalizedString("enrolled", comment: ""))
            case .ineligible, .finaled:
                return nil
            }
    }
    
    private(set) lazy var budgetButtonText: Driver<NSAttributedString> = self.currentAccountDetail.map {
        if $0.isBudgetBillEnrollment {
            return BillViewModel.isEnrolledText(topText: NSLocalizedString("Budget Billing", comment: ""),
                                                bottomText: NSLocalizedString("enrolled", comment: ""))
        } else {
            return BillViewModel.canEnrollText(boldText: NSLocalizedString("Budget Billing?", comment: ""))
        }
    }
    
	
	// MARK: - Conveniece functions
	
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




