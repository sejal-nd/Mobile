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
    
    let fetchDataMMEvents: Observable<Event<Maintenance>>
    let accountDetailEvents: Observable<Event<AccountDetail>>
    private let walletService: WalletService
    private let paymentService: PaymentService
    private let authService: AuthenticationService
    
    let cvv2 = Variable<String?>(nil)
    
    let submitOneTouchPay = PublishSubject<Void>()
    
    let fetchData: Observable<FetchingAccountState>
    
    private let refreshFetchTracker: ActivityTracker
    private let switchAccountFetchTracker: ActivityTracker
    
    private func fetchTracker(forState state: FetchingAccountState) -> ActivityTracker {
        switch state {
        case .refresh: return refreshFetchTracker
        case .switchAccount: return switchAccountFetchTracker
        }
    }
    
    let paymentTracker = ActivityTracker()
    
    required init(fetchData: Observable<FetchingAccountState>,
                  fetchDataMMEvents: Observable<Event<Maintenance>>,
                  accountDetailEvents: Observable<Event<AccountDetail>>,
                  walletService: WalletService,
                  paymentService: PaymentService,
                  authService: AuthenticationService,
                  refreshFetchTracker: ActivityTracker,
                  switchAccountFetchTracker: ActivityTracker) {
        self.fetchData = fetchData
        self.fetchDataMMEvents = fetchDataMMEvents
        self.accountDetailEvents = accountDetailEvents
        self.walletService = walletService
        self.paymentService = paymentService
        self.authService = authService
        self.refreshFetchTracker = refreshFetchTracker
        self.switchAccountFetchTracker = switchAccountFetchTracker
                
        self.oneTouchPayResult
            .withLatestFrom(Observable.combineLatest(self.walletItem.unwrap(), self.oneTouchPayResult))
            .subscribe(onNext: { walletItem, oneTouchPayEvent in
                switch (walletItem.bankOrCard, oneTouchPayEvent.error) {
                case (.bank, nil):
                    Analytics.log(event: .OneTouchBankComplete)
                case (.bank, let error):
                    Analytics.log(event: .OneTouchBankError,
                                         dimensions: [.ErrorCode: (error as! ServiceError).serviceCode])
                case (.card, nil):
                    Analytics.log(event: .OneTouchCardComplete)
                case (.card, let error):
                    Analytics.log(event: .OneTouchCardError,
                                         dimensions: [.ErrorCode: (error as! ServiceError).serviceCode])
                }
            })
            .disposed(by: bag)
    }
    
    private lazy var fetchTrigger = Observable
        .merge(self.fetchData, RxNotifications.shared.defaultWalletItemUpdated.map(to: FetchingAccountState.switchAccount))
    
    // Awful maintenance mode check
    private lazy var defaultWalletItemUpdatedMMEvents: Observable<Event<Maintenance>> = RxNotifications.shared.defaultWalletItemUpdated
        .toAsyncRequest(activityTracker: { [weak self] _ in self?.fetchTracker(forState: .switchAccount) },
                        requestSelector: { [unowned self] _ in self.authService.getMaintenanceMode() })
    
    private lazy var maintenanceModeEvents: Observable<Event<Maintenance>> = Observable.merge(self.fetchDataMMEvents, self.defaultWalletItemUpdatedMMEvents)
    
    private lazy var walletItemEvents: Observable<Event<WalletItem?>> = self.maintenanceModeEvents
        .filter { !($0.element?.billStatus ?? false) && !($0.element?.homeStatus ?? false) }
        .withLatestFrom(self.fetchTrigger)
        .toAsyncRequest(activityTracker: { [weak self] in self?.fetchTracker(forState: $0) },
                        requestSelector: {[unowned self] _ in
                            self.walletService.fetchWalletItems().map { $0.first(where: { $0.isDefault }) }
        })
    
    private(set) lazy var walletItemNoNetworkConnection: Observable<Bool> = self.walletItemEvents.errors()
        .map { ($0 as? ServiceError)?.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue }
    
    private(set) lazy var workDaysNoNetworkConnection: Observable<Bool> = self.workDayEvents.errors()
        .map { ($0 as? ServiceError)?.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue }
    
    private lazy var walletItem: Observable<WalletItem?> = self.walletItemEvents.elements()
    
    private lazy var account: Observable<Account> = self.fetchData.map { _ in AccountsStore.shared.currentAccount }

    private(set) lazy var data: Observable<Event<(AccountDetail, WalletItem?)>> =
        Observable.combineLatest(self.accountDetailEvents.elements(),
                                 self.walletItem)
            .materialize()
            .share()
    
    private lazy var workDayEvents: Observable<Event<[Date]>> = self.maintenanceModeEvents
        .filter { !($0.element?.billStatus ?? false) && !($0.element?.homeStatus ?? false) }
        .withLatestFrom(self.fetchTrigger)
        .flatMapLatest { [unowned self] state -> Observable<Event<[Date]>> in
            if Environment.shared.opco == .peco {
                return self.paymentService.fetchWorkdays()
                    .trackActivity(self.fetchTracker(forState: state))
                    .materialize()
            } else {
                return Observable<[Date]>.just([]).materialize()
            }
        }
        .share(replay: 1)
    
    private(set) lazy var oneTouchPayResult: Observable<Event<Void>> = self.submitOneTouchPay.asObservable()
        .withLatestFrom(Observable.combineLatest(self.accountDetailEvents.elements(),
                                                 self.walletItem.unwrap(),
                                                 self.cvv2.asObservable(),
                                                 self.shouldShowWeekendWarning.asObservable(),
                                                 self.workDayEvents.elements()))
        .do(onNext: { _, walletItem, _, _, _ in
            switch walletItem.bankOrCard {
            case .bank:
                Analytics.log(event: .OneTouchBankOffer)
            case .card:
                Analytics.log(event: .OneTouchCardOffer)
            }
        })
        .map { accountDetail, walletItem, cvv2, isWeekendOrHoliday, workDays in
            let startOfToday = Calendar.opCo.startOfDay(for: Date())
            let paymentDate: Date
            if isWeekendOrHoliday, let nextWorkDay = workDays.sorted().first(where: { $0 > Date() }) {
                paymentDate = nextWorkDay
            } else if Environment.shared.opco == .bge &&
                Calendar.opCo.component(.hour, from: Date()) >= 20,
                let tomorrow = Calendar.opCo.date(byAdding: .day, value: 1, to: startOfToday) {
                paymentDate = tomorrow
            } else {
                paymentDate = Date()
            }
            return Payment(accountNumber: accountDetail.accountNumber,
                           existingAccount: true,
                           saveAccount: true,
                           maskedWalletAccountNumber: walletItem.maskedWalletItemAccountNumber!,
                           paymentAmount: accountDetail.billingInfo.netDueAmount!,
                           paymentType: (walletItem.bankOrCard == .bank) ? .check : .credit,
                           paymentDate: paymentDate,
                           walletId: AccountsStore.shared.customerIdentifier,
                           walletItemId: walletItem.walletItemID!,
                           cvv: cvv2)
        }
        .flatMapLatest { [unowned self] payment in
            self.paymentService.schedulePayment(payment: payment)
                .do(onNext: {
                    let paymentDetails = PaymentDetails(amount: payment.paymentAmount, date: payment.paymentDate)
                    RecentPaymentsStore.shared[AccountsStore.shared.currentAccount] = paymentDetails
                })
                .map(to: ())
                .trackActivity(self.paymentTracker)
                .materialize()
                .filter { !$0.isCompleted }
        }
        .share()
    
    private(set) lazy var shouldShowWeekendWarning: Driver<Bool> = {
        if Environment.shared.opco == .peco {
            return self.workDayEvents.elements()
                .map { $0.filter(Calendar.opCo.isDateInToday).isEmpty }
                .asDriver(onErrorDriveWith: .empty())
        } else {
            return Driver.just(false)
        }
    }()
    
    private(set) lazy var promptForCVV: Driver<Bool> = {
        if Environment.shared.opco != .bge {
            return Driver.just(false)
        } else {
            return self.walletItemDriver.map {
                guard let walletItem = $0 else { return false }
                switch walletItem.bankOrCard {
                case .bank:
                    return false
                case .card:
                    return true
                }
            }
        }
    }()
    
    private(set) lazy var cvvIsValid: Driver<Bool> = self.cvv2.asDriver()
        .map { 3...4 ~= ($0?.count ?? 0) }
    
    //MARK: - Loaded States
    
    private lazy var accountDetailDriver: Driver<AccountDetail> = self.accountDetailEvents.elements().asDriver(onErrorDriveWith: .empty())
    private lazy var walletItemDriver: Driver<WalletItem?> = self.walletItem.asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var billNotReady: Driver<Bool> = self.billState.map { $0 == .billNotReady }
        .asDriver(onErrorJustReturn: false)
    
    private(set) lazy var showErrorState: Driver<Bool> = {
        if Environment.shared.opco == .peco {
            return Observable.combineLatest(self.accountDetailEvents, self.walletItemEvents, self.workDayEvents, self.showMaintenanceModeState.asObservable())
                .map { ($0.0.error != nil || $0.1.error != nil || $0.2.error != nil) && !$0.3 }
                .startWith(false)
                .asDriver(onErrorDriveWith: .empty())
        } else {
            return Observable.combineLatest(self.accountDetailEvents, self.walletItemEvents, self.showMaintenanceModeState.asObservable())
                .map { ($0.0.error != nil || $0.1.error != nil) && !$0.2 }
                .startWith(false)
                .asDriver(onErrorDriveWith: .empty())
        }
        
    }()
    
    private(set) lazy var showCustomErrorState: Driver<Bool> = self.accountDetailEvents.asDriver(onErrorDriveWith: .empty()).map {
        if let serviceError = $0.error as? ServiceError {
            return serviceError.serviceCode == ServiceErrorCode.fnAccountDisallow.rawValue
        }
        return false
    }
        .startWith(false)
    
    private(set) lazy var showMaintenanceModeState: Driver<Bool> = self.maintenanceModeEvents
        .map { $0.element?.billStatus ?? false }
        .startWith(false)
        .asDriver(onErrorDriveWith: .empty())
    
    // MARK: - Title States
    
    enum BillState {
        case restoreService, catchUp, avoidShutoff, pastDue, billReady, billReadyAutoPay, billPaid, billPaidIntermediate, credit,
        paymentPending, billNotReady, paymentScheduled
        
        var isPrecariousBillSituation: Bool {
            switch self {
            case .restoreService, .catchUp, .avoidShutoff, .pastDue:
                return true
            default:
                return false
            }
        }
        
        var billPaidOrPending: Bool {
            switch self {
            case .billPaid, .paymentPending, .billPaidIntermediate:
                return true
            default:
                return false
            }
        }
    }
    
    private lazy var billState: Driver<BillState> =
        self.data.elements()
            .map { accountDetail, walletItem -> BillState in
                let billingInfo = accountDetail.billingInfo
                let opco = Environment.shared.opco
                
                if RecentPaymentsStore.shared[AccountsStore.shared.currentAccount] != nil {
                    return .billPaidIntermediate
                }
                
                if opco != .bge && (billingInfo.restorationAmount ?? 0) > 0 && accountDetail.isCutOutNonPay {
                    return .restoreService
                }
                
                if (billingInfo.disconnectNoticeArrears ?? 0) > 0 && billingInfo.isDisconnectNotice {
                    return .avoidShutoff
                }
                
                if opco != .bge && (billingInfo.amtDpaReinst ?? 0 > 0) {
                    return .catchUp
                }
                
                if billingInfo.pastDueAmount ?? 0 > 0 {
                    return .pastDue
                }
                
                if billingInfo.pendingPayments.first?.amount ?? 0 > 0 {
                    return .paymentPending
                }
                
                if billingInfo.scheduledPayment?.amount ?? 0 > 0 {
                    return .paymentScheduled
                }
                
                if opco == .bge && (billingInfo.netDueAmount ?? 0) < 0 {
                    return .credit
                }
                
                if billingInfo.netDueAmount ?? 0 > 0 {
                    if accountDetail.isAutoPay || accountDetail.isBGEasy {
                        return .billReadyAutoPay
                    } else {
                        return .billReady
                    }
                }
                
                if let billDate = billingInfo.billDate,
                    let lastPaymentDate = billingInfo.lastPaymentDate,
                    billingInfo.lastPaymentAmount ?? 0 > 0,
                    billDate < lastPaymentDate {
                    return .billPaid
                }
                
                return .billNotReady
            }
            .asDriver(onErrorDriveWith: .empty())
    
    // MARK: - Show/Hide view logic
    
    private(set) lazy var showHeaderView: Driver<Bool> = self.billState.map {
        switch $0 {
        case .restoreService, .catchUp, .avoidShutoff, .pastDue, .credit:
            return true
        default:
            return AccountsStore.shared.currentAccount.isMultipremise
        }
    }
    
    private(set) lazy var showAlertIcon: Driver<Bool> = self.billState.map { $0.isPrecariousBillSituation }
    
    private(set) lazy var showPaymentPendingIcon: Driver<Bool> = self.billState.map { $0 == .paymentPending }
    
    private(set) lazy var showBillPaidIcon: Driver<Bool> = self.billState.map { $0 == .billPaid || $0 == .billPaidIntermediate }
    
    private(set) lazy var showSlideToPay24DisclaimerLabel: Driver<Bool> = self.billState.map { $0 == .billPaidIntermediate }
    
    private(set) lazy var showAmount: Driver<Bool> = self.billState.map { $0 != .billPaidIntermediate }
    
    private(set) lazy var showConvenienceFee: Driver<Bool> = Driver.combineLatest(self.walletItemDriver,
                                                                                  self.showOneTouchPaySlider,
                                                                                  self.billState,
                                                                                  self.enableOneTouchSlider)
        .map { $0 != nil && $1 && $2 != .credit && !$2.isPrecariousBillSituation && $2 != .paymentScheduled && $2 != .billReadyAutoPay && $3 }
    
    private(set) lazy var showDueDate: Driver<Bool> = self.billState.map {
        switch ($0) {
        case .billPaid, .billPaidIntermediate, .paymentPending:
            return false
        default:
            return true
        }
    }
    
    let showDueDateTooltip = Environment.shared.opco == .peco
    
    private(set) lazy var showReinstatementFeeText: Driver<Bool> = self.reinstatementFeeText.isNil().not()
    
    private(set) lazy var showBankCreditButton: Driver<Bool> = Driver.combineLatest(self.billState,
                                                                          self.walletItemDriver,
                                                                          self.showOneTouchPaySlider,
                                                                          self.enableOneTouchSlider)
        { $0 != .credit && !$0.isPrecariousBillSituation && $0 != .billReadyAutoPay && $1 != nil && $2 && ($3 || $1!.isExpired) }
    
    private(set) lazy var showBankCreditExpiredLabel: Driver<Bool> = self.walletItemDriver.map {
        guard let walletItem = $0 else { return false }
        return walletItem.isExpired
    }
    
    private(set) lazy var showSaveAPaymentAccountButton: Driver<Bool> = Driver.combineLatest(self.billState,
                                                                                   self.walletItemDriver,
                                                                                   self.showOneTouchPaySlider)
        { $0 != .credit && !$0.isPrecariousBillSituation && $0 != .paymentScheduled && $1 == nil && $2 }
    
    private(set) lazy var showMinMaxPaymentAllowed: Driver<Bool> = Driver.combineLatest(self.billState,
                                                                               self.walletItemDriver,
                                                                               self.accountDetailDriver,
                                                                               self.showOneTouchPaySlider,
                                                                               self.minMaxPaymentAllowedText)
    { billState, walletItem, accountDetail, showOneTouchPaySlider, minMaxPaymentAllowedText in
        return billState == .billReady &&
            walletItem != nil &&
            showOneTouchPaySlider &&
            minMaxPaymentAllowedText != nil
    }
    
    private(set) lazy var showOneTouchPaySlider: Driver<Bool> = Driver.combineLatest(self.billState,
                                                                                     self.accountDetailDriver)
        .map { ($0 == .credit || $0 == .billReady) && !$1.isActiveSeverance && !$1.isCashOnly }
    
    private(set) lazy var showCommercialBgeOtpVisaLabel: Driver<Bool> = Driver.combineLatest(self.enableOneTouchSlider, self.accountDetailDriver, self.walletItemDriver).map {
        guard let walletItem = $2 else { return false }
        if !$0 {
            // These first two if statements copy logic from self.enableOneTouchSlider - to ensure that we ONLY show the label if the
            // reason that the slider is disabled is because of the BGE Commercial Visa scenario
            if let minPaymentAmount = $1.billingInfo.minPaymentAmount, $1.billingInfo.netDueAmount ?? 0 < minPaymentAmount && Environment.shared.opco != .bge {
                return false
            } else if $1.billingInfo.netDueAmount ?? 0 < 0 && Environment.shared.opco == .bge {
                return false
            } else if let cardIssuer = walletItem.cardIssuer, cardIssuer == "Visa" && Environment.shared.opco == .bge && !$1.isResidential && !$1.isActiveSeverance && !$1.isCashOnly {
                return true
            }
        }
        return false
    }
    
    private(set) lazy var showScheduledImageView: Driver<Bool> = self.billState.map { $0 == .paymentScheduled }
    
    private(set) lazy var showAutoPayIcon: Driver<Bool> = self.billState.map { $0 == .billReadyAutoPay }
    
    private(set) lazy var showAutomaticPaymentInfoButton: Driver<Bool> = self.billState.map { $0 == .billReadyAutoPay }
    
    private(set) lazy var showScheduledPaymentInfoButton: Driver<Bool> = self.billState.map { $0 == .paymentScheduled }
    
    private(set) lazy var showOneTouchPayTCButton: Driver<Bool> = Driver.combineLatest(self.showOneTouchPaySlider,
                                                                             self.enableOneTouchSlider,
                                                                             self.billState) { $0 && $1 && $2 != .paymentScheduled }
    
    
    // MARK: - View States
    private(set) lazy var titleText: Driver<String?> = Driver.combineLatest(self.billState, self.accountDetailDriver)
    { (billState, accountDetail) in
        
        switch billState {
        case .restoreService:
            return NSLocalizedString("Amount Due to Restore Service", comment: "")
        case .catchUp:
            return NSLocalizedString("Amount Due to Catch Up on Agreement", comment: "")
        case .avoidShutoff:
            switch Environment.shared.opco {
            case .bge:
                if AccountsStore.shared.currentAccount.isMultipremise {
                    return NSLocalizedString("Amount due to avoid shutoff for your multi-premise bill", comment: "")
                } else {
                    return NSLocalizedString("Amount Due to Avoid Service Interruption", comment: "")
                }
            case .comEd, .peco:
                return NSLocalizedString("Amount Due to Avoid Shutoff", comment: "")
            }
        case .pastDue:
            return NSLocalizedString("Amount Past Due", comment: "")
        case .billReady, .billReadyAutoPay, .paymentScheduled:
            if accountDetail.billingInfo.netDueAmount ?? 0 < 0 {
                return NSLocalizedString("No Amount Due - Credit Balance", comment: "")
            } else if Environment.shared.opco == .bge && AccountsStore.shared.currentAccount.isMultipremise {
                return NSLocalizedString("Your multi-premise bill is ready", comment: "")
            } else {
                return NSLocalizedString("Your bill is ready", comment: "")
            }
        case .billPaid, .billPaidIntermediate:
            return NSLocalizedString("Thank you for your payment", comment: "")
        case .credit:
            return NSLocalizedString("No Amount Due - Credit Balance", comment: "")
        case .paymentPending:
            switch Environment.shared.opco {
            case .bge:
                return NSLocalizedString("Your payment is processing", comment: "")
            case .comEd, .peco:
                return NSLocalizedString("Your payment is pending", comment: "")
            }
        case .billNotReady:
            return nil
        }
    }
    
    private(set) lazy var titleA11yText: Driver<String?> = self.titleText.map {
        $0?.replacingOccurrences(of: "shutoff", with: "shut-off")
            .replacingOccurrences(of: "Shutoff", with: "shut-off")
    }
    
    private(set) lazy var showAlertAnimation: Driver<Bool> = self.billState.map {
        return $0.isPrecariousBillSituation
    }
    
    private(set) lazy var resetAlertAnimation: Driver<Void> = Driver.merge(self.refreshFetchTracker.asDriver(),
                                                                           self.switchAccountFetchTracker.asDriver())
        .filter(!)
        .map(to: ())
    
    private(set) lazy var headerText: Driver<NSAttributedString?> = Driver.combineLatest(self.accountDetailDriver, self.billState)
    { accountDetail, billState in
        switch billState {
        case .credit:
            return NSAttributedString(string: NSLocalizedString("Credit Balance", comment: ""),
                                      attributes: [.font: SystemFont.semibold.of(textStyle: .footnote),
                                                   .foregroundColor: UIColor.deepGray])
        case .pastDue:
            return NSAttributedString(string: NSLocalizedString("Your bill is past due", comment: ""),
                                      attributes: [.font: SystemFont.semibold.of(textStyle: .footnote),
                                                   .foregroundColor: UIColor.errorRed])
        case .catchUp:
            guard let amountString = accountDetail.billingInfo.amtDpaReinst?.currencyString,
                let dueByDate = accountDetail.billingInfo.dueByDate else {
                    return nil
            }
            
            let days = dueByDate.interval(ofComponent: .day, fromDate: Calendar.opCo.startOfDay(for: Date()))
            let localizedText = NSLocalizedString("%@ is due in %d day%@ to catch up on your DPA agreement.", comment: "")
            let string = String.localizedStringWithFormat(localizedText, amountString, days, days == 1 ? "": "s")
            return NSAttributedString(string: string,
                                      attributes: [.font: SystemFont.semibold.of(textStyle: .footnote),
                                                   .foregroundColor: UIColor.errorRed])
        case .restoreService:
            guard let amountString = accountDetail.billingInfo.restorationAmount?.currencyString else {
                return nil
            }
            
            let localizedText = NSLocalizedString("%@ is due immediately to restore service.", comment: "")
            let string = String.localizedStringWithFormat(localizedText, amountString)
            return NSAttributedString(string: string,
                                      attributes: [.font: SystemFont.semibold.of(textStyle: .footnote),
                                                   .foregroundColor: UIColor.errorRed])
        case .avoidShutoff:
            guard let amountString = accountDetail.billingInfo.disconnectNoticeArrears?.currencyString else {
                return nil
            }
            
            switch Environment.shared.opco {
            case .bge:
                guard let date = accountDetail.billingInfo.turnOffNoticeExtendedDueDate ??
                    accountDetail.billingInfo.turnOffNoticeDueDate ??
                    accountDetail.billingInfo.dueByDate else {
                        return nil
                }
                let days = date.interval(ofComponent: .day, fromDate: Calendar.opCo.startOfDay(for: Date()))
                let localizedText = NSLocalizedString("%@ is due in %d day%@ to avoid service interruption.", comment: "")
                let string = String.localizedStringWithFormat(localizedText, amountString, days, days == 1 ? "": "s")
                return NSAttributedString(string: string,
                                          attributes: [.font: SystemFont.semibold.of(textStyle: .footnote),
                                                       .foregroundColor: UIColor.errorRed])
            case .comEd, .peco:
                let localizedText = NSLocalizedString("%@ is due immediately to avoid shutoff.", comment: "")
                let string = String.localizedStringWithFormat(localizedText, amountString)
                return NSAttributedString(string: string,
                                          attributes: [.font: SystemFont.semibold.of(textStyle: .footnote),
                                                       .foregroundColor: UIColor.errorRed])
            }
//        case .billPaid:
//            return accountDetail.billingInfo.lastPaymentAmount?.currencyString
//        case .paymentPending:
//            return accountDetail.billingInfo.pendingPayments.last?.amount.currencyString
        default:
            if AccountsStore.shared.currentAccount.isMultipremise {
                return NSAttributedString(string: NSLocalizedString("Multi-Premise Bill", comment: ""),
                                          attributes: [.font: SystemFont.semibold.of(textStyle: .footnote),
                                                       .foregroundColor: UIColor.deepGray])
            }
            return nil
        }
    }
    
    private(set) lazy var amountText: Driver<String?> = Driver.combineLatest(self.accountDetailDriver, self.billState)
    {
        switch $1 {
        case .billPaid:
            return $0.billingInfo.lastPaymentAmount?.currencyString
        case .paymentPending:
            return $0.billingInfo.pendingPayments.last?.amount.currencyString
        default:
            return $0.billingInfo.netDueAmount?.currencyString
        }
    }
    
    private(set) lazy var dueDateText: Driver<NSAttributedString?> = Driver.combineLatest(self.accountDetailDriver, self.billState)
    { accountDetail, billState in
        switch billState {
        case .pastDue:
            return NSAttributedString(string: NSLocalizedString("Amount due immediately", comment: ""),
                                      attributes: [.foregroundColor: UIColor.errorRed,
                                                   .font: OpenSans.semibold.of(textStyle: .subheadline)])
        case .credit:
            return NSAttributedString(string: NSLocalizedString("No amount due", comment: ""),
                                      attributes: [.foregroundColor: UIColor.errorRed,
                                                   .font: OpenSans.semibold.of(textStyle: .subheadline)])
        default:
            if let dueByDate = accountDetail.billingInfo.dueByDate {
                let calendar = Calendar.opCo
                
                let date1 = calendar.startOfDay(for: Date())
                let date2 = calendar.startOfDay(for: dueByDate)
                
                guard let days = calendar.dateComponents([.day], from: date1, to: date2).day else {
                    return nil
                }
                
                if days > 0 {
                    let localizedText = NSLocalizedString("Amount due in %d day%@", comment: "")
                    return NSAttributedString(string: String(format: localizedText, days, days == 1 ? "": "s"),
                                              attributes: [.foregroundColor: UIColor.deepGray,
                                                           .font: OpenSans.regular.of(textStyle: .subheadline)])
                } else {
                    let localizedText = NSLocalizedString("Amount due on %@", comment: "")
                    return NSAttributedString(string: String(format: localizedText, dueByDate.mmDdYyyyString),
                                              attributes: [.foregroundColor: UIColor.deepGray,
                                                           .font: OpenSans.regular.of(textStyle: .subheadline)])
                }
                
            } else {
                return nil
            }
        }
    }
    
    private(set) lazy var reinstatementFeeText: Driver<String?> = self.accountDetailDriver.map {
        guard let reinstateString = $0.billingInfo.atReinstateFee?.currencyString,
            Environment.shared.opco == .comEd &&
                $0.billingInfo.amtDpaReinst ?? 0 > 0 &&
                $0.billingInfo.atReinstateFee ?? 0 > 0 &&
                !$0.isLowIncome else {
                    return nil
        }

        let reinstatementText = NSLocalizedString("You are entitled to one free reinstatement per plan. Any additional reinstatement will incur a %@ fee on your next bill.", comment: "")
        return String(format: reinstatementText, reinstateString)
    }
    
    private(set) lazy var bankCreditCardNumberText: Driver<String?> = self.walletItemDriver.map {
        guard let maskedNumber = $0?.maskedWalletItemAccountNumber else { return nil }
        return "**** " + maskedNumber
    }
    
    private(set) lazy var bankCreditCardImage: Driver<UIImage?> = self.walletItemDriver.map {
        guard let walletItem = $0 else { return nil }
        switch walletItem.bankOrCard {
        case .bank:
            return #imageLiteral(resourceName: "ic_bank")
        case .card:
            return #imageLiteral(resourceName: "ic_creditcard")
        }
    }
    
    private(set) lazy var bankCreditCardButtonAccessibilityLabel: Driver<String?> = self.walletItemDriver.map {
        guard let walletItem = $0,
            let maskedNumber = walletItem.maskedWalletItemAccountNumber else { return nil }
        
        let imageLabel: String
        switch walletItem.bankOrCard {
        case .bank:
            imageLabel = NSLocalizedString("Bank account", comment: "")
        case .card:
            imageLabel = NSLocalizedString("Credit card", comment: "")
        }
        
        return imageLabel + ", " + String(format:NSLocalizedString("Account ending in %@", comment: ""), maskedNumber)
    }
    
    private(set) lazy var minMaxPaymentAllowedText: Driver<String?> = Driver.combineLatest(self.accountDetailDriver, self.walletItemDriver)
    { accountDetail, walletItemOptional in
        guard let walletItem = walletItemOptional else { return nil }
        guard let paymentAmount = accountDetail.billingInfo.netDueAmount else { return nil }
        
        let minPayment: Double
        let maxPayment: Double
        switch walletItem.bankOrCard {
        case .bank:
            minPayment = accountDetail.minPaymentAmount(bankOrCard: .bank)
            maxPayment = accountDetail.maxPaymentAmount(bankOrCard: .bank)
        case .card:
            minPayment = accountDetail.minPaymentAmount(bankOrCard: .card)
            maxPayment = accountDetail.maxPaymentAmount(bankOrCard: .card)
        }
        
        if paymentAmount < minPayment, let amountText = minPayment.currencyString {
            let minLocalizedText = NSLocalizedString("Minimum payment allowed is %@", comment: "")
            return String(format: minLocalizedText, amountText)
        } else if paymentAmount > maxPayment, let amountText = maxPayment.currencyString {
            let maxLocalizedText = NSLocalizedString("Maximum payment allowed is %@", comment: "")
            return String(format: maxLocalizedText, amountText)
        } else {
            return nil
        }
    }
    
    private(set) lazy var convenienceFeeText: Driver<String?> = Driver.combineLatest(self.accountDetailDriver, self.walletItemDriver)
        { accountDetail, walletItem in
            guard let walletItem = walletItem else { return nil }
            
            var localizedText: String? = nil
            var convenienceFeeString: String? = nil
            switch (accountDetail.isResidential, walletItem.bankOrCard, Environment.shared.opco) {
            case (_, .card, .peco):
                localizedText = NSLocalizedString("A %@ convenience fee will be applied by Bill Matrix, our payment partner.", comment: "")
                convenienceFeeString = accountDetail.billingInfo.convenienceFee?.currencyString
            case (_, .card, .comEd):
                localizedText = NSLocalizedString("A %@ convenience fee will be applied by Bill Matrix, our payment partner.", comment: "")
                convenienceFeeString = accountDetail.billingInfo.convenienceFee?.currencyString
            case (true, .card, .bge):
                localizedText = NSLocalizedString("A %@ convenience fee will be applied.", comment: "")
                convenienceFeeString = accountDetail.billingInfo.residentialFee?.currencyString
            case (false, .card, .bge):
                localizedText = NSLocalizedString("A %@ convenience fee will be applied.", comment: "")
                convenienceFeeString = accountDetail.billingInfo.commercialFee?.percentString
            case (_, .bank, _):
                return NSLocalizedString("No fees applied.", comment: "")
            }
            
            guard let text = localizedText, let convenienceFee = convenienceFeeString else { return nil }
            return String(format: text, convenienceFee)
            
    }
    
    private(set) lazy var enableOneTouchSlider: Driver<Bool> = Driver.combineLatest(self.accountDetailDriver, self.walletItemDriver, self.showMinMaxPaymentAllowed)
        { accountDetail, walletItem, showMinMaxPaymentAllowed in
            if showMinMaxPaymentAllowed {
                return false
            }
            if walletItem == nil {
                return false
            }
            if walletItem!.isExpired {
                return false
            }
            if let minPaymentAmount = accountDetail.billingInfo.minPaymentAmount,
                accountDetail.billingInfo.netDueAmount ?? 0 < minPaymentAmount && Environment.shared.opco != .bge {
                return false
            }
            if accountDetail.billingInfo.netDueAmount ?? 0 < 0 && Environment.shared.opco == .bge {
                return false
            }
            if let cardIssuer = walletItem?.cardIssuer, cardIssuer == "Visa", Environment.shared.opco == .bge, !accountDetail.isResidential {
                return false
            }
            return true
        }
    
    private(set) lazy var titleFont: Driver<UIFont> = self.billState
        .map {
            switch $0 {
            case .billReady, .billReadyAutoPay, .billPaid, .billPaidIntermediate, .credit:
                return OpenSans.regular.of(textStyle: .title1)
            case .paymentPending:
                return OpenSans.italic.of(textStyle: .title1)
            default:
                return OpenSans.regular.of(textStyle: .title1)
            }
    }
    
    private(set) lazy var amountFont: Driver<UIFont> = self.billState
        .map { $0 == .paymentPending ? OpenSans.semiboldItalic.of(size: 28): OpenSans.semibold.of(size: 36) }
    
    private(set) lazy var automaticPaymentInfoButtonText: Driver<String?> = self.accountDetailDriver
        .map { accountDetail in
            if Environment.shared.opco == .bge && accountDetail.isBGEasy {
                return NSLocalizedString("You are enrolled in BGEasy", comment: "")
            } else {
                return NSLocalizedString("You are enrolled in AutoPay." , comment: "")
            }
    }
    
    private(set) lazy var thankYouForSchedulingButtonText: Driver<String?> = self.accountDetailDriver.map {
        guard let paymentAmountText = $0.billingInfo.scheduledPayment?.amount.currencyString else { return nil }
        guard let paymentDateText = $0.billingInfo.scheduledPayment?.date?.mmDdYyyyString else { return nil }
        let localizedText = NSLocalizedString("Thank you for scheduling your %@ payment for %@." , comment: "")
        return String(format: localizedText, paymentAmountText, paymentDateText)
    }
    
    private(set) lazy var oneTouchPayTCButtonText: Driver<String?> = self.walletItemDriver.map {
        guard let walletItem = $0 else { return nil }
        switch (Environment.shared.opco, walletItem.bankOrCard) {
        case (.bge, .bank):
            return NSLocalizedString("Payments made on the Home screen cannot be canceled.", comment: "")
        default:
            return NSLocalizedString("Payments made on the Home screen cannot be canceled. By sliding to pay, you agree to these payment Terms & Conditions.", comment: "")
        }
    }
    
    private(set) lazy var enableOneTouchPayTCButton: Driver<Bool> = self.walletItemDriver.map {
        guard let walletItem = $0 else { return false }
        switch (Environment.shared.opco, walletItem.bankOrCard) {
        case (.bge, .bank):
            return false
        default:
            return true
        }
    }
    
    private(set) lazy var oneTouchPayTCButtonTextColor: Driver<UIColor> = self.enableOneTouchPayTCButton.map {
        $0 ? UIColor.actionBlue: UIColor.blackText
    }
    
    private(set) lazy var bankCreditButtonBorderColor: Driver<CGColor> = self.walletItemDriver.map {
        if let walletItem = $0, walletItem.isExpired {
            return UIColor.errorRed.cgColor
        }
        return UIColor.accentGray.cgColor
    }
    
    var paymentTACUrl: URL {
        switch Environment.shared.opco {
        case .bge:
            return URL(string: "https://www.speedpay.com/terms/")!
        case .comEd, .peco:
            return URL(string:"https://webpayments.billmatrix.com/HTML/terms_conditions_en-us.html")!
        }
    }
    
}





