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
    
    let fetchAccountDetail = PublishSubject<FetchingAccountState>()
    let refreshTracker = ActivityTracker()
    let switchAccountsTracker = ActivityTracker()
    let usageBillImpactLoading = PublishSubject<Bool>()
    var usageBillImpactInnerLoading = false
    
    let electricGasSelectedSegmentIndex = BehaviorRelay(value: 0)
    let compareToLastYear = BehaviorRelay(value: false)
    
    let mobileAssistanceURL = BehaviorRelay(value: "")
    var mobileAssistanceType = MobileAssistanceURL(rawValue: "none")
    
    let isBgeDdeEligible = BehaviorRelay<Bool?>(value: nil)
    let isBgeDpaEligible = BehaviorRelay<Bool?>(value: nil)
    
    let dueDateExtensionDetails = BehaviorRelay<DueDateElibility?>(value: nil)
    var paymentArrangementDetails = BehaviorRelay<PaymentArrangement?>(value: nil)
    
    let ddeDpafeatureFlag =  Configuration.shared.opco == .comEd ||  Configuration.shared.opco == .peco ? true : false
    
    private func tracker(forState state: FetchingAccountState) -> ActivityTracker {
        switch state {
        case .refresh: return refreshTracker
        case .switchAccount: return switchAccountsTracker
        }
    }
    
    private lazy var fetchTrigger = Observable
        .merge(fetchAccountDetail,
               RxNotifications.shared.accountDetailUpdated.mapTo(FetchingAccountState.switchAccount),
               RxNotifications.shared.recentPaymentsUpdated.mapTo(FetchingAccountState.switchAccount))
    
    // Awful maintenance mode check
    private lazy var maintenanceModeEvents: Observable<Event<MaintenanceMode>> = fetchTrigger
        .toAsyncRequest(activityTracker: { [weak self] in self?.tracker(forState: $0) },
                        requestSelector: { [unowned self] _ in AnonymousService.rx.getMaintenanceMode(shouldPostNotification: true) })
    
    private(set) lazy var dataEvents: Observable<Event<(AccountDetail, PaymentItem?)>> = maintenanceModeEvents
        .filter { !($0.element?.all ?? false) && !($0.element?.bill ?? false) }
        .withLatestFrom(self.fetchTrigger)
        .toAsyncRequest(activityTracker: { [weak self] in
            self?.tracker(forState: $0)
        }, requestSelector: { [weak self] _ -> Observable<(AccountDetail, PaymentItem?)> in
            guard let self = self, AccountsStore.shared.currentIndex != nil else { return .empty() }
            let account = AccountsStore.shared.currentAccount
            let accountDetail = AccountService.rx.fetchAccountDetails(accountNumber: account.accountNumber, budgetBilling: true)
            let scheduledPayment = AccountService.rx.fetchScheduledPayments(accountNumber: account.accountNumber).map { $0.last }
                .do(onError: { _ in
                    FirebaseUtility.logEvent(.bill(parameters: [.bill_not_available]))
                })
            return Observable.zip(accountDetail, scheduledPayment)
        })
        .do(onNext: { _ in UIAccessibility.post(notification: .screenChanged, argument: nil) })
    
    private lazy var usageBillImpactEvents: Observable<Event<CompareBillResult>> = Observable
        .combineLatest(dataEvents.elements().map { $0.0 }.filter { $0.isEligibleForUsageData },
                       compareToLastYear.asObservable(),
                       electricGasSelectedSegmentIndex.asObservable())
        .toAsyncRequest { [weak self] (accountDetail, compareToLastYear, electricGasIndex) in
            guard let self = self else { return .empty() }
            if !self.usageBillImpactInnerLoading {
                self.usageBillImpactLoading.onNext(true)
            }
            let isGas = self.isGas(accountDetail: accountDetail, electricGasSelectedIndex: electricGasIndex)
            return UsageService.rx.compareBill(accountNumber: accountDetail.accountNumber,
                                                         premiseNumber: accountDetail.premiseNumber!,
                                                         yearAgo: compareToLastYear,
                                                         gas: isGas,
                                                         useCache: false)
        }
    
    private(set) lazy var fetchBGEDdeDpaEligibility: Driver<Bool> = self.currentAccountDetail.map {
        if Configuration.shared.opco == .bge || self.ddeDpafeatureFlag  {
            // Fetch BGE DDE
            AccountService.fetchDDE  { [weak self] result in
                switch result {
                case .success(let resultObject):
                    self?.isBgeDdeEligible.accept( resultObject.isPaymentExtensionEligible ?? false)
                    self?.dueDateExtensionDetails.accept(resultObject)
                case .failure:
                    self?.isBgeDdeEligible.accept(false)
                }
            }
            
            // Fetch BGE DPA
            let customerNumber = $0.customerNumber
            let premiseNumber = $0.premiseNumber ?? ""
            let paymentAmount = (String(describing: $0.billingInfo.netDueAmount ?? 0.0))
            AccountService.fetchDPA(customerNumber: customerNumber,
                                    premiseNumber: premiseNumber,
                                    paymentAmount: paymentAmount)         { [weak self] result in
                switch result {
                case .success(let paymentEnhancement):
                    self?.isBgeDpaEligible.accept(paymentEnhancement.customerInfo?.paEligibility == "true" ? true : false)
                    self?.paymentArrangementDetails.accept(paymentEnhancement)
                case .failure:
                    self?.isBgeDpaEligible.accept(false)
                }
            }
        } else {
            self.isBgeDpaEligible.accept(false)
            self.isBgeDdeEligible.accept(false)
        }
        return false
    }
    
    
    private(set) lazy var accountDetailError: Driver<NetworkingError?> = dataEvents.errors()
        .map { $0 as? NetworkingError }
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
    
    private(set) lazy var showUsageBillImpactEmptyState: Driver<Void> = dataEvents.elements()
        .map { $0.0 }
        .filter {
            return !$0.isEligibleForUsageData && $0.isResidential && !($0.status?.lowercased() == "inactive")
        }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
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
    

    private(set) lazy var currentBillComparison: Driver<CompareBillResult> = usageBillImpactEvents
        .elements()
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var scheduledPayment: Driver<PaymentItem?> = data
        .map { $0.1 }
        .asDriver(onErrorDriveWith: Driver.empty())
	
    // MARK: - Show/Hide Views
    
    private(set) lazy var showMaintenanceMode: Driver<Void> = maintenanceModeEvents.elements()
        .filter { $0.bill }
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
        return netDueAmount < 0 && (Configuration.shared.opco == .bge || Configuration.shared.opco.isPHI)
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
    
    #warning("A short term fix for PHI customers. For the time being Hidden Remaining Balance Option for March, 2021 release will have to remove check for PHI after Long Term Solution is discussed with SAP")
    private(set) lazy var showRemainingBalanceDue: Driver<Bool> = currentAccountDetail.map {
        $0.billingInfo.pendingPaymentsTotal > 0 && $0.billingInfo.remainingBalanceDue > 0 && !Configuration.shared.opco.isPHI
    }
    
    private(set) lazy var showPaymentReceived: Driver<Bool> = currentAccountDetail.map {
        $0.billingInfo.lastPaymentAmount > 0 && $0.billingInfo.netDueAmount ?? 0 == 0
    }
    
    let showAmountDueTooltip = Configuration.shared.opco == .peco
    
    private(set) lazy var showMakeAPaymentButton: Driver<Bool> = currentAccountDetail.map {
        $0.billingInfo.netDueAmount > 0 || Configuration.shared.opco == .bge || Configuration.shared.opco.isPHI
    }
    
    private(set) lazy var showBillPaidFakeButton: Driver<Bool> =
        Driver.combineLatest(self.showMakeAPaymentButton, self.showBillNotReady) { !$0 && !$1 }
    
    private(set) lazy var showPaymentStatusText = paymentStatusText.isNil().not()
    
    private(set) lazy var showAutoPay: Driver<Bool> = currentAccountDetail.map {
        $0.isAutoPay || $0.isBGEasy || $0.isAutoPayEligible
    }
    
    private(set) lazy var showPaperless: Driver<Bool> = currentAccountDetail.map {
        // ComEd/PECO commercial customers should always see the button
        if !$0.isResidential && Configuration.shared.opco != .bge {
            return true
        }
        
        switch $0.eBillEnrollStatus {
        case .canEnroll, .canUnenroll: return true
        case .ineligible, .finaled: return false
        }
    }
    
    private(set) lazy var showBudget: Driver<Bool> = currentAccountDetail.map {
        return $0.isBudgetBillEligible ||
            $0.isBudgetBill ||
            Configuration.shared.opco == .bge
    }
    
    //MARK: - Banner Alert Text
    
    private(set) lazy var alertBannerText: Driver<String?> = currentAccountDetail.map { accountDetail in
        let billingInfo = accountDetail.billingInfo
        let status = Configuration.shared.opco.isPHI ? "is inactive" : "has been finaled"
        
        // Finaled
        if billingInfo.pastDueAmount > 0 && accountDetail.isFinaled {
            if billingInfo.pastDueAmount == billingInfo.netDueAmount {
                // Since the past due amount and the net due amount are both equal, it makes sense not to show the `pastDueAmount` and also its implemented similarly in Android as well
                return NSLocalizedString("The total amount must be paid immediately. Your account \(status) and is no longer connected to your premise address.", comment: "")
            } else {
                if billingInfo.pastDueAmount > .zero && accountDetail.isFinaled {
                    return String.localizedStringWithFormat("%@ is past due and must be paid immediately. Your account \(status) and is no longer connected to your premise address.", billingInfo.pastDueAmount?.currencyString ?? "--")
                }
            }
        }
        
        // Restore Service
        if let restorationAmount = accountDetail.billingInfo.restorationAmount,
            restorationAmount > 0 &&
                accountDetail.isCutOutNonPay &&
                Configuration.shared.opco != .bge {
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
            Configuration.shared.opco != .bge && amtDpaReinst > 0 {
            let days = dueByDate.interval(ofComponent: .day, fromDate: Calendar.opCo.startOfDay(for: .now))
            let amountString = amtDpaReinst.currencyString
            
            let string: String
            switch (days > 0 && Configuration.shared.opco != .peco, billingInfo.amtDpaReinst == billingInfo.netDueAmount) {
            case (true, true):
                let format = "The total amount must be paid by %@ to catch up on your DPA."
                return String.localizedStringWithFormat(format, dueByDate.mmDdYyyyString)
            case (true, false):
                let format = "%@ of the total must be paid by %@ to catch up on your DPA."
                return String.localizedStringWithFormat(format, amountString, dueByDate.mmDdYyyyString)
            case (false, true):
                return NSLocalizedString("The total amount must be paid immediately to catch up on your DPA.", comment: "")
            case (false, false):
                let format = "%@ of the total is due immediately to catch up on your DPA."
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
        
        switch Configuration.shared.opco {
        case .ace, .bge, .delmarva, .pepco: // For credit scenario we want to show the positive number
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
            if Configuration.shared.opco != .bge && billingInfo.amtDpaReinst > 0 &&
                billingInfo.amtDpaReinst == billingInfo.pastDueAmount {
                return NSLocalizedString("Catch Up on Agreement Amount", comment: "")
            } else {
                return NSLocalizedString("Past Due Amount", comment: "")
            }
    }
    
    private(set) lazy var pastDueAmountText: Driver<String> = currentAccountDetail.map {
        if Configuration.shared.opco != .bge && $0.billingInfo.amtDpaReinst > 0 &&
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
                Configuration.shared.opco != .bge &&
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
        switch Configuration.shared.opco {
        case .bge:
            return NSLocalizedString("Payments Processing", comment: "")
        case .comEd, .peco, .pepco, .ace, .delmarva:
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
    private(set) lazy var showCatchUpDisclaimer: Driver<Bool> = Driver.combineLatest(showBgeDdeDpaEligibility.asDriver(), enrollmentStatus.asDriver()) {(showBgeDdeDpaEligibility, enrollmentStatus) in
        return showBgeDdeDpaEligibility && !(enrollmentStatus ?? "").isEmpty
    }
    
    private(set) lazy var catchUpDisclaimerText: Driver<String> = currentAccountDetail.map {
        let localizedText = NSLocalizedString("You are entitled to one free reinstatement per plan. Any additional reinstatement will incur a %@ fee on your next bill.", comment: "")
        return String(format: localizedText, $0.billingInfo.atReinstateFee?.currencyString ?? "--")
    }
    
    //MARK: - Payment Status
    private(set) lazy var paymentStatusText: Driver<String?> = data
        .map { accountDetail, scheduledPayment in
            if Configuration.shared.opco == .bge && accountDetail.isBGEasy {
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
                return String(format: NSLocalizedString("Thank you for your %@ payment on %@", comment: ""), lastPaymentAmount.currencyString, lastPaymentDate.mmDdYyyyString)
            }
            return nil
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var makePaymentScheduledPaymentAlertInfo: Observable<(String?, String?, AccountDetail)> = data
        .map { accountDetail, scheduledPayment in
            if Configuration.shared.opco == .bge && accountDetail.isBGEasy {
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
            guard let reference = $0.referenceBill, let compared = $0.comparedBill else {
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
            
            guard let reference = billComparison.referenceBill, let compared = billComparison.comparedBill else {
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
            
            guard let reference = billComparison.referenceBill, let compared = billComparison.comparedBill else {
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
    
    private(set) lazy var noPreviousData: Driver<Bool> = currentBillComparison.map { $0.comparedBill == nil }
    
    //MARK: - Enrollment
    
    private(set) lazy var showPaperlessEnrolledView: Driver<Bool> = currentAccountDetail.map {
        // Always hide for ComEd/PECO commercial customers
        var showPaperlessEnrolledView = false
        if Configuration.shared.opco.isPHI {
            showPaperlessEnrolledView = $0.eBillEnrollStatus == .canUnenroll
        } else {
            if !$0.isResidential && Configuration.shared.opco != .bge {
                showPaperlessEnrolledView = false
            } else {
                showPaperlessEnrolledView = $0.eBillEnrollStatus == .canUnenroll
            }
        }
        return showPaperlessEnrolledView
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
        return $0.isBudgetBill
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
        return URL(string: Configuration.shared.myAccountUrl)!
    }
    
    // MARK: - Helpers
    
    // If a gas only account, return true, if an electric only account, returns false, if both gas/electric, returns selected segemented control
    private func isGas(accountDetail: AccountDetail, electricGasSelectedIndex: Int) -> Bool {
        if accountDetail.serviceType?.uppercased() == "GAS" { // If account is gas only
            return true
        } else if Configuration.shared.opco != .comEd && accountDetail.serviceType?.uppercased() == "GAS/ELECTRIC" {
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
    
    private(set) lazy var showBgeDdeDpaEligibility: Driver<Bool> =
        Driver.combineLatest(self.isBgeDdeEligible.asDriver(),
                             self.isBgeDpaEligible.asDriver())
            {
            ($0 != nil) && ($1 != nil)
            
        }
    private(set) lazy var showAssistanceCTA: Driver<Bool> =
        Driver.combineLatest(self.enrollmentStatus.asDriver(),
                             showBgeDdeDpaEligibility.asDriver())
            {
            ($0 == "") && $1
            
        }
    
    private(set) lazy var showDDEExtendedView: Driver<Bool> =
        Driver.combineLatest(self.enrollmentStatus.asDriver(),
                             showBgeDdeDpaEligibility.asDriver(), currentAccountDetail)
            {
            guard let dueDateString = $0 else {return false}
            return (dueDateString.hasPrefix("You're enrolled in a Due Date Extension"))  && $1 && $2.billingInfo.pastDueAmount > 0
        }
    // MARK: - Enrollment Status
    private(set) lazy var enrollmentStatus: Driver<String?> = Driver.combineLatest(currentAccountDetail, showBgeDdeDpaEligibility.asDriver(), paymentArrangementDetails.asDriver(), dueDateExtensionDetails.asDriver()) { (accountDetail, bgeDdeDpaEligibilityChecked, paymentArrangementDetails, dueDateExtensionDetails) in
        if self.ddeDpafeatureFlag {
            if accountDetail.billingInfo.isDpaEnrolled == "true" {
                if paymentArrangementDetails?.pAData?.first?.numberOfInstallments == paymentArrangementDetails?.pAData?.first?.noOfInstallmentsLeft {
                    return "Your request to enroll in a payment arrangement has been accepted. For further details log into your My Account."
                } else if paymentArrangementDetails?.pAData?.first?.numberOfInstallments != paymentArrangementDetails?.pAData?.first?.noOfInstallmentsLeft {
                    guard  let remainingPaymentAmount = paymentArrangementDetails?.pAData?.first?.remainingPaymentAmount,
                           let monthlyInstallment = paymentArrangementDetails?.pAData?.first?.monthlyInstallment,
                           let noOfInstallmentsLeft = paymentArrangementDetails?.pAData?.first?.noOfInstallmentsLeft,
                           let numberOfInstallments = paymentArrangementDetails?.pAData?.first?.numberOfInstallments else {
                        return ""
                    }
                    return " You’re enrolled in a payment arrangement. Your $\(monthlyInstallment) monthly installment is included in the current bill. You have \(noOfInstallmentsLeft) installments, for a total of $\(remainingPaymentAmount), left on your arrangement."
                }
            } else if !accountDetail.isDueDateExtensionEligible &&
                        dueDateExtensionDetails?.extendedDueDate != nil &&
                        dueDateExtensionDetails?.extensionDueAmt != nil {
                guard let extendedDueDate = dueDateExtensionDetails?.extendedDueDate,
                      let extensionDueAmt = dueDateExtensionDetails?.extensionDueAmt else {return nil}
                if Date() > dueDateExtensionDetails?.extendedDueDate {
                    return "You're enrolled in a Due Date Extension. You have until \(String(describing: extendedDueDate.mmDdYyyyString)) to pay your extended bill of $\(extensionDueAmt)."
                } else {
                    return "You're enrolled in a Due Date Extension. You have until \(String(describing: extendedDueDate.mmDdYyyyString)) to pay your extended bill of $\(extensionDueAmt)."
                }
            }
        }
        return ""
    }
    
    // MARK: - Assistance View States
    private(set) lazy var paymentAssistanceValues: Driver<(title: String, description: String, ctaType: String, ctaURL: String)?> =
        Driver.combineLatest(currentAccountDetail, showBgeDdeDpaEligibility.asDriver())
        { (accountDetail, bgeDdeDpaEligibilityChecked) in
            let isAccountTypeEligible =  accountDetail.isResidential || accountDetail.isSmallCommercialCustomer
            if isAccountTypeEligible &&
                FeatureFlagUtility.shared.bool(forKey: .paymentProgramAds) {
                // BGE has different conditions for DDE, DPA and CTA3
                if Configuration.shared.opco == .bge {
                    if bgeDdeDpaEligibilityChecked {
                        let bgeCTADetails =  self.showBGEAssitanceCTA(accountDetail: accountDetail)
                        return bgeCTADetails
                    } else {
                        return ("","","","")
                        
                    }
                }
                
                if accountDetail.isDueDateExtensionEligible &&
                    accountDetail.billingInfo.pastDueAmount > 0 {
        
                    self.mobileAssistanceURL.accept(MobileAssistanceURL.getMobileAssistnceURL(assistanceType: .dde))
                    self.mobileAssistanceType = MobileAssistanceURL.dde
                    if Configuration.shared.opco.isPHI {
                        return (title: "You’re eligible for a One-Time Payment Delay",
                                description: "Having trouble keeping up with your \(Configuration.shared.opco.displayString) bill? We’re here to help. Extend your upcoming bill due date by up to 30 calendar days with a One-Time Payment Delay.",
                                ctaType: "Request One-Time Payment Delay",
                                ctaURL: "")
                    } else {
                        return (title: "You’re eligible for a Due Date Extension",
                                description: "Having trouble keeping up with your \(Configuration.shared.opco.displayString) bill? We’re here to help. Extend your upcoming bill due date by up to 21 calendar days with a Due Date Extension.",
                                ctaType: "Request Due Date Extension",
                                ctaURL: "")
                    }
                    
                } else if !accountDetail.isDueDateExtensionEligible &&
                            accountDetail.billingInfo.amtDpaReinst > 0 &&
                            accountDetail.is_dpa_reinstate_eligible {
                    self.mobileAssistanceURL.accept(MobileAssistanceURL.getMobileAssistnceURL(assistanceType: .dpaReintate))
                    self.mobileAssistanceType = MobileAssistanceURL.dpaReintate
                    
                    var lowIncomeTitle = "You can reinstate your Payment Arrangement at no additional cost."
                    let reinstateFee = accountDetail.billingInfo.atReinstateFee > 0 ? accountDetail.billingInfo.atReinstateFee : 14.24
                    var nonLowIncomeTitle = "You are entitled to one free reinstatement per plan. Any additional reinstatement will incur a $14.24 fee on your next bill."
                    var title =  Configuration.shared.opco == .comEd && accountDetail.isLowIncome ? lowIncomeTitle : nonLowIncomeTitle
                    return (title: title,
                            description: "",
                            ctaType: "Reinstate Payment Arrangement",
                            ctaURL: "")
                } else if !accountDetail.isDueDateExtensionEligible &&
                            accountDetail.billingInfo.pastDueAmount > 0 &&
                            accountDetail.is_dpa_eligible {
                    self.mobileAssistanceURL.accept(MobileAssistanceURL.getMobileAssistnceURL(assistanceType: .dpa))
                    self.mobileAssistanceType = MobileAssistanceURL.dpa
                    if Configuration.shared.opco.isPHI {
                        return (title: "You’re eligible for a Payment Arrangement.",
                                description: "Having trouble keeping up with your \(Configuration.shared.opco.displayString) bill? We’re here to help. You can make monthly installments to bring your account up to date.",
                                ctaType: "Learn More",
                                ctaURL: "")
                    } else {
                        return (title: "You’re eligible for a Deferred Payment Arrangement.",
                                description: "Having trouble keeping up with your \(Configuration.shared.opco.displayString) bill? We’re here to help. You can make monthly installments to bring your account up to date.",
                                ctaType: "Learn More",
                                ctaURL: "")
                    }
                } else if !accountDetail.isDueDateExtensionEligible &&
                            accountDetail.billingInfo.pastDueAmount > 0 &&
                            !accountDetail.is_dpa_eligible  &&
                            !accountDetail.is_dpa_reinstate_eligible {
                    self.mobileAssistanceURL.accept(MobileAssistanceURL.getMobileAssistnceURL(assistanceType: .none, stateJurisdiction: accountDetail.state))
                    self.mobileAssistanceType = MobileAssistanceURL.none
                    return (title: "Having trouble keeping up with your \(Configuration.shared.opco.displayString) bill?",
                            description: "Check out the many Assistance Programs \(Configuration.shared.opco.displayString) offers to find one that’s right for you.",
                            ctaType: "Learn More",
                            ctaURL: "")
                }
            }
            return nil
    }
    
    
    private func showBGEAssitanceCTA(accountDetail: AccountDetail) -> (title: String, description: String, ctaType: String, ctaURL: String) {
        guard let dueDate = accountDetail.billingInfo.dueByDate else {
            return ("","","","")
        }
        let netDueAmount = accountDetail.billingInfo.netDueAmount
        if accountDetail.billingInfo.currentDueAmount >= 0 &&
            isBgeDdeEligible.value ?? false &&
            accountDetail.isAutoPay == false &&
            Date() >= Calendar.current.date(byAdding: .day, value: -4, to: dueDate) {
            self.mobileAssistanceURL.accept(MobileAssistanceURL.getMobileAssistnceURL(assistanceType: .dde))
            self.mobileAssistanceType = MobileAssistanceURL.dde
            return (title: "You’re eligible for a Due Date Extension",
                    description: "Having trouble keeping up with your \(Configuration.shared.opco.displayString) bill? We’re here to help. Extend your upcoming bill due date by up to 30 calendar days with a Due Date Extension.",
                    ctaType: "Request Due Date Extension",
                    ctaURL: "")
        } else if accountDetail.billingInfo.pastDueAmount > 0 &&
                    netDueAmount >= 80 && netDueAmount <= 5000 &&
                    isBgeDpaEligible.value ?? false {
            self.mobileAssistanceURL.accept(MobileAssistanceURL.getMobileAssistnceURL(assistanceType: .dpa))
            self.mobileAssistanceType = MobileAssistanceURL.dpa
            return (title: "You’re eligible for a Deferred Payment Arrangement.",
                    description: "Having trouble keeping up with your \(Configuration.shared.opco.displayString) bill? We’re here to help. You can make monthly installments to bring your account up to date.",
                    ctaType: "Learn More",
                    ctaURL: "")
            
        } else if accountDetail.billingInfo.pastDueAmount > 0  {
            self.mobileAssistanceURL.accept(MobileAssistanceURL.getMobileAssistnceURL(assistanceType: .none, stateJurisdiction: accountDetail.state))
            self.mobileAssistanceType = MobileAssistanceURL.none
            return (title: "Having trouble keeping up with your \(Configuration.shared.opco.displayString) bill?",
                    description: "Check out the many Assistance Programs \(Configuration.shared.opco.displayString) offers to find one that’s right for you.",
                    ctaType: "Learn More",
                    ctaURL: "")
        }
        return ("","","","")
    }
    
    enum MobileAssistanceURL: String {
        case dde
        case dpa
        case dpaReintate
        case none
        
        private static func getBaseURLmobileAssistance(assistanceType: MobileAssistanceURL) -> String {
            let projectTierRawValue = UserDefaults.standard.string(forKey: "selectedProjectTier") ?? "Stage"
            let projectTier = ProjectTier(rawValue: projectTierRawValue) ?? .stage
            var baseURL = ""
            switch assistanceType {
            case .dde,.dpa,.dpaReintate:
                baseURL = "https://" + Configuration.shared.associatedDomain
            case .none:
                baseURL = Configuration.shared.myAccountUrl
            }
            
            switch projectTier {
            case .test:
                return "https://t-e-euweb-paymentenhancements-bge-ui-01.azurewebsites.net"
            default:
                return (baseURL)
            }
        }
        
        private static func getURLPath(assistanceType: MobileAssistanceURL, stateJurisdiction: String? = "") -> String {
            
            switch assistanceType {
            case .dde:
                return "/payments/duedateextension"
            case .dpa,.dpaReintate:
                return "/payments/dpa"
            case .none:
                switch Configuration.shared.opco {
                case .pepco:
                    return stateJurisdiction == "DC" ? "/CustomerSupport/Pages/DC/AssistancePrograms(DC).aspx" : "/CustomerSupport/Pages/MD/AssistancePrograms(MD).aspx"
                case .delmarva:
                    return stateJurisdiction == "DE" ? "/CustomerSupport/Pages/DE/AssistancePrograms%20(DE).aspx" :
                        "/CustomerSupport/Pages/MD/AssistancePrograms%20(MD).aspx"
                default:
                    return "/CustomerSupport/Pages/AssistancePrograms.aspx"
                }
            }
        }
        
        private static func getUTMParams(assistanceType: MobileAssistanceURL) -> String {
            
            switch assistanceType {
            case .dde:
                return "?utm_source=Mobile%20App%20CTA&utm_medium=Mobile%20Web%20Bill%20Tab&utm_campaign=DDE_CTA"
            case .dpa:
                return "?utm_source=Mobile%20App%20CTA&utm_medium=Mobile%20Web%20Bill%20Tab&utm_campaign=DPA_CTA"
            case .dpaReintate:
                return "?utm_source=Mobile%20App%20CTA&utm_medium=Mobile%20Web%20Bill%20Tab&utm_campaign=DPAReinstate_CTA"
            case .none:
                return "?utm_source=Mobile%20App%20CTA&utm_medium=Mobile%20Web%20Bill%20Tab&utm_campaign=AssistanceProgram_CTA"
            }
        }
        
        static func getMobileAssistnceURL(assistanceType: MobileAssistanceURL, stateJurisdiction: String? = "") -> String {
            return (getBaseURLmobileAssistance(assistanceType: assistanceType) + getURLPath(assistanceType: assistanceType, stateJurisdiction: stateJurisdiction)) + getUTMParams(assistanceType: assistanceType)
            
        }
}
}




