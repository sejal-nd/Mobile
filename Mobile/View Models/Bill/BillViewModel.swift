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
    
    private var accountService: AccountService

    let fetchAccountDetail = PublishSubject<FetchingAccountState>()
    let currentAccountDetail = Variable<AccountDetail?>(nil)
    let isFetchingAccountDetail: Driver<Bool>
    let accountDetailErrorMessage: Driver<String>
    
    required init(accountService: AccountService) {
        self.accountService = accountService
        
        let fetchingAccountDetailTracker = ActivityTracker()
        isFetchingAccountDetail = fetchingAccountDetailTracker.asDriver()
		
		let sharedFetchAccountDetail = Observable.merge(fetchAccountDetail,
		                                                RxNotifications.shared.accountDetailUpdated
                                                            .mapTo(FetchingAccountState.switchAccount))
            .share()
		
		sharedFetchAccountDetail
			.filter { $0 != .refresh }
			.map { _ in nil }
			.bind(to: currentAccountDetail)
			.disposed(by: disposeBag)
        
        let fetchAccountDetailResult = sharedFetchAccountDetail
            .flatMapLatest { _ in
                accountService.fetchAccountDetail(account: AccountsStore.sharedInstance.currentAccount)
                    .retry(.exponentialDelayed(maxCount: 2, initial: 2.0, multiplier: 1.5))
                    .trackActivity(fetchingAccountDetailTracker)
                    .materialize()
            }
            .shareReplay(1)
            
        fetchAccountDetailResult.elements()
			.bind(to: currentAccountDetail)
			.disposed(by: disposeBag)
        
        accountDetailErrorMessage = fetchAccountDetailResult.errors()
            .map { 
                if let serviceError = $0 as? ServiceError {
                    if serviceError.serviceCode == ServiceErrorCode.FnNotFound.rawValue {
                        return NSLocalizedString(ServiceErrorCode.TcUnknown.rawValue, comment: "")
                    } else {
                        return serviceError.localizedDescription
                    }
                } else {
                    return $0.localizedDescription
                }
            }
            .asDriver(onErrorJustReturn: "")
    }
	
	func fetchAccountDetail(isRefresh: Bool) {
		fetchAccountDetail.onNext(isRefresh ? .refresh: .switchAccount)
    }
    
    private(set) lazy var currentAccountDetailUnwrapped: Driver<AccountDetail> = self.currentAccountDetail.asObservable()
            .unwrap()
            .asDriver(onErrorDriveWith: Driver.empty())
	
    private(set) lazy var isFetchingDifferentAccount: Driver<Bool> = self.currentAccountDetail.asDriver()
        .do(onNext: { _ in UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil) })
        .isNil()
	
	
    // MARK: - Show/Hide Views -
    
    private(set) lazy var shouldShowAlertBanner: Driver<Bool> = {
        let isCutOutNonPay = self.currentAccountDetail.asDriver().map { $0?.isCutOutNonPay ?? false }
        return Driver.zip(isCutOutNonPay, self.shouldShowRestoreService, self.shouldShowAvoidShutoff) {
            return ($0 && $1) || $2
        }
    }()
    
    private(set) lazy var shouldShowRestoreService: Driver<Bool> = self.currentAccountDetail.asDriver().map {
        return $0?.billingInfo.restorationAmount ?? 0 > 0 && $0?.isCutOutNonPay ?? false && Environment.sharedInstance.opco != .bge
    }
    
    private(set) lazy var shouldShowAvoidShutoff: Driver<Bool> = {
        let showAvoidShutoff = self.currentAccountDetail.asDriver().map { accountDetail -> Bool in
            guard let billingInfo = accountDetail?.billingInfo else { return false }
            return (billingInfo.disconnectNoticeArrears ?? 0) > 0 && billingInfo.isDisconnectNotice
        }
        return Driver.zip(self.shouldShowRestoreService, showAvoidShutoff) { !$0 && $1 }
    }()
    
    private(set) lazy var shouldShowCatchUpAmount: Driver<Bool> = {
        let showCatchup = self.currentAccountDetail.asDriver().map {
            $0?.billingInfo.amtDpaReinst ?? 0 > 0
        }
        return Driver.zip(self.shouldShowRestoreService, self.shouldShowAvoidShutoff, showCatchup) { !$0 && !$1 && $2 }
    }()
    
    private(set) lazy var shouldShowCatchUpDisclaimer: Driver<Bool> = Driver.zip(self.currentAccountDetail.asDriver(), self.shouldShowCatchUpAmount)
    {
        guard let accountDetail = $0 else { return false }
        return !accountDetail.isLowIncome && $1 && Environment.sharedInstance.opco == .comEd
    }
    
    private(set) lazy var shouldShowPastDue: Driver<Bool> = {
        let showPastDue = self.currentAccountDetail.asDriver().map { accountDetail -> Bool in
            guard let billingInfo = accountDetail?.billingInfo else { return false }
            return billingInfo.pastDueAmount ?? 0 > 0 && billingInfo.amtDpaReinst ?? 0 == 0
        }
        return Driver.zip(self.shouldShowAlertBanner, showPastDue) { !$0 && $1 }
    }()
    
    private(set) lazy var shouldShowTopContent: Driver<Bool> = self.isFetchingDifferentAccount.not()
    
    private(set) lazy var pendingPaymentAmountDueBoxesAlpha: Driver<CGFloat> = self.currentAccountDetail.asDriver().map {
        guard let pendingPaymentAmount = $0?.billingInfo.pendingPayments.first?.amount else { return 1.0 }
        return pendingPaymentAmount > 0 ? 0.5 : 1.0
    }
    
    private(set) lazy var shouldShowPendingPayment: Driver<Bool> = self.currentAccountDetail.asDriver().map {
        $0?.billingInfo.pendingPayments.first?.amount ?? 0 > 0
    }
    
    private(set) lazy var shouldShowRemainingBalanceDue: Driver<Bool> = self.currentAccountDetail.asDriver().map {
        return $0?.billingInfo.pendingPayments.first?.amount ?? 0 > 0 &&
            $0?.billingInfo.remainingBalanceDue ?? 0 > 0  &&
            Environment.sharedInstance.opco != .bge
    }
    
    private(set) lazy var shouldShowRemainingBalancePastDue: Driver<Bool> = {
        let showRemainingPastDue = self.currentAccountDetail.asDriver().map { accountDetail -> Bool in
            guard let billingInfo = accountDetail?.billingInfo else { return false }
            return billingInfo.pastDueRemaining ?? 0 > 0
        }
        return Driver.zip(showRemainingPastDue, self.shouldShowPastDue) { $0 && $1 && Environment.sharedInstance.opco != .bge }
    }()
    
    private(set) lazy var shouldShowBillIssued: Driver<Bool> = self.currentAccountDetail.asDriver().map {
        guard let billingInfo = $0?.billingInfo else { return false }
        //TODO: Bill Issued
        return false
    }
    
    private(set) lazy var shouldShowPaymentReceived: Driver<Bool> = self.currentAccountDetail.asDriver().map {
        guard let billingInfo = $0?.billingInfo else { return false }
        return billingInfo.lastPaymentAmount ?? 0 > 0 && billingInfo.netDueAmount ?? 0 == 0
    }
    
    private(set) lazy var shouldShowCredit: Driver<Bool> = self.currentAccountDetail.asDriver().map {
        guard let netDueAmount = $0?.billingInfo.netDueAmount else { return false }
        return netDueAmount < 0 && Environment.sharedInstance.opco == .bge
    }
    
    private(set) lazy var shouldShowAmountDueTooltip: Driver<Bool> = self.currentAccountDetailUnwrapped.map {
        $0.billingInfo.pastDueAmount ?? 0 <= 0 && Environment.sharedInstance.opco == .peco
    }
    
    private(set) lazy var shouldShowNeedHelpUnderstanding: Driver<Bool> = self.currentAccountDetail.asDriver().map {
        guard let accountDetail = $0 else { return false }
        guard let serviceType = accountDetail.serviceType else { return false }
        
        if !accountDetail.isResidential { // Residential customers only
            return false
        }
        
        // Must have valid serviceType
        if serviceType.uppercased() != "GAS" && serviceType.uppercased() != "ELECTRIC" && serviceType.uppercased() != "GAS/ELECTRIC" {
            return false
        }
        
        if let status = accountDetail.status, status.lowercased() == "finaled" { // No finaled accounts
            return false
        }

        return true
    }
    
    private(set) lazy var shouldEnableMakeAPaymentButton: Driver<Bool> = self.currentAccountDetail.asDriver().map {
        $0?.billingInfo.netDueAmount ?? 0 > 0 || Environment.sharedInstance.opco == .bge
    }
    
    private(set) lazy var shouldShowAutoPay: Driver<Bool> = self.currentAccountDetail.asDriver().map {
        guard let accountDetail = $0 else { return false }
        return accountDetail.isAutoPay || accountDetail.isBGEasy || accountDetail.isAutoPayEligible
    }
    
    private(set) lazy var shouldShowPaperless: Driver<Bool> = self.currentAccountDetail.asDriver().map {
        guard let accountDetail = $0 else { return false }
        if !accountDetail.isResidential && (Environment.sharedInstance.opco == .comEd || Environment.sharedInstance.opco == .peco) {
            return true
        }
        
        switch accountDetail.eBillEnrollStatus {
        case .canEnroll, .canUnenroll: return true
        case .ineligible, .finaled: return false
        }
    }
    
    private(set) lazy var shouldShowBudget: Driver<Bool> = self.currentAccountDetail.asDriver().map {
        guard let accountDetail = $0 else { return false }
        return accountDetail.isBudgetBillEligible ||
            accountDetail.isBudgetBillEnrollment ||
            Environment.sharedInstance.opco == .bge
    }
    
    
	// MARK: - View Content
    
    
    //MARK: - Banner Alert Text
    
    private(set) lazy var alertBannerText: Driver<String?> = Driver.combineLatest(self.restoreServiceAlertText,
                                                                     self.avoidShutoffAlertText,
                                                                     self.paymentFailedAlertText) { $0 ?? $1 ?? $2 }
    
    private(set) lazy var alertBannerA11yText: Driver<String?> = self.alertBannerText.map {
        $0?.replacingOccurrences(of: "shutoff", with: "shut-off")
    }
    
    private(set) lazy var restoreServiceAlertText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        guard let accountDetail = $0,
            !(accountDetail.billingInfo.restorationAmount ?? 0 > 0 && accountDetail.billingInfo.amtDpaReinst ?? 0 > 0) &&
                accountDetail.isCutOutNonPay else {
                    return nil
        }
        return NSLocalizedString("Your service is off due to non-payment.", comment: "")
    }
    
    private(set) lazy var avoidShutoffAlertText: Driver<String?> = Driver.zip(self.currentAccountDetail.asDriver(), self.restoreServiceAlertText)
    { accountDetail, restoreServiceAlertText in
        guard let billingInfo = accountDetail?.billingInfo,
            let amountText = billingInfo.disconnectNoticeArrears?.currencyString,
            restoreServiceAlertText == nil,
            (billingInfo.disconnectNoticeArrears ?? 0 > 0 && billingInfo.isDisconnectNotice) else {
                    return nil
        }
        
        switch Environment.sharedInstance.opco {
        case .bge:
            guard let dateText = billingInfo.dueByDate?.mmDdYyyyString else { return nil }
            if billingInfo.disconnectNoticeArrears ?? 0 > 0 &&
                billingInfo.isDisconnectNotice,
                let extensionDateText = billingInfo.turnOffNoticeExtendedDueDate?.mmDdYyyyString {
                let localizedExtText = NSLocalizedString("A payment of %@ is due by %@", comment: "")
                return String(format: localizedExtText, amountText, extensionDateText)
            } else {
                let localizedText = NSLocalizedString("Payment due to avoid service interruption is %@ due by %@.", comment: "")
                return String(format: localizedText, amountText, dateText)
            }
        case .comEd, .peco:
            let localizedText = NSLocalizedString("Payment due to avoid shutoff is %@ due immediately.", comment: "")
            return String(format: localizedText, amountText)
        }
    }
    
    private(set) lazy var paymentFailedAlertText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        guard let accountDetail = $0 else { return nil }
        //TODO: Implement this alert text
        let localizedText = NSLocalizedString("Your payment of %@ made with $@ failed processing. Please select an alternative payment account", comment: "")
        return nil
    }
    
    //MARK: - Total Amount Due
    
    private(set) lazy var totalAmountText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        guard let netDueAmount = $0?.billingInfo.netDueAmount else { return nil }
        if Environment.sharedInstance.opco == .bge { // BGE should display the negative value if there is a credit
            return netDueAmount.currencyString ?? "--"
        }
        return max(netDueAmount, 0).currencyString ?? "--"
    }
    
    private(set) lazy var totalAmountDescriptionText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        guard let billingInfo = $0?.billingInfo else { return nil }
        
        if (billingInfo.pastDueAmount ?? 0) > 0 && billingInfo.pastDueAmount == billingInfo.netDueAmount { // Confluence Billing 11.10
            return NSLocalizedString("Total Amount Due Immediately", comment: "")
        } else if Environment.sharedInstance.opco == .bge {
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
    private(set) lazy var restoreServiceAmountText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        $0?.billingInfo.restorationAmount?.currencyString ?? "--"
    }
    
    //MARK: - Catch Up
    private(set) lazy var catchUpAmountText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        $0?.billingInfo.amtDpaReinst?.currencyString ?? "--"
    }
    
    private(set) lazy var catchUpDateText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        let localizedText = NSLocalizedString("Due by %@", comment: "")
        return String(format: localizedText, $0?.billingInfo.dueByDate?.mmDdYyyyString ?? "")
    }
    
    private(set) lazy var catchUpDisclaimerText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        guard let billingInfo = $0?.billingInfo else { return nil }
        let localizedText = NSLocalizedString("You are entitled to one free reinstatement per plan. Any additional reinstatement will incur a %@ fee on your next bill.", comment: "")
        return String(format: localizedText, billingInfo.atReinstateFee?.currencyString ?? "--")
    }
    
    //MARK: - Avoid Shutoff
    var avoidShutoffText: String {
        switch Environment.sharedInstance.opco {
        case .bge:
            return NSLocalizedString("Amount Due to Avoid Service Interruption", comment: "")
        case .comEd, .peco:
            return NSLocalizedString("Amount Due to Avoid Shutoff", comment: "")
        }
    }
    
    var avoidShutoffA11yText: String {
        return avoidShutoffText.replacingOccurrences(of: "Shutoff", with: "shut-off")
    }
    
    private(set) lazy var avoidShutoffAmountText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        $0?.billingInfo.disconnectNoticeArrears?.currencyString ?? "--"
    }
    
    private(set) lazy var avoidShutoffDueDateText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        guard let billingInfo = $0?.billingInfo else { return nil }
        if Environment.sharedInstance.opco == .bge {
            let localizedText = NSLocalizedString("Due by %@", comment: "")
            let dueByDateString = billingInfo.dueByDate?.mmDdYyyyString ?? "--"
            return String(format: localizedText, dueByDateString)
        } else {
            return NSLocalizedString("Due Immediately", comment: "")
        }
    }
    
    //MARK: - Past Due
    private(set) lazy var pastDueAmountText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        $0?.billingInfo.pastDueAmount?.currencyString ?? "--"
    }
    
    //MARK: - Pending Payments
    private(set) lazy var pendingPaymentAmounts: Driver<[Double]> = self.currentAccountDetail.asDriver().map {
        // In a later release, we can use the whole pendingPayments array for BGE processing payments
        [$0?.billingInfo.pendingPayments.first].flatMap { $0?.amount }
    }
    
    //MARK: - Remaining Balance Due
    var remainingBalanceDueText: String? {
        switch Environment.sharedInstance.opco {
        case .bge:
            return nil
        case .comEd, .peco:
            return NSLocalizedString("Remaining Balance Due", comment: "")
        }
    }
    
    private(set) lazy var remainingBalanceDueAmountText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        if $0?.billingInfo.pendingPayments.first?.amount == $0?.billingInfo.netDueAmount {
            return 0.currencyString
        } else {
            return $0?.billingInfo.remainingBalanceDue?.currencyString ?? "--"
        }
    }
    
    private(set) lazy var remainingBalanceDueDateText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        guard let dateString = $0?.billingInfo.dueByDate?.mmDdYyyyString else { return nil }
        let localizedText = NSLocalizedString("Due by %@", comment: "")
        return String(format: localizedText, dateString)
    }
    
    //MARK: - Remaining Balance Past Due
    var remainingBalancePastDueText: String? {
        switch Environment.sharedInstance.opco {
        case .bge:
            return nil
        case .comEd, .peco:
            return NSLocalizedString("Remaining Past Balance Due ", comment: "")
        }
    }
    
    private(set) lazy var remainingBalancePastDueAmountText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        $0?.billingInfo.pastDueRemaining?.currencyString ?? "--"
    }
    
    //MARK: - Bill Issued
    private(set) lazy var billIssuedAmountText: Driver<String?> = self.currentAccountDetail.asDriver().map { _ in
        nil //TODO: Bill Issued
    }
    
    private(set) lazy var billIssuedDateText: Driver<String?> = self.currentAccountDetail.asDriver().map { _ in
        nil //TODO: Bill Issued
    }
    
    //MARK: - Payment Received
    private(set) lazy var paymentReceivedAmountText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        $0?.billingInfo.lastPaymentAmount?.currencyString ?? "--"
    }
    
    private(set) lazy var paymentReceivedDateText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        guard let dateString = $0?.billingInfo.lastPaymentDate?.mmDdYyyyString else { return nil }
        let localizedText = NSLocalizedString("Payment Date %@", comment: "")
        return String(format: localizedText, dateString)
    }
    
    //MARK: - Credit
    private(set) lazy var creditAmountText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        guard let netDueAmount = $0?.billingInfo.netDueAmount else { return "--" }
        return abs(netDueAmount).currencyString ?? "--"
    }
    
    //MARK: - Payment Status
    private(set) lazy var paymentStatusText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        guard let accountDetail = $0 else { return nil }
    
        if Environment.sharedInstance.opco == .bge && accountDetail.isBGEasy {
            return NSLocalizedString("You are enrolled in BGEasy", comment: "")
        } else if accountDetail.isAutoPay {
            return NSLocalizedString("You are enrolled in AutoPay", comment: "")
        } else if let pendingPaymentAmount = accountDetail.billingInfo.pendingPayments.first?.amount, let amountString = pendingPaymentAmount.currencyString, pendingPaymentAmount > 0 {
            let localizedText: String
            switch Environment.sharedInstance.opco {
            case .bge:
                localizedText = NSLocalizedString("You have a payment of %@ processing", comment: "")
            case .comEd, .peco:
                localizedText = NSLocalizedString("You have a pending payment of %@", comment: "")
            }
            return String(format: localizedText, amountString)
        } else if let scheduledPaymentAmount = accountDetail.billingInfo.scheduledPayment?.amount,
            let scheduledPaymentDate = accountDetail.billingInfo.scheduledPayment?.date,
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
    
    private(set) lazy var makePaymentScheduledPaymentAlertInfo: Observable<(String?, String?)> = self.currentAccountDetail.asObservable().map {
        guard let accountDetail = $0 else { return (nil, nil) }
        
        if Environment.sharedInstance.opco == .bge && accountDetail.isBGEasy {
            return (NSLocalizedString("Existing Automatic Payment", comment: ""), NSLocalizedString("You are already " +
                    "enrolled in our BGEasy direct debit payment option. BGEasy withdrawals process on the due date " +
                    "of your bill from the bank account you originally submitted. You may make a one-time payment " +
                    "now, but it may result in duplicate payment processing. Do you want to continue with a " +
                    "one-time payment?", comment: ""))
        } else if accountDetail.isAutoPay {
            return (NSLocalizedString("Existing Automatic Payment", comment: ""), NSLocalizedString("You currently " +
                    "have automatic payments set up. To avoid a duplicate payment, please review your payment " +
                    "activity before proceeding. Would you like to continue making an additional payment?\n\nNote: " +
                    "If you recently enrolled in AutoPay and you have not yet received a new bill, you will need " +
                    "to submit a payment for your current bill if you have not already done so.", comment: ""))
        } else if let scheduledPaymentAmount = accountDetail.billingInfo.scheduledPayment?.amount,
            let scheduledPaymentDate = accountDetail.billingInfo.scheduledPayment?.date,
            let amountString = scheduledPaymentAmount.currencyString, scheduledPaymentAmount > 0 {
            let localizedTitle = NSLocalizedString("Existing Scheduled Payment", comment: "")
            return (localizedTitle, String(format: NSLocalizedString("You have a payment of %@ scheduled for %@. " +
                    "To avoid a duplicate payment, please review your payment activity before proceeding. Would " +
                    "you like to continue making an additional payment?", comment: ""),
                    amountString, scheduledPaymentDate.mmDdYyyyString))
        }
        return (nil, nil)
    }
    
    private(set) lazy var makePaymentStatusTextTapRouting: Driver<MakePaymentStatusTextRouting> = self.currentAccountDetail.asDriver().map {
        guard let accountDetail = $0 else { return .nowhere }
        guard !accountDetail.isBGEasy else { return .nowhere }
        
        if accountDetail.isAutoPay {
            return .autoPay
        } else if accountDetail.billingInfo.scheduledPayment?.amount ?? 0 > 0.0 {
            return .activity
        }
        return .nowhere
    }
    
    //MARK: - Enrollment
    
    private(set) lazy var autoPayButtonText: Driver<NSAttributedString?> = self.currentAccountDetail.asDriver().map {
        guard let accountDetail = $0 else { return nil }
        if accountDetail.isAutoPay || accountDetail.isBGEasy {
            let text = NSLocalizedString("AutoPay", comment: "")
            let enrolledText = accountDetail.isBGEasy ?
                NSLocalizedString("enrolled in BGEasy", comment: "") :
                NSLocalizedString("enrolled", comment: "")
            return BillViewModel.isEnrolledText(topText: text, bottomText: enrolledText)
        } else {
            return BillViewModel.canEnrollText(boldText: NSLocalizedString("AutoPay?", comment: ""))
        }
    }
    
    private(set) lazy var paperlessButtonText: Driver<NSAttributedString?> = self.currentAccountDetail.asDriver().map {
        guard let accountDetail = $0 else { return nil }
        if !accountDetail.isResidential && (Environment.sharedInstance.opco == .comEd || Environment.sharedInstance.opco == .peco) {
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
    
    private(set) lazy var budgetButtonText: Driver<NSAttributedString?> = self.currentAccountDetail.asDriver().map {
        guard let accountDetail = $0 else { return nil }
        if accountDetail.isBudgetBillEnrollment {
            return BillViewModel.isEnrolledText(topText: NSLocalizedString("Budget Billing", comment: ""),
                                                bottomText: NSLocalizedString("enrolled", comment: ""))
        } else {
            return BillViewModel.canEnrollText(boldText: NSLocalizedString("Budget Billing?", comment: ""))
        }
    }
    
	
	// MARK: - Conveniece functions
	
    private static func isEnrolledText(topText: String, bottomText: String) -> NSAttributedString {
        let mutableText = NSMutableAttributedString(string: topText + "\n" + bottomText)
        let topTextRange = NSMakeRange(0, topText.characters.count)
        let bottomTextRange = NSMakeRange(topText.characters.count + 1, bottomText.characters.count)
        
        mutableText.addAttribute(NSFontAttributeName, value: OpenSans.bold.of(size: 16), range: topTextRange)
        mutableText.addAttribute(NSForegroundColorAttributeName, value: UIColor.blackText, range: topTextRange)
        mutableText.addAttribute(NSFontAttributeName, value: OpenSans.regular.of(size: 14), range: bottomTextRange)
        mutableText.addAttribute(NSForegroundColorAttributeName, value: UIColor.successGreenText, range: bottomTextRange)
        
        return mutableText
    }
    
    private static func canEnrollText(boldText: String) -> NSAttributedString {
        let text = NSLocalizedString("Would you like to enroll in ", comment: "")
        let mutableText = NSMutableAttributedString(string: text + boldText, attributes: [NSForegroundColorAttributeName: UIColor.blackText])
        
        mutableText.addAttribute(NSFontAttributeName, value: OpenSans.regular.of(size: 16), range: NSMakeRange(0, text.characters.count))
        mutableText.addAttribute(NSFontAttributeName, value: OpenSans.bold.of(size: 16), range: NSMakeRange(text.characters.count, boldText.characters.count))
        
        return mutableText
    }
    
}




