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
		
		let sharedFetchAccountDetail = fetchAccountDetail.share()
		
		sharedFetchAccountDetail
			.filter { $0 != .refresh }
			.map { _ in nil }
			.bind(to: currentAccountDetail)
			.addDisposableTo(disposeBag)
		
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
			.addDisposableTo(disposeBag)
        
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
    
    lazy var currentAccountDetailUnwrapped: Driver<AccountDetail> = self.currentAccountDetail.asObservable()
            .unwrap()
            .asDriver(onErrorDriveWith: Driver.empty())
	
	lazy var isFetchingDifferentAccount: Driver<Bool> = self.currentAccountDetail.asDriver().map { $0 == nil }
	
	
    // MARK: - Show/Hide Views -
    
    lazy var shouldShowAlertBanner: Driver<Bool> = {
        let isCutOutNonPay = self.currentAccountDetail.asDriver().map { $0?.isCutOutNonPay ?? false }
        return Driver.zip(isCutOutNonPay, self.shouldShowRestoreService, self.shouldShowAvoidShutoff) {
            return ($0 && $1) || $2
        }
    }()
    
    lazy var shouldShowRestoreService: Driver<Bool> = self.currentAccountDetail.asDriver().map {
        return $0?.billingInfo.restorationAmount ?? 0 > 0
    }
    
    lazy var shouldShowAvoidShutoff: Driver<Bool> = {
        let showAvoidShutoff = self.currentAccountDetail.asDriver().map { accountDetail -> Bool in
            guard let billingInfo = accountDetail?.billingInfo else { return false }
            return (billingInfo.disconnectNoticeArrears ?? 0) > 0 && billingInfo.isDisconnectNotice
        }
        return Driver.zip(self.shouldShowRestoreService, showAvoidShutoff) { !$0 && $1 }
    }()
    
    lazy var shouldShowCatchUpAmount: Driver<Bool> = {
        let showCatchup = self.currentAccountDetail.asDriver().map {
            $0?.billingInfo.amtDpaReinst ?? 0 > 0
        }
        return Driver.zip(self.shouldShowAvoidShutoff, showCatchup) { !$0 && $1 }
    }()
    
    lazy var shouldShowCatchUpDisclaimer: Driver<Bool> = self.shouldShowCatchUpAmount.map {
        $0 && Environment.sharedInstance.opco == .comEd
    }
    
    lazy var shouldShowPastDue: Driver<Bool> = {
        let showPastDue = self.currentAccountDetail.asDriver().map { accountDetail -> Bool in
            guard let billingInfo = accountDetail?.billingInfo else { return false }
            return billingInfo.pastDueAmount ?? 0 > 0 && billingInfo.amtDpaReinst ?? 0 == 0
        }
        return Driver.zip(self.shouldShowAlertBanner, showPastDue) { !$0 && $1 }
    }()
    
    lazy var pendingPaymentAmountDueBoxesAlpha: Driver<CGFloat> = self.currentAccountDetail.asDriver().map {
        guard let pendingPaymentAmount = $0?.billingInfo.pendingPaymentAmount else { return 1.0 }
        return pendingPaymentAmount > 0 ? 0.5 : 1.0
    }
    
    lazy var shouldShowPendingPayment: Driver<Bool> = self.currentAccountDetail.asDriver().map {
        //TODO: Account for web service change when this becomes an array
        $0?.billingInfo.pendingPaymentAmount ?? 0 > 0
    }
    
    lazy var shouldShowRemainingBalanceDue: Driver<Bool> = self.currentAccountDetail.asDriver().map {
        guard let billingInfo = $0?.billingInfo else { return false }
        return billingInfo.pendingPaymentAmount ?? 0 > 0 && billingInfo.remainingBalanceDue ?? 0 > 0
    }
    
    lazy var shouldShowRemainingBalancePastDue: Driver<Bool> = {
        let showRemainingPastDue = self.currentAccountDetail.asDriver().map { accountDetail -> Bool in
            guard let billingInfo = accountDetail?.billingInfo else { return false }
            return billingInfo.pastDueRemaining ?? 0 > 0
        }
        return Driver.zip(showRemainingPastDue, self.shouldShowPastDue) { $0 && $1 }
    }()
    
    lazy var shouldShowBillIssued: Driver<Bool> = self.currentAccountDetail.asDriver().map {
        guard let billingInfo = $0?.billingInfo else { return false }
        //TODO: Bill Issued
        return false
    }
    
    lazy var shouldShowPaymentReceived: Driver<Bool> = self.currentAccountDetail.asDriver().map {
        guard let billingInfo = $0?.billingInfo else { return false }
        return billingInfo.lastPaymentAmount ?? 0 > 0 && billingInfo.netDueAmount ?? 0 == 0
    }
    
    lazy var shouldShowCredit: Driver<Bool> = self.currentAccountDetail.asDriver().map {
        guard let netDueAmount = $0?.billingInfo.netDueAmount else { return false }
        return netDueAmount < 0 && Environment.sharedInstance.opco == .bge
    }
    
    let shouldShowAmountDueTooltip = Environment.sharedInstance.opco == .peco
    
    lazy var shouldShowNeedHelpUnderstanding: Driver<Bool> = self.currentAccountDetail.asDriver().map { _ in
        return false // Bill Analysis will be Release 2
//        guard let accountDetail = $0 else { return false }
//        return accountDetail.isResidential && !accountDetail.isAMICustomer
    }
    
    lazy var shouldEnableMakeAPaymentButton: Driver<Bool> = self.currentAccountDetail.asDriver().map {
        $0?.billingInfo.netDueAmount ?? 0 > 0 || Environment.sharedInstance.opco == .bge
    }
    
    lazy var shouldShowAutoPay: Driver<Bool> = self.currentAccountDetail.asDriver().map {
        guard let accountDetail = $0 else { return false }
        return accountDetail.isAutoPay || accountDetail.isBGEasy || accountDetail.isAutoPayEligible
    }
    
    lazy var shouldShowPaperless: Driver<Bool> = self.currentAccountDetail.asDriver().map {
        guard let accountDetail = $0 else { return false }
        if !accountDetail.isResidential && (Environment.sharedInstance.opco == .comEd || Environment.sharedInstance.opco == .peco) {
            return true
        }
        
        switch accountDetail.eBillEnrollStatus {
        case .canEnroll, .canUnenroll: return true
        case .ineligible, .finaled: return false
        }
    }
    
    lazy var shouldShowBudget: Driver<Bool> = self.currentAccountDetail.asDriver().map {
        guard let accountDetail = $0 else { return false }
        return accountDetail.isBudgetBillEligible ||
            accountDetail.isBudgetBillEnrollment ||
            Environment.sharedInstance.opco == .bge
    }
    
    
	// MARK: - View Content
    
    
    //MARK: - Banner Alert Text
    
    lazy var alertBannerText: Driver<String?> = Driver.combineLatest(self.restoreServiceAlertText,
                                                                     self.avoidShutoffAlertText,
                                                                     self.paymentFailedAlertText) { $0 ?? $1 ?? $2 }
    
    lazy var alertBannerA11yText: Driver<String?> = self.alertBannerText.map {
        $0?.replacingOccurrences(of: "shutoff", with: "shut-off")
    }
    
    lazy var restoreServiceAlertText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        guard let accountDetail = $0,
            !(accountDetail.billingInfo.restorationAmount ?? 0 > 0 && accountDetail.billingInfo.amtDpaReinst ?? 0 > 0) &&
                accountDetail.isCutOutNonPay else {
                    return nil
        }
        return NSLocalizedString("Your service is off due to non-payment.", comment: "")
    }
    
    lazy var avoidShutoffAlertText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        guard let billingInfo = $0?.billingInfo,
            let amountText = billingInfo.disconnectNoticeArrears?.currencyString,
            (!(billingInfo.restorationAmount ?? 0 > 0 && billingInfo.amtDpaReinst ?? 0 > 0) &&
                (billingInfo.disconnectNoticeArrears ?? 0) > 0 &&
                billingInfo.isDisconnectNotice) else {
                    return nil
        }
        
        switch Environment.sharedInstance.opco {
        case .bge:
            guard let dateText = billingInfo.dueByDate?.mmDdYyyyString else { return nil }
            let localizedText = NSLocalizedString("Payment due to avoid service interruption is %@ due by %@.", comment: "")
            return String(format: localizedText, amountText, dateText)
        case .comEd, .peco:
            let localizedText = NSLocalizedString("Payment due to avoid shutoff is %@ due immediately.", comment: "")
            return String(format: localizedText, amountText)
        }
    }
    
    lazy var paymentFailedAlertText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        guard let accountDetail = $0 else { return nil }
        //TODO: Implement this alert text
        let localizedText = NSLocalizedString("Your payment of %@ made with $@ failed processing. Please select an alternative payment account", comment: "")
        return nil
    }
    
    //MARK: - Total Amount Due
    
    lazy var totalAmountText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        guard let netDueAmount = $0?.billingInfo.netDueAmount else { return nil }
        if Environment.sharedInstance.opco == .bge { // BGE should display the negative value if there is a credit
            return netDueAmount.currencyString ?? "--"
        }
        return max(netDueAmount, 0).currencyString ?? "--"
    }
    
    lazy var totalAmountDescriptionText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        guard let billingInfo = $0?.billingInfo else { return nil }
        
        if Double(billingInfo.pastDueAmount!) > 0 && billingInfo.pastDueAmount == billingInfo.netDueAmount { // Confluence Billing 11.10
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
    lazy var restoreServiceAmountText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        $0?.billingInfo.restorationAmount?.currencyString ?? "--"
    }
    
    //MARK: - Catch Up
    lazy var catchUpAmountText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        $0?.billingInfo.amtDpaReinst?.currencyString ?? "--"
    }
    
    lazy var catchUpDateText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        let localizedText = NSLocalizedString("Due by %@", comment: "")
        return String(format: localizedText, $0?.billingInfo.dueByDate?.mmDdYyyyString ?? "")
    }
    
    lazy var catchUpDisclaimerText: Driver<String?> = self.currentAccountDetail.asDriver().map {
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
        return avoidShutoffText.replacingOccurrences(of: "shutoff", with: "shut-off")
    }
    
    lazy var avoidShutoffAmountText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        $0?.billingInfo.disconnectNoticeArrears?.currencyString ?? "--"
    }
    
    lazy var avoidShutoffDueDateText: Driver<String?> = self.currentAccountDetail.asDriver().map {
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
    lazy var pastDueAmountText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        $0?.billingInfo.pastDueAmount?.currencyString ?? "--"
    }
    
    //MARK: - Pending Payments
    lazy var pendingPaymentAmounts: Driver<[Double]> = self.currentAccountDetail.asDriver().map {
        [$0?.billingInfo.pendingPaymentAmount].flatMap { $0 }
    }
    
    //MARK: - Remaining Balance Due
    var remainingBalanceDueText: String {
        switch Environment.sharedInstance.opco {
        case .bge:
            return NSLocalizedString("Amount Remaining Due", comment: "")
        case .comEd, .peco:
            return NSLocalizedString("Remaining Balance Due", comment: "")
        }
    }
    
    lazy var remainingBalanceDueAmountText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        $0?.billingInfo.remainingBalanceDue?.currencyString ?? "--"
    }
    
    lazy var remainingBalanceDueDateText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        guard let dateString = $0?.billingInfo.dueByDate?.mmDdYyyyString else { return nil }
        let localizedText = NSLocalizedString("Due by %@", comment: "")
        return String(format: localizedText, dateString)
    }
    
    //MARK: - Remaining Balance Past Due
    var remainingBalancePastDueText: String {
        switch Environment.sharedInstance.opco {
        case .bge:
            return NSLocalizedString("Amount Remaining Past Due", comment: "")
        case .comEd, .peco:
            return NSLocalizedString("Remaining Past Balance Due ", comment: "")
        }
    }
    
    lazy var remainingBalancePastDueAmountText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        $0?.billingInfo.pastDueRemaining?.currencyString ?? "--"
    }
    
    //MARK: - Bill Issued
    lazy var billIssuedAmountText: Driver<String?> = self.currentAccountDetail.asDriver().map { _ in
        nil //TODO: Bill Issued
    }
    
    lazy var billIssuedDateText: Driver<String?> = self.currentAccountDetail.asDriver().map { _ in
        nil //TODO: Bill Issued
    }
    
    //MARK: - Payment Received
    lazy var paymentReceivedAmountText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        $0?.billingInfo.lastPaymentAmount?.currencyString ?? "--"
    }
    
    lazy var paymentReceivedDateText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        guard let dateString = $0?.billingInfo.lastPaymentDate?.mmDdYyyyString else { return nil }
        let localizedText = NSLocalizedString("Payment Date %@", comment: "")
        return String(format: localizedText, dateString)
    }
    
    //MARK: - Credit
    lazy var creditAmountText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        guard let netDueAmount = $0?.billingInfo.netDueAmount else { return "--" }
        return abs(netDueAmount).currencyString ?? "--"
    }
    
    //MARK: - Payment Status
    lazy var paymentStatusText: Driver<String?> = self.currentAccountDetail.asDriver().map {
        guard let accountDetail = $0 else { return nil }
    
        if Environment.sharedInstance.opco == .bge && accountDetail.isBGEasy {
            return NSLocalizedString("You are enrolled in BGEasy", comment: "")
        } else if accountDetail.isAutoPay {
            return NSLocalizedString("You are enrolled in AutoPay", comment: "")
        } else if let pendingPaymentAmount = accountDetail.billingInfo.pendingPaymentAmount, let amountString = pendingPaymentAmount.currencyString, pendingPaymentAmount > 0 {
            let localizedText: String
            switch Environment.sharedInstance.opco {
            case .bge:
                localizedText = NSLocalizedString("You have a payment of %@ processing", comment: "")
            case .comEd, .peco:
                localizedText = NSLocalizedString("You have a pending payment of %@", comment: "")
            }
            return String(format: localizedText, amountString)
        } else if let scheduledPaymentAmount = accountDetail.billingInfo.scheduledPaymentAmount, let scheduledPaymentDate = accountDetail.billingInfo.scheduledPaymentDate, let amountString = scheduledPaymentAmount.currencyString, scheduledPaymentAmount > 0 {
            return String(format: NSLocalizedString("Thank you for scheduling your %@ payment for %@", comment: ""), amountString, scheduledPaymentDate.mmDdYyyyString)
        } else if let lastPaymentAmount = accountDetail.billingInfo.lastPaymentAmount, let lastPaymentDate = accountDetail.billingInfo.lastPaymentDate, let amountString = lastPaymentAmount.currencyString, lastPaymentAmount > 0 {
            return String(format: NSLocalizedString("Thank you for %@ payment on %@", comment: ""), amountString, lastPaymentDate.mmDdYyyyString)
        }
        return nil
    }
    
    lazy var makePaymentScheduledPaymentAlertInfo: Observable<(String?, String?)> = self.currentAccountDetail.asObservable().map {
        guard let accountDetail = $0 else { return (nil, nil) }
        
        if Environment.sharedInstance.opco == .bge && accountDetail.isBGEasy {
            return (NSLocalizedString("Existing Automatic Payment", comment: ""), NSLocalizedString("You are already enrolled in our BGEasy direct debit payment option. BGEasy withdrawals process on the due date of your bill from the bank account you originally submitted. You may make a one-time payment now, but it may result in duplicate payment processing. Do you want to continue with a one-time payment?", comment: ""))
        } else if accountDetail.isAutoPay {
            if Environment.sharedInstance.opco == .bge {
                return (NSLocalizedString("Existing Automatic Payment", comment: ""), NSLocalizedString("You currently have automatic payments set up. To avoid a duplicate payment, please review your payment activity before proceeding. Would you like to continue making an additional payment?", comment: ""))
            } else {
                return (nil, nil)
            }
        } else if let scheduledPaymentAmount = accountDetail.billingInfo.scheduledPaymentAmount, let scheduledPaymentDate = accountDetail.billingInfo.scheduledPaymentDate, let amountString = scheduledPaymentAmount.currencyString, scheduledPaymentAmount > 0 {
            let localizedTitle = NSLocalizedString("Existing Scheduled Payment", comment: "")
            return (localizedTitle, String(format: NSLocalizedString("You have a payment of %@ scheduled for %@. To avoid a duplicate payment, please review your payment activity before proceeding. Would you like to continue making an additional payment?", comment: ""), amountString, scheduledPaymentDate.mmDdYyyyString))
        }
        return (nil, nil)
    }
    
    var makePaymentStatusTextTapRouting: Observable<MakePaymentStatusTextRouting> {
        return Observable.combineLatest(currentAccountDetail.asObservable(), self.shouldShowAutoPay.asObservable()).map {
            guard let accountDetail = $0 else { return .nowhere }
            if let scheduledPaymentAmount = accountDetail.billingInfo.scheduledPaymentAmount, scheduledPaymentAmount > 0.0 {
                if accountDetail.isAutoPay && $1 {
                    return .autoPay
                } else {
                    return .activity
                }
            }
            return .nowhere
        }
    }
    
    //MARK: - Enrollment
    
    lazy var autoPayButtonText: Driver<NSAttributedString?> = self.currentAccountDetail.asDriver().map {
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
    
    lazy var paperlessButtonText: Driver<NSAttributedString?> = self.currentAccountDetail.asDriver().map {
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
    
    lazy var budgetButtonText: Driver<NSAttributedString?> = self.currentAccountDetail.asDriver().map {
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




