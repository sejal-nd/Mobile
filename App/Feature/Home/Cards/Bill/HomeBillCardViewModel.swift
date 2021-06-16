//
//  BillHomeCard.swift
//  Mobile
//
//  Created by Sam Francis on 7/17/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

class HomeBillCardViewModel {
    
    let bag = DisposeBag()
    
    let fetchDataMMEvents: Observable<Event<MaintenanceMode>>
    let accountDetailEvents: Observable<Event<AccountDetail>>
    let scheduledPaymentEvents: Observable<Event<PaymentItem?>>
    
    
    var accountDetail = BehaviorRelay<AccountDetail?>(value: nil)
    var walletItems = BehaviorRelay<[WalletItem]?>(value: nil)
    let selectedWalletItem = BehaviorRelay<WalletItem?>(value: nil)
    
    let isFetching = BehaviorRelay(value: false)
    let isError = BehaviorRelay(value: false)
    
    let emailAddress = BehaviorRelay(value: "")
    let phoneNumber = BehaviorRelay(value: "")
    let mobileAssistanceURL = BehaviorRelay(value: "")
    var mobileAssistanceType = MobileAssistanceURL(rawValue: "none")
    private let kMaxUsernameChars = 255
    
    let submitOneTouchPay = PublishSubject<Void>()
    
    let fetchData: Observable<Void>
    
    private let fetchTracker: ActivityTracker
    
    let paymentTracker = ActivityTracker()
    
    required init(fetchData: Observable<Void>,
                  fetchDataMMEvents: Observable<Event<MaintenanceMode>>,
                  accountDetailEvents: Observable<Event<AccountDetail>>,
                  scheduledPaymentEvents: Observable<Event<PaymentItem?>>,
                  fetchTracker: ActivityTracker) {
        self.fetchData = fetchData
        self.fetchDataMMEvents = fetchDataMMEvents
        self.accountDetailEvents = accountDetailEvents
        self.scheduledPaymentEvents = scheduledPaymentEvents
        self.fetchTracker = fetchTracker
        
        oneTouchPayResult
            .withLatestFrom(walletItem.unwrap()) { ($0, $1) }
            .subscribe(onNext: { oneTouchPayEvent, walletItem in
                switch (walletItem.bankOrCard, oneTouchPayEvent.error) {
                case (.bank, nil):
                    GoogleAnalytics.log(event: .oneTouchBankComplete)
                case (.bank, let error):
                    GoogleAnalytics.log(event: .oneTouchBankError,
                                        dimensions: [.errorCode: (error as? NetworkingError)?.title ?? ""])
                case (.card, nil):
                    GoogleAnalytics.log(event: .oneTouchCardComplete)
                case (.card, let error):
                    GoogleAnalytics.log(event: .oneTouchCardError,
                                        dimensions: [.errorCode: (error as? NetworkingError)?.title ?? ""])
                }
            })
            .disposed(by: bag)
    }
    
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
                    if self.accountDetail.value?.isCashOnly ?? false {
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
                
                if let walletItem = self.selectedWalletItem.value, walletItem.isExpired {
                    self.selectedWalletItem.accept(nil)
                }
                
                onSuccess?()
            case .failure:
                self?.isFetching.accept(false)
                self?.isError.accept(true)
                onError?()
            }
        }
    }
    
    private lazy var fetchTrigger = Observable
        .merge(fetchData, RxNotifications.shared.defaultWalletItemUpdated)
    
    // Awful maintenance mode check
    private lazy var defaultWalletItemUpdatedMMEvents: Observable<Event<MaintenanceMode>> = RxNotifications.shared.defaultWalletItemUpdated
        .filter { _ in AccountsStore.shared.currentIndex != nil }
        .toAsyncRequest(activityTracker: { [weak self] in self?.fetchTracker },
                        requestSelector: { [unowned self] _ in AnonymousService.rx.getMaintenanceMode(shouldPostNotification: true) })
    
    private lazy var maintenanceModeEvents: Observable<Event<MaintenanceMode>> =
        Observable.merge(fetchDataMMEvents, defaultWalletItemUpdatedMMEvents)
    
    private lazy var walletItemEvents: Observable<Event<WalletItem?>> = maintenanceModeEvents
        .filter {
            guard let maint = $0.element else { return true }
            return !maint.all && !maint.bill && !maint.home
    }
    .withLatestFrom(fetchTrigger)
    .toAsyncRequest(activityTracker: { [weak self] in self?.fetchTracker },
                    requestSelector: { [weak self] _ in
                        guard let this = self else { return .empty() }
                        return WalletService.rx.fetchWalletItems().map { $0.first(where: { $0.isDefault }) }
    })
    
    private(set) lazy var walletItemNoNetworkConnection: Observable<Bool> = walletItemEvents.errors()
        .map { ($0 as? NetworkingError) == .noNetwork }
    
    private(set) lazy var walletItem: Observable<WalletItem?> = walletItemEvents.elements()
    
    private lazy var account: Observable<Account> = fetchData.map { _ in AccountsStore.shared.currentAccount }
    
    private(set) lazy var oneTouchPayResult: Observable<Event<Void>> = submitOneTouchPay.asObservable()
        .withLatestFrom(Observable.combineLatest(accountDetailEvents.elements(),
                                                 walletItem.unwrap()))
        .do(onNext: { _, walletItem in
            switch walletItem.bankOrCard {
            case .bank:
                GoogleAnalytics.log(event: .oneTouchBankOffer)
            case .card:
                GoogleAnalytics.log(event: .oneTouchCardOffer)
            }
        })
        .map { accountDetail, walletItem in
            let startOfToday = Calendar.opCo.startOfDay(for: .now)
            let paymentDate: Date
            if Configuration.shared.opco == .bge &&
                Calendar.opCo.component(.hour, from: .now) >= 20,
                let tomorrow = Calendar.opCo.date(byAdding: .day, value: 1, to: startOfToday) {
                paymentDate = tomorrow
            } else {
                paymentDate = .now
            }
            
            return [
                "accountNumber": accountDetail.accountNumber,
                "paymentAmount": accountDetail.billingInfo.netDueAmount!,
                "paymentDate": paymentDate,
                "walletItem": walletItem
            ]
    }
    .toAsyncRequest(activityTracker: paymentTracker,
                    requestSelector: { [unowned self] (object: [String: Any]) in
                        let paymentAmount = object["paymentAmount"] as! Double
                        let paymentDate = object["paymentDate"] as! Date
                        
                        let request = ScheduledPaymentUpdateRequest(paymentAmount: paymentAmount, paymentDate: paymentDate, walletItem: object["walletItem"] as! WalletItem, alternateEmail: "", alternatePhoneNumber: "")
                        
                        return PaymentService.rx.schedulePayment(accountNumber: object["accountNumber"] as! String, request: request)
                            .do(onNext: { confirmationNumber in
                                let paymentDetails = PaymentDetails(amount: paymentAmount,
                                                                    date: paymentDate,
                                                                    confirmationNumber: confirmationNumber)
                                RecentPaymentsStore.shared[AccountsStore.shared.currentAccount] = paymentDetails
                            })
                            .mapTo(())
    })
    
    //MARK: - Loaded States
    
    private lazy var accountDetailDriver: Driver<AccountDetail> =
        accountDetailEvents.elements().asDriver(onErrorDriveWith: .empty())
    
    private lazy var scheduledPaymentDriver: Driver<PaymentItem?> =
        scheduledPaymentEvents.elements().asDriver(onErrorDriveWith: .empty())
    
    private lazy var walletItemDriver: Driver<WalletItem?> = walletItem.asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showLoadingState: Driver<Bool> = fetchTracker.asDriver()
        .skip(1)
        .startWith(true)
        .distinctUntilChanged()
    
    private(set) lazy var billNotReady: Driver<Bool> = billState.map { $0 == .billNotReady }
    
    private(set) lazy var showErrorState: Driver<Bool> = Observable
        .combineLatest(accountDetailEvents,
                       walletItemEvents,
                       scheduledPaymentEvents,
                       showMaintenanceModeState.asObservable())
        { ($0.error != nil || $1.error != nil || $2.error != nil) && !$3 }
        .startWith(false)
        .distinctUntilChanged()
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showMaintenanceModeState: Driver<Bool> = maintenanceModeEvents
        .map { $0.element?.bill ?? false }
        .startWith(false)
        .distinctUntilChanged()
        .asDriver(onErrorDriveWith: .empty())
    
    // MARK: - Title States
    
    enum BillState {
        case restoreService, catchUp, avoidShutoff, pastDue, finaled,
        eligibleForCutoff, billReady, billReadyAutoPay, billPaid,
        billPaidIntermediate, credit, paymentPending, billNotReady, paymentScheduled
        
        var isPrecariousBillSituation: Bool {
            switch self {
            case .restoreService, .catchUp, .avoidShutoff, .pastDue, .finaled, .eligibleForCutoff:
                return true
            default:
                return false
            }
        }
    }
    
    private lazy var billState: Driver<BillState> = Observable
        .combineLatest(accountDetailEvents.elements(), scheduledPaymentEvents.elements(), walletItem)
        .map { accountDetail, scheduledPayment, walletItem -> BillState in
            let billingInfo = accountDetail.billingInfo
            let opco = Configuration.shared.opco
            
            if RecentPaymentsStore.shared[AccountsStore.shared.currentAccount] != nil {
                return .billPaidIntermediate
            }
            
            if accountDetail.isFinaled && billingInfo.pastDueAmount > 0 {
                return .finaled
            }
            
            if opco != .bge && billingInfo.restorationAmount > 0 && accountDetail.isCutOutNonPay {
                return .restoreService
            }
            
            if billingInfo.disconnectNoticeArrears > 0 {
                if accountDetail.isCutOutIssued {
                    return .eligibleForCutoff
                } else {
                    return .avoidShutoff
                }
            }
            
            if opco != .bge && billingInfo.amtDpaReinst > 0 {
                return .catchUp
            }
            
            if billingInfo.pastDueAmount > 0 {
                return .pastDue
            }
            
            if billingInfo.pendingPaymentsTotal > 0 {
                return .paymentPending
            }
            
            if scheduledPayment?.amount > 0 {
                return .paymentScheduled
            }
            
            if billingInfo.netDueAmount > 0 && (accountDetail.isAutoPay || accountDetail.isBGEasy) {
                return .billReadyAutoPay
            }
            
            if (opco == .bge || opco.isPHI) && billingInfo.netDueAmount < 0 {
                return .credit
            }
            
            if billingInfo.netDueAmount > 0 {
                return .billReady
            }
            
            if let billDate = billingInfo.billDate,
                let lastPaymentDate = billingInfo.lastPaymentDate,
                billingInfo.lastPaymentAmount > 0,
                billDate < lastPaymentDate {
                return .billPaid
            }
            
            return .billNotReady
    }
    .asDriver(onErrorDriveWith: .empty())
    
    // MARK: - Show/Hide view logic
    
    let showViewBillButton = !StormModeStatus.shared.isOn
    
    private(set) lazy var showHeaderView: Driver<Bool> = billState.map {
        switch $0 {
        case .restoreService, .catchUp, .avoidShutoff, .pastDue, .finaled, .eligibleForCutoff, .credit:
            return true
        default:
            return AccountsStore.shared.currentAccount.isMultipremise
        }
    }
    
    private(set) lazy var showAlertIcon: Driver<Bool> = billState.map { $0.isPrecariousBillSituation }
    
    private(set) lazy var showPaymentPendingIcon: Driver<Bool> = billState.map { $0 == .paymentPending }
    
    private(set) lazy var showBillPaidIcon: Driver<Bool> = billState.map {
        $0 == .billPaid || $0 == .billPaidIntermediate
    }
    
    private(set) lazy var showPaymentDescription: Driver<Bool> = paymentDescriptionText.isNil().not()
    
    private(set) lazy var showSlideToPayConfirmationDetailLabel: Driver<Bool> = billState.map {
        $0 == .billPaidIntermediate
    }
    
    private(set) lazy var reviewPaymentShouldShowConvenienceFee: Driver<Bool> =
        self.walletItemDriver.map { $0?.bankOrCard == .card }
    
    private(set) lazy var isActiveSeveranceUser: Driver<Bool> = self.accountDetailDriver.map { $0.isActiveSeverance }
    
    private(set) lazy var showAmount: Driver<Bool> = billState.map { $0 != .billPaidIntermediate }
    
    private(set) lazy var showConvenienceFee: Driver<Bool> = showSaveAPaymentAccountButton.not()
    
    private(set) lazy var showDueDate: Driver<Bool> = billState.map {
        switch $0 {
        case .billPaid, .billPaidIntermediate, .paymentPending:
            return false
        default:
            return true
        }
    }
    
    let showDueDateTooltip = Configuration.shared.opco == .peco
    
    
    private(set) lazy var showWalletItemInfo: Driver<Bool> = Driver
        .combineLatest(
            showSaveAPaymentAccountButton,
            showMinMaxPaymentAllowed,
            showAutoPay)
        { ($0) && !$1 && !$2 }
        .distinctUntilChanged()
    
    private(set) lazy var showBankCreditNumberButton: Driver<Bool> = walletItemDriver.isNil().not()
    
    private(set) lazy var showBankCreditExpiredLabel: Driver<Bool> = walletItemDriver.map {
        $0?.isExpired ?? false
    }
    
    private(set) lazy var showSaveAPaymentAccountButton: Driver<Bool> = Driver
        .combineLatest(billState, walletItemDriver)
        { $0 != .credit && !$0.isPrecariousBillSituation && $0 != .paymentScheduled && $1 == nil }
        .distinctUntilChanged()
    
    private(set) lazy var showMinMaxPaymentAllowed: Driver<Bool> = Driver
        .combineLatest(billState,
                       walletItemDriver,
                       accountDetailDriver,
                       minMaxPaymentAllowedText)
        { billState, walletItem, accountDetail, minMaxPaymentAllowedText in
            return billState == .billReady &&
                walletItem != nil &&
                minMaxPaymentAllowedText != nil
    }
    .distinctUntilChanged()

    
    private(set) lazy var showMakePaymentButton: Driver<Bool> = accountDetailDriver.map {
        return ($0.billingInfo.netDueAmount > 0 || Configuration.shared.opco == .bge || Configuration.shared.opco.isPHI ) ? true : false
    }
    
    private(set) lazy var showScheduledPayment: Driver<Bool> = billState.map { $0 == .paymentScheduled }
    
    private(set) lazy var showAutoPay: Driver<Bool> = billState.map {
        $0 == .billReadyAutoPay
    }
    
    // MARK: - View States
    private(set) lazy var paymentDescriptionText: Driver<NSAttributedString?> =
        Driver.combineLatest(billState, accountDetailDriver)
        { (billState, accountDetail) in
            let textColor = StormModeStatus.shared.isOn ? UIColor.white : UIColor.deepGray
            switch billState {
            case .billPaid, .billPaidIntermediate:
                let text = NSLocalizedString("Thank you for your payment", comment: "")
                return NSAttributedString(string: text, attributes: [.font: OpenSans.regular.of(textStyle: .headline),
                                                                     .foregroundColor: textColor])
            case .paymentPending:
                let text: String
                switch Configuration.shared.opco {
                case .bge:
                    text = NSLocalizedString("You have processing payments", comment: "")
                case .ace, .comEd, .delmarva, .peco, .pepco:
                    text = NSLocalizedString("You have pending payments", comment: "")
                }
                return NSAttributedString(string: text, attributes: [.font: OpenSans.italic.of(textStyle: .headline),
                                                                     .foregroundColor: textColor])
            default:
                return nil
            }
    }
    
    // MARK: - Assistance View States
    private(set) lazy var paymentAssistanceValues: Driver<(title: String, description: String, ctaType: String, ctaURL: String)?> =
        Driver.combineLatest(billState, accountDetailDriver)
        { (billState, accountDetail) in
            let isAccountTypeEligible = Configuration.shared.opco.isPHI ? accountDetail.isResidential || accountDetail.isSmallCommercialCustomer : accountDetail.isResidential
            if isAccountTypeEligible &&
                FeatureFlagUtility.shared.bool(forKey: .paymentProgramAds) {
                if accountDetail.isDueDateExtensionEligible &&
                    accountDetail.billingInfo.pastDueAmount > 0 {
                    
                    self.mobileAssistanceURL.accept(MobileAssistanceURL.getMobileAssistnceURL(assistanceType: .dde))
                    self.mobileAssistanceType = MobileAssistanceURL.dde
                    if Configuration.shared.opco.isPHI {
                        return (title: "You’re eligible for a One-Time Payment Delay",
                                description: "Having trouble keeping up with your \(Configuration.shared.opco.displayString) bill? We’re here to help. Extend your upcoming bill due date by up to 30 calendar days with a One-Time Payment Delay",
                                ctaType: "Request One-Time Payment Delay",
                                ctaURL: "")
                    } else {
                        return (title: "You’re eligible for a Due Date Extension",
                                description: "Having trouble keeping up with your \(Configuration.shared.opco.displayString) bill? We’re here to help. Extend your upcoming bill due date by up to 21 calendar days with a Due Date Extension",
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
    
    private(set) lazy var showAlertAnimation: Driver<Bool> = billState.map {
        return $0.isPrecariousBillSituation
    }
    
    private(set) lazy var resetAlertAnimation: Driver<Void> = fetchTracker.asDriver()
        .filter(!)
        .mapTo(())
    
    private(set) lazy var headerText: Driver<NSAttributedString?> = Driver.combineLatest(accountDetailDriver, billState)
    { accountDetail, billState in
        let billingInfo = accountDetail.billingInfo
        let isMultiPremise = AccountsStore.shared.currentAccount.isMultipremise
        
        let textColor = StormModeStatus.shared.isOn ? UIColor.white : UIColor.errorRed
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = 16
        var attributes: [NSAttributedString.Key: Any] = [.font: SystemFont.semibold.of(textStyle: .caption1),
                                                         .paragraphStyle: style,
                                                         .foregroundColor: textColor]
        
        switch billState {
        case .credit:
            attributes[.foregroundColor] = StormModeStatus.shared.isOn ? UIColor.white : UIColor.deepGray
            return NSAttributedString(string: NSLocalizedString("Credit Balance", comment: ""),
                                      attributes: attributes)
        case .pastDue:
            let string: String
            switch (isMultiPremise, billingInfo.netDueAmount == billingInfo.pastDueAmount) {
            case (false, false):
                guard let amount = billingInfo.pastDueAmount?.currencyString else { return nil }
                let format = "%@ of the total is due immediately.".localized()
                string = String(format: format, amount)
            case (true, false):
                guard let amount = billingInfo.pastDueAmount?.currencyString else { return nil }
                let format = "%@ of the total is due immediately for your multi-premise account.".localized()
                string = String(format: format, amount)
            case (false, true):
                if accountDetail.serviceType == nil && Configuration.shared.opco == .bge && accountDetail.billingInfo.pastDueAmount > 0 {
                    guard let amount = billingInfo.pastDueAmount?.currencyString else { return nil }
                    let format = "%@ must be paid immediately. Your account has been stopped.".localized()
                    string = String(format: format, amount)
                } else {
                    string = NSLocalizedString("Your bill is past due.", comment: "")
                }
            case (true, true):
                string = NSLocalizedString("Your bill is past due for your multi-premise account.", comment: "")
            }
            
            return NSAttributedString(string: string, attributes: attributes)
        case .catchUp:
            guard let amountString = billingInfo.amtDpaReinst?.currencyString,
                  let dueByDate = billingInfo.dueByDate else {
                return nil
            }
            
            let days = dueByDate.interval(ofComponent: .day, fromDate: Calendar.opCo.startOfDay(for: .now))
            
            let string: String
            switch (days > 0 && Configuration.shared.opco != .peco, billingInfo.amtDpaReinst == billingInfo.netDueAmount) {
            case (true, true):
                let format = "The total amount is due in %d day%@ to catch up on your DPA."
                string = String.localizedStringWithFormat(format, days, days == 1 ? "": "s")
            case (true, false):
                let format = "%@ of the total is due in %d day%@ to catch up on your DPA."
                string = String.localizedStringWithFormat(format, amountString, days, days == 1 ? "": "s")
            case (false, true):
                string = NSLocalizedString("The total amount must be paid immediately to catch up on your DPA.", comment: "")
            case (false, false):
                let format = "%@ of the total is due immediately to catch up on your DPA."
                string = String.localizedStringWithFormat(format, amountString)
            }
            
            return NSAttributedString(string: string, attributes: attributes)
        case .restoreService:
            guard let amountString = billingInfo.restorationAmount?.currencyString else {
                return nil
            }
            if billingInfo.restorationAmount == billingInfo.netDueAmount {
                let string =  NSLocalizedString("The total amount must be paid immediately to restore service.", comment: "")
                return NSAttributedString(string: string, attributes: attributes)
            } else {
                let localizedText = NSLocalizedString("%@ of the total must be paid immediately to restore service.", comment: "")
                let string = String.localizedStringWithFormat(localizedText, amountString)
                return NSAttributedString(string: string, attributes: attributes)
            }
            
        case .avoidShutoff, .eligibleForCutoff:
            guard let amountString = billingInfo.disconnectNoticeArrears?.currencyString else {
                return nil
            }
            
            let date = billingInfo.turnOffNoticeExtendedDueDate ?? billingInfo.turnOffNoticeDueDate
            let days = date?.interval(ofComponent: .day, fromDate: Calendar.opCo.startOfDay(for: .now)) ?? 0
            let dateString = date?.mmDdYyyyString ?? "--"
            
            let string: String
            switch (days > 0, isMultiPremise, billingInfo.disconnectNoticeArrears == billingInfo.netDueAmount) {
            case (true, true, true):
                let format = "The total amount must be paid by %@ to avoid shutoff for your multi-premise account."
                string = String.localizedStringWithFormat(format, dateString)
            case (true, true, false):
                let format = "%@ of the total must be paid by %@ to avoid shutoff for your multi-premise account."
                string = String.localizedStringWithFormat(format, amountString, dateString)
            case (true, false, true):
                let format = "The total amount must be paid by %@ to avoid shutoff."
                string = String.localizedStringWithFormat(format, dateString)
            case (true, false, false):
                let format = "%@ of the total must be paid by %@ to avoid shutoff."
                string = String.localizedStringWithFormat(format, amountString, dateString)
            case (false, true, true):
                string = NSLocalizedString("The total amount must be paid immediately to avoid shutoff for your multi-premise account.", comment: "")
            case (false, true, false):
                let format = "%@ of the total must be paid immediately to avoid shutoff for your multi-premise account."
                string = String.localizedStringWithFormat(format, amountString)
            case (false, false, true):
                string = NSLocalizedString("The total amount must be paid immediately to avoid shutoff.", comment: "")
            case (false, false, false):
                let format = "%@ of the total must be paid immediately to avoid shutoff."
                string = String.localizedStringWithFormat(format, amountString)
            }
            
            return NSAttributedString(string: string, attributes: attributes)
        case .finaled:
            guard let amountString = billingInfo.pastDueAmount?.currencyString else {
                return nil
            }
            var string = ""
            let billingInfo = accountDetail.billingInfo
            let status = Configuration.shared.opco.isPHI ? "is inactive" : "has been finaled"
            if billingInfo.pastDueAmount == billingInfo.netDueAmount {
                string = NSLocalizedString("The total amount must be paid immediately. Your account \(status).", comment: "")
            } else {
                if billingInfo.pastDueAmount > .zero && accountDetail.isFinaled {
                    string = String.localizedStringWithFormat("%@ must be paid immediately. Your account \(status).", billingInfo.pastDueAmount?.currencyString ?? "--")
                }
            }
            return NSAttributedString(string: string, attributes: attributes)
        default:
            if AccountsStore.shared.currentAccount.isMultipremise {
                attributes[.foregroundColor] = StormModeStatus.shared.isOn ? UIColor.white : UIColor.deepGray
                return NSAttributedString(string: NSLocalizedString("Multi-Premise Bill", comment: ""),
                                          attributes: attributes)
            }
            return nil
        }
    }
    
    private(set) lazy var headerA11yText: Driver<String?> = paymentDescriptionText.map {
        $0?.string.replacingOccurrences(of: "shutoff", with: "shut-off")
            .replacingOccurrences(of: "Shutoff", with: "shut-off")
    }
    
    private(set) lazy var amountText: Driver<String?> = Driver
        .combineLatest(billState, accountDetailDriver)
        .map { billState, accountDetail in
            switch billState {
            case .billPaid:
                return accountDetail.billingInfo.lastPaymentAmount?.currencyString
            case .paymentPending:
                return accountDetail.billingInfo.pendingPayments.last?.amount.currencyString
            default:
                guard let netDue = accountDetail.billingInfo.netDueAmount else { return nil }
                return abs(netDue).currencyString
            }
    }
    
    private(set) lazy var dueDateText: Driver<NSAttributedString?> = Driver.combineLatest(accountDetailDriver, billState)
    { accountDetail, billState in
        let grayAttributes: [NSAttributedString.Key: Any] =
            [.foregroundColor: StormModeStatus.shared.isOn ? UIColor.white : UIColor.deepGray,
             .font: SystemFont.regular.of(textStyle: .caption1)]
        let redAttributes: [NSAttributedString.Key: Any] =
            [.foregroundColor: StormModeStatus.shared.isOn ? UIColor.white : UIColor.errorRed,
             .font: SystemFont.semibold.of(textStyle: .caption1)]
        
        switch billState {
        case .pastDue, .finaled, .restoreService, .avoidShutoff, .eligibleForCutoff, .catchUp:
            if let netDueAmount = accountDetail.billingInfo.netDueAmount, netDueAmount == accountDetail.billingInfo.pastDueAmount {
                return NSAttributedString(string: "Total Amount Due Immediately".localized(),
                                          attributes: redAttributes)
            } else {
                return NSAttributedString(string: NSLocalizedString("Total Amount Due", comment: ""),
                                          attributes: grayAttributes)
            }
        case .credit:
            return Configuration.shared.opco.isPHI ? NSAttributedString(string: NSLocalizedString("You have no amount due", comment: ""), attributes: grayAttributes) :
                NSAttributedString(string: NSLocalizedString("No Amount Due", comment: ""), attributes: grayAttributes)
        default:
            guard let dueByDate = accountDetail.billingInfo.dueByDate else { return nil }
            let localizedText = NSLocalizedString("Total Amount Due on %@", comment: "")
            return NSAttributedString(string: String(format: localizedText, dueByDate.mmDdYyyyString),
                                      attributes: grayAttributes)
        }
    }
    
    private(set) lazy var bankCreditCardNumberText: Driver<String?> = walletItemDriver.map {
        guard let maskedNumber = $0?.maskedAccountNumber else { return nil }
        return "**** " + maskedNumber
    }
    
    private(set) lazy var bankCreditCardImage: Driver<UIImage?> = walletItemDriver.map {
        guard let walletItem = $0 else { return nil }
        return walletItem.bankOrCard == .bank ? #imageLiteral(resourceName: "ic_bank") : #imageLiteral(resourceName: "ic_creditcard")
    }
    
    private(set) lazy var bankCreditCardButtonAccessibilityLabel: Driver<String?> = walletItemDriver.map {
        guard let walletItem = $0,
            let maskedNumber = walletItem.maskedAccountNumber else { return nil }
        
        let imageLabel: String
        switch walletItem.bankOrCard {
        case .bank:
            imageLabel = NSLocalizedString("Bank account", comment: "")
        case .card:
            imageLabel = NSLocalizedString("Credit card", comment: "")
        }
        
        return imageLabel + ", " + String(format:NSLocalizedString("Account ending in %@", comment: ""), maskedNumber)
    }
    
    private(set) lazy var minMaxPaymentAllowedText: Driver<String?> = Driver.combineLatest(accountDetailDriver, walletItemDriver)
    { accountDetail, walletItemOptional in
        guard let walletItem = walletItemOptional else { return nil }
        guard let paymentAmount = accountDetail.billingInfo.netDueAmount else { return nil }
        
        let minPayment = accountDetail.billingInfo.minPaymentAmount
        let maxPayment = accountDetail.billingInfo.maxPaymentAmount(bankOrCard: walletItem.bankOrCard)
        
        if paymentAmount < minPayment {
            let minLocalizedText = NSLocalizedString("Minimum payment allowed is %@", comment: "")
            return String(format: minLocalizedText, minPayment.currencyString)
        } else if paymentAmount > maxPayment {
            let maxLocalizedText = NSLocalizedString("Maximum payment allowed is %@", comment: "")
            return String(format: maxLocalizedText, maxPayment.currencyString)
        } else {
            return nil
        }
    }
    
    private(set) lazy var convenienceFeeText: Driver<String?> =
        Driver.combineLatest(accountDetailDriver, walletItemDriver) { accountDetail, walletItem in
            guard let walletItem = walletItem else { return nil }
            if walletItem.bankOrCard == .bank {
                return NSLocalizedString("No fees applied.", comment: "")
            } else {
                return String.localizedStringWithFormat("A %@ convenience fee will be applied by Paymentus, our payment partner.", accountDetail.billingInfo.convenienceFee.currencyString)
            }
    }

    
    private(set) lazy var titleFont: Driver<UIFont> = billState
        .map {
            switch $0 {
            case .billReady, .billReadyAutoPay, .billPaid, .billPaidIntermediate, .credit:
                return OpenSans.regular.of(textStyle: .headline)
            case .paymentPending:
                return OpenSans.italic.of(textStyle: .headline)
            default:
                return OpenSans.regular.of(textStyle: .headline)
            }
    }
    
    private(set) lazy var amountFont: Driver<UIFont> = billState
        .map { $0 == .paymentPending ? OpenSans.semibold.of(textStyle: .largeTitle): OpenSans.semibold.of(textStyle: .largeTitle) }
    
    private(set) lazy var amountColor: Driver<UIColor> = billState
        .map { Configuration.shared.opco.isPHI ? ($0 == .credit ? .successGreenText : .deepGray) : .deepGray }
    
    private(set) lazy var automaticPaymentInfoButtonText: Driver<String> =
        Driver.combineLatest(accountDetailDriver, scheduledPaymentDriver)
            .map { accountDetail, scheduledPayment in
                if let paymentAmountText = scheduledPayment?.amount.currencyString,
                    let paymentDateText = scheduledPayment?.date?.mmDdYyyyString {
                    return String.localizedStringWithFormat("You have an automatic payment of %@ for %@.",
                                                            paymentAmountText,
                                                            paymentDateText)
                } else if Configuration.shared.opco == .bge && accountDetail.isBGEasy {
                    return NSLocalizedString("You are enrolled in BGEasy", comment: "")
                } else {
                    return NSLocalizedString("You are enrolled in AutoPay." , comment: "")
                }
    }
    
    private(set) lazy var thankYouForSchedulingButtonText: Driver<String?> = scheduledPaymentDriver.map {
        guard let paymentAmountText = $0?.amount.currencyString else { return nil }
        guard let paymentDateText = $0?.date?.mmDdYyyyString else { return nil }
        let localizedText = NSLocalizedString("Thank you for scheduling your %@ payment for %@." , comment: "")
        return String(format: localizedText, paymentAmountText, paymentDateText)
    }
    
    private(set) lazy var slideToPayConfirmationDetailText: Driver<String?> = accountDetailDriver
        .map { _ in
            switch Configuration.shared.opco {
            case .bge:
                return NSLocalizedString("It may take 24 hours for your payment status to update.", comment: "")
            case .comEd, .peco:
                guard let payment = RecentPaymentsStore.shared[AccountsStore.shared.currentAccount] else {
                    return nil
                }
                
                return String.localizedStringWithFormat("Your confirmation number is %@", payment.confirmationNumber)
            case .ace, .delmarva, .pepco:
                guard let payment = RecentPaymentsStore.shared[AccountsStore.shared.currentAccount] else {
                    return nil
                }
                
                return String.localizedStringWithFormat("Your confirmation number is %@. It may take 24 hours for your payment status to update.", payment.confirmationNumber)
            }
    }
    
    private(set) lazy var bankCreditButtonBorderWidth: Driver<CGFloat> = walletItemDriver.map {
        $0?.isExpired ?? false ? 1 : 0
    }
    
    var paymentTACUrl: URL {
        return URL(string: "https://ipn2.paymentus.com/rotp/www/terms-and-conditions-exln.html")!
    }
    
    var errorPhoneNumber: String {
        switch Configuration.shared.opco {
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
    private(set) lazy var totalPaymentDisplayString: Driver<String?> =
        Driver.combineLatest(accountDetailDriver, reviewPaymentShouldShowConvenienceFee)
            .map { [weak self] accountDetail, showConvenienceFee in
                guard let self = self,
                    let dueAmount = accountDetail.billingInfo.netDueAmount else { return nil }
                if showConvenienceFee {
                    return (dueAmount + accountDetail.billingInfo.convenienceFee).currencyString
                } else {
                    return dueAmount.currencyString
                }
    }
    
    private(set) lazy var convenienceDisplayString: Driver<String?> =
        Driver.combineLatest(accountDetailDriver, walletItemDriver) { accountDetail, walletItem in
            guard let walletItem = walletItem else {
                return NSLocalizedString("with no convenience fee", comment: "")
                
            }
            if walletItem.bankOrCard == .bank {
                return NSLocalizedString("with no convenience fee", comment: "")
            } else {
                return String.localizedStringWithFormat("with a %@ convenience fee included, applied by Paymentus, our payment partner.", accountDetail.billingInfo.convenienceFee.currencyString)
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
        return "**** \(walletItem.maskedAccountNumber ?? "")"
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
                return (baseURL.replacingOccurrences(of: "azstage", with: "aztest")).replacingOccurrences(of: "azstg", with: "aztst1")
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
                return "?utm_source=Mobile%20App%20CTA&utm_medium=Mobile%20Web&utm_campaign=DDE_CTA"
            case .dpa:
                return "?utm_source=Mobile%20App%20CTA&utm_medium=Mobile%20Web&utm_campaign=DPA_CTA"
            case .dpaReintate:
                return "?utm_source=Mobile%20App%20CTA&utm_medium=Mobile%20Web&utm_campaign=DPAReinstate_CTA"
            case .none:
                return "?utm_source=Mobile%20App%20CTA&utm_medium=Mobile%20Web&utm_campaign=AssistanceProgram_CTA"
            }
        }
        
        static func getMobileAssistnceURL(assistanceType: MobileAssistanceURL, stateJurisdiction: String? = "") -> String {
            
            return (getBaseURLmobileAssistance(assistanceType: assistanceType) + getURLPath(assistanceType: assistanceType, stateJurisdiction: stateJurisdiction)) + getUTMParams(assistanceType: assistanceType)
            
        }

}
}
