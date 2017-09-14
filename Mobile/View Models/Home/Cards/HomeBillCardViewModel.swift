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
    
    private let account: Observable<Account>
    let accountDetailEvents: Observable<Event<AccountDetail>>
    private let walletService: WalletService
    private let paymentService: PaymentService
    
    let cvv2 = Variable<String?>(nil)
    
    let submitOneTouchPay = PublishSubject<Void>()
    
    private let fetchingTracker: ActivityTracker
    let paymentTracker = ActivityTracker()
    
    required init(withAccount account: Observable<Account>,
                  accountDetailEvents: Observable<Event<AccountDetail>>,
                  walletService: WalletService,
                  paymentService: PaymentService,
                  fetchingTracker: ActivityTracker) {
        self.account = account
        self.accountDetailEvents = accountDetailEvents
        self.walletService = walletService
        self.paymentService = paymentService
        self.fetchingTracker = fetchingTracker
        
        self.oneTouchPayResult
            .withLatestFrom(self.walletItem)
            .unwrap()
            .subscribe(onNext: {
                switch $0.bankOrCard {
                case .bank:
                    Analytics().logScreenView(AnalyticsPageView.OneTouchBankComplete.rawValue)
                case .card:
                    Analytics().logScreenView(AnalyticsPageView.OneTouchCardComplete.rawValue)
                }
            })
            .disposed(by: bag)
    }
    
    private lazy var walletItemEvents: Observable<Event<WalletItem?>> = Observable.merge(self.account.mapTo(()),
                                                                                         RxNotifications.shared.defaultWalletItemUpdated)
        .flatMapLatest { [unowned self] in
            self.walletService.fetchWalletItems()
                .trackActivity(self.fetchingTracker)
                .map { $0.first(where: { $0.isDefault }) }
                .materialize()
        }
        .shareReplay(1)
    
    private(set) lazy var walletItemNoNetworkConnection: Observable<Bool> = self.walletItemEvents.errors()
        .map { ($0 as? ServiceError)?.serviceCode == ServiceErrorCode.NoNetworkConnection.rawValue }
    
    private(set) lazy var workDaysNoNetworkConnection: Observable<Bool> = self.workDayEvents.errors()
        .map { ($0 as? ServiceError)?.serviceCode == ServiceErrorCode.NoNetworkConnection.rawValue }
    
    private lazy var walletItem: Observable<WalletItem?> = self.walletItemEvents.elements()

    private(set) lazy var data: Observable<Event<(Account, AccountDetail, WalletItem?)>> =
        Observable.combineLatest(self.account,
                                 self.accountDetailEvents.elements(),
                                 self.walletItem)
            .materialize()
            .share()
    
    private lazy var workDayEvents: Observable<Event<[Date]>> = self.account
        .flatMapLatest { [unowned self] _ -> Observable<Event<[Date]>> in
            if Environment.sharedInstance.opco == .peco {
                return self.paymentService.fetchWorkdays()
                    .trackActivity(self.fetchingTracker)
                    .materialize()
            } else {
                return Observable<[Date]>.just([]).materialize()
            }
        }
        .shareReplay(1)
    
    private(set) lazy var oneTouchPayResult: Observable<Event<Void>> = self.submitOneTouchPay.asObservable()
        .withLatestFrom(Observable.combineLatest(self.accountDetailEvents.elements(),
                                                 self.walletItem.unwrap(),
                                                 self.cvv2.asObservable(),
                                                 self.shouldShowWeekendWarning.asObservable(),
                                                 self.workDayEvents.elements()))
        .do(onNext: { _, walletItem, _, _, _ in
            switch walletItem.bankOrCard {
            case .bank:
                Analytics().logScreenView(AnalyticsPageView.OneTouchBankOffer.rawValue)
            case .card:
                Analytics().logScreenView(AnalyticsPageView.OneTouchCardOffer.rawValue)
            }
        })
        .map { accountDetail, walletItem, cvv2, isWeekendOrHoliday, workDays in
            let startOfToday = Calendar.opCoTime.startOfDay(for: Date())
            let paymentDate: Date
            if isWeekendOrHoliday, let nextWorkDay = workDays.sorted().first(where: { $0 > Date() }) {
                paymentDate = nextWorkDay
            } else if Environment.sharedInstance.opco == .bge &&
                Calendar.opCoTime.component(.hour, from: Date()) >= 20,
                let tomorrow = Calendar.opCoTime.date(byAdding: .day, value: 1, to: startOfToday) {
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
                           walletId: AccountsStore.sharedInstance.customerIdentifier,
                           walletItemId: walletItem.walletItemID!,
                           cvv: cvv2)
        }
        .flatMapLatest { [unowned self] payment in
            self.paymentService.schedulePayment(payment: payment)
                .do(onNext: {
                    let paymentDetails = PaymentDetails(amount: payment.paymentAmount, date: payment.paymentDate)
                    RecentPaymentsStore.shared[AccountsStore.sharedInstance.currentAccount] = paymentDetails
                })
                .toVoid()
                .trackActivity(self.paymentTracker)
                .materialize()
        }
        .share()
    
    private(set) lazy var shouldShowWeekendWarning: Driver<Bool> = {
        if Environment.sharedInstance.opco == .peco {
            return self.workDayEvents.elements()
                .map { $0.filter(Calendar.opCoTime.isDateInToday).isEmpty }
                .asDriver(onErrorDriveWith: .empty())
        } else {
            return Driver.just(false)
        }
    }()
    
    private(set) lazy var promptForCVV: Driver<Bool> = {
        if Environment.sharedInstance.opco != .bge {
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
        .map { 3...4 ~= ($0?.characters.count ?? 0) }
    
    //MARK: - Loaded States
    
    private lazy var accountDetailDriver: Driver<AccountDetail> = self.accountDetailEvents.elements().asDriver(onErrorDriveWith: .empty())
    private lazy var walletItemDriver: Driver<WalletItem?> = self.walletItem.asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var billNotReady: Driver<Bool> = self.billState.map { $0 == .billNotReady }
        .asDriver(onErrorJustReturn: false)
    
    private(set) lazy var showErrorState: Driver<Bool> = {
        if Environment.sharedInstance.opco == .peco {
            return Observable.combineLatest(self.accountDetailEvents, self.walletItemEvents, self.workDayEvents)
                .map { $0.0.error != nil || $0.1.error != nil || $0.2.error != nil }
                .asDriver(onErrorDriveWith: .empty())
        } else {
            return Observable.combineLatest(self.accountDetailEvents, self.walletItemEvents)
                .map { $0.0.error != nil || $0.1.error != nil }
                .asDriver(onErrorDriveWith: .empty())
        }
        
    }()
    
    private(set) lazy var showInfoStack: Driver<Bool> = Driver.combineLatest(self.billNotReady, self.showErrorState) { $0 || $1 }
    
    // MARK: - Title States
    
    enum BillState {
        case restoreService, catchUp, avoidShutoff, pastDueTotal,
        pastDueNotTotal, billReady, billReadyAutoPay, billPaid, billPaidIntermediate, credit,
        paymentPending, billNotReady, paymentScheduled
        
        var isPrecariousBillSituation: Bool {
            switch self {
            case .restoreService, .catchUp, .avoidShutoff, .pastDueTotal, .pastDueNotTotal:
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
            .map { account, accountDetail, walletItem -> BillState in
                let billingInfo = accountDetail.billingInfo
                let opco = Environment.sharedInstance.opco
                
                if RecentPaymentsStore.shared[account] != nil {
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
                    if billingInfo.netDueAmount == billingInfo.pastDueAmount {
                        return .pastDueTotal
                    } else {
                        return .pastDueNotTotal
                    }
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
    private(set) lazy var showAlertIcon: Driver<Bool> = self.billState.map { $0.isPrecariousBillSituation }
    
    private(set) lazy var showPaymentPendingIcon: Driver<Bool> = self.billState.map { $0 == .paymentPending }
    
    private(set) lazy var showBillPaidIcon: Driver<Bool> = self.billState.map { $0 == .billPaid || $0 == .billPaidIntermediate }
    
    private(set) lazy var showAmount: Driver<Bool> = self.billState.map { $0 != .billPaidIntermediate }
    
    private(set) lazy var showConvenienceFee: Driver<Bool> = Driver.combineLatest(self.walletItemDriver,
                                                                                  self.showOneTouchPaySlider,
                                                                                  self.billState,
                                                                                  self.enableOneTouchSlider)
        .map { $0 != nil && $1 && $2 != .credit && !$2.isPrecariousBillSituation && $2 != .paymentScheduled && $2 != .billReadyAutoPay && $3 }
    
    private(set) lazy var showDueDate: Driver<Bool> = Driver.combineLatest(self.billState, self.accountDetailDriver)
    {
        switch ($0) {
        case .billPaid, .billPaidIntermediate, .credit, .paymentPending:
            return false
        default:
            return $1.billingInfo.netDueAmount ?? 0 >= 0 // don't show for credit balances
        }
    }
    
    private(set) lazy var showDueAmountAndDate: Driver<Bool> = self.billState.map {
        switch $0 {
        case .avoidShutoff, .pastDueNotTotal, .catchUp, .restoreService:
            return true
        default:
            return false
        }
    }
    
    private(set) lazy var showDueDateTooltip: Driver<Bool> = Driver.zip(self.showDueAmountAndDate, self.billState)
    { !$0 && !$1.isPrecariousBillSituation && Environment.sharedInstance.opco == .peco }
    
    let showDueAmountAndDateTooltip = Environment.sharedInstance.opco == .peco
    
    private(set) lazy var showBankCreditButton: Driver<Bool> = Driver.combineLatest(self.billState,
                                                                          self.walletItemDriver,
                                                                          self.showOneTouchPaySlider,
                                                                          self.enableOneTouchSlider)
        { $0 != .credit && !$0.isPrecariousBillSituation && $0 != .billReadyAutoPay && $1 != nil && $2 && $3 }
    
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
            Environment.sharedInstance.opco != .bge &&
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
            if let minPaymentAmount = $1.billingInfo.minPaymentAmount, $1.billingInfo.netDueAmount ?? 0 < minPaymentAmount && Environment.sharedInstance.opco != .bge {
                return false
            } else if $1.billingInfo.netDueAmount ?? 0 < 0 && Environment.sharedInstance.opco == .bge {
                return false
            } else if let cardIssuer = walletItem.cardIssuer, cardIssuer == "Visa", Environment.sharedInstance.opco == .bge, !$1.isResidential {
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
    private(set) lazy var titleText: Driver<String?> = Driver.combineLatest(self.billState, self.data.elements().asDriver(onErrorDriveWith: .empty()))
    { (billState, data) in
        let (account, accountDetail, _) = data
        
        switch billState {
        case .restoreService:
            return NSLocalizedString("Amount Due to Restore Service", comment: "")
        case .catchUp:
            return NSLocalizedString("Amount Due to Catch Up on Agreement", comment: "")
        case .avoidShutoff:
            switch Environment.sharedInstance.opco {
            case .bge:
                if account.isMultipremise {
                    return NSLocalizedString("Amount due to avoid shutoff for your multi-premise bill", comment: "")
                } else {
                    return NSLocalizedString("Amount Due to Avoid Service Interruption", comment: "")
                }
            case .comEd, .peco:
                return NSLocalizedString("Amount Due to Avoid Shutoff", comment: "")
            }
        case .pastDueTotal, .pastDueNotTotal:
            return NSLocalizedString("Amount Past Due", comment: "")
        case .billReady, .billReadyAutoPay, .paymentScheduled:
            if accountDetail.billingInfo.netDueAmount ?? 0 < 0 {
                return NSLocalizedString("No Amount Due - Credit Balance", comment: "")
            } else if Environment.sharedInstance.opco == .bge && account.isMultipremise {
                return NSLocalizedString("Your multi-premise bill is ready", comment: "")
            } else {
                return NSLocalizedString("Your bill is ready", comment: "")
            }
        case .billPaid, .billPaidIntermediate:
            return NSLocalizedString("Thank you for your payment", comment: "")
        case .credit:
            return NSLocalizedString("No Amount Due - Credit Balance", comment: "")
        case .paymentPending:
            switch Environment.sharedInstance.opco {
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
    
    private(set) lazy var amountText: Driver<String?> = Driver.combineLatest(self.accountDetailDriver, self.billState)
    {
        switch $1 {
        case .pastDueNotTotal:
            return $0.billingInfo.pastDueAmount?.currencyString
        case .catchUp:
            return $0.billingInfo.amtDpaReinst?.currencyString
        case .restoreService:
            return $0.billingInfo.restorationAmount?.currencyString
        case .avoidShutoff:
            return $0.billingInfo.disconnectNoticeArrears?.currencyString
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
        if billState.isPrecariousBillSituation {
            if Environment.sharedInstance.opco == .bge &&
                accountDetail.billingInfo.disconnectNoticeArrears ?? 0 > 0 &&
                accountDetail.billingInfo.isDisconnectNotice,
                let extensionDate = accountDetail.billingInfo.dueByDate {
                
                let calendar = Calendar.opCoTime
                
                let date1 = calendar.startOfDay(for: Date())
                let date2 = calendar.startOfDay(for: extensionDate)
                
                guard let days = calendar.dateComponents([.day], from: date1, to: date2).day else {
                    return nil
                }
                
                if days > 0 {
                    let localizedText = NSLocalizedString("Due in %d day%@", comment: "")
                    return NSAttributedString(string: String(format: localizedText, days, days == 1 ? "": "s"),
                                              attributes: [NSForegroundColorAttributeName: UIColor.deepGray,
                                                           NSFontAttributeName: SystemFont.regular.of(textStyle: .subheadline)])
                } else {
                    let localizedText = NSLocalizedString("Due on %@", comment: "")
                    return NSAttributedString(string: String(format: localizedText, extensionDate.mmDdYyyyString),
                                              attributes: [NSForegroundColorAttributeName: UIColor.deepGray,
                                                           NSFontAttributeName: SystemFont.regular.of(textStyle: .subheadline)])
                }
            } else {
                return NSAttributedString(string: NSLocalizedString("Due Immediately", comment: ""),
                                          attributes: [NSForegroundColorAttributeName: UIColor.errorRed,
                                                       NSFontAttributeName: SystemFont.regular.of(textStyle: .subheadline)])
            }
        } else if let dueByDate = accountDetail.billingInfo.dueByDate {
            let calendar = Calendar.opCoTime
            
            let date1 = calendar.startOfDay(for: Date())
            let date2 = calendar.startOfDay(for: dueByDate)
            
            guard let days = calendar.dateComponents([.day], from: date1, to: date2).day else {
                return nil
            }
            
            if days > 0 {
                let localizedText = NSLocalizedString("Due in %d day%@", comment: "")
                return NSAttributedString(string: String(format: localizedText, days, days == 1 ? "": "s"),
                                          attributes: [NSForegroundColorAttributeName: UIColor.deepGray,
                                                       NSFontAttributeName: SystemFont.regular.of(textStyle: .subheadline)])
            } else {
                let localizedText = NSLocalizedString("Due on %@", comment: "")
                return NSAttributedString(string: String(format: localizedText, dueByDate.mmDdYyyyString),
                                          attributes: [NSForegroundColorAttributeName: UIColor.deepGray,
                                                       NSFontAttributeName: SystemFont.regular.of(textStyle: .subheadline)])
            }
            
        } else {
            return nil
        }
    }
    
    func getDueInOnText(dueByDate: Date) -> NSAttributedString? {
        let calendar = Calendar.opCoTime
        
        let date1 = calendar.startOfDay(for: Date())
        let date2 = calendar.startOfDay(for: dueByDate)
        
        guard let days = calendar.dateComponents([.day], from: date1, to: date2).day else {
            return nil
        }
        
        if days > 0 {
            let localizedText = NSLocalizedString("Due in %d day%@", comment: "")
            return NSAttributedString(string: String(format: localizedText, days, days == 1 ? "": "s"),
                                      attributes: [NSForegroundColorAttributeName: UIColor.deepGray,
                                                   NSFontAttributeName: SystemFont.regular.of(textStyle: .subheadline)])
        } else {
            let localizedText = NSLocalizedString("Due on %@", comment: "")
            return NSAttributedString(string: String(format: localizedText, dueByDate.mmDdYyyyString),
                                      attributes: [NSForegroundColorAttributeName: UIColor.deepGray,
                                                   NSFontAttributeName: SystemFont.regular.of(textStyle: .subheadline)])
        }
    }
    
    private(set) lazy var dueAmountAndDateText: Driver<String?> = self.accountDetailDriver.map {
        guard let amountDueString = $0.billingInfo.netDueAmount?.currencyString else { return nil }
        guard let dueByDate = $0.billingInfo.dueByDate else { return nil }
        
        let calendar = Calendar.opCoTime
        let date1 = calendar.startOfDay(for: Date())
        let date2 = calendar.startOfDay(for: dueByDate)
        guard let days = calendar.dateComponents([.day], from: date1, to: date2).day else { return nil }
        
        if days > 0 {
            let localizedText = NSLocalizedString("Your bill total of %@ is due in %d day%@.", comment: "")
            return String(format: localizedText, amountDueString, days, days == 1 ? "": "s")
        } else if $0.billingInfo.pastDueAmount == nil {
            let localizedText = NSLocalizedString("Your bill total of %@ is due %@.", comment: "")
            return String(format: localizedText, amountDueString, dueByDate.mmDdYyyyString)
        } else {
            let localizedText = NSLocalizedString("Your bill total of %@ is due immediately.", comment: "")
            return String(format: localizedText, amountDueString)
        }
        
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
        switch (walletItem.bankOrCard, Environment.sharedInstance.opco) {
        case (.bank, .bge):
            minPayment = accountDetail.billingInfo.minPaymentAmountACH ?? 0
            maxPayment = accountDetail.billingInfo.maxPaymentAmountACH ?? (accountDetail.isResidential ? 9999.99 : 99999.99)
        case (.bank, _):
            minPayment = accountDetail.billingInfo.minPaymentAmountACH ?? 5
            maxPayment = accountDetail.billingInfo.maxPaymentAmountACH ?? 90000
        case (.card, .bge):
            minPayment = accountDetail.billingInfo.minPaymentAmount ?? 0
            maxPayment = accountDetail.billingInfo.maxPaymentAmount ?? (accountDetail.isResidential ? 600 : 25000)
        case (.card, _):
            minPayment = accountDetail.billingInfo.minPaymentAmount ?? 5
            maxPayment = accountDetail.billingInfo.maxPaymentAmount ?? 5000
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
            switch (accountDetail.isResidential, walletItem.bankOrCard, Environment.sharedInstance.opco) {
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
            default:
                break
            }
            
            guard let text = localizedText, let convenienceFee = convenienceFeeString else { return nil }
            return String(format: text, convenienceFee)
            
    }
    
    private(set) lazy var enableOneTouchSlider: Driver<Bool> = Driver.combineLatest(self.accountDetailDriver, self.walletItemDriver, self.showMinMaxPaymentAllowed)
        { accountDetail, walletItem, showMinMaxPaymentAllowed in
            if showMinMaxPaymentAllowed {
                return false
            } else if walletItem == nil {
                return false
            } else if let minPaymentAmount = accountDetail.billingInfo.minPaymentAmount,
                accountDetail.billingInfo.netDueAmount ?? 0 < minPaymentAmount && Environment.sharedInstance.opco != .bge {
                return false
            } else if accountDetail.billingInfo.netDueAmount ?? 0 < 0 && Environment.sharedInstance.opco == .bge {
                return false
            } else if let cardIssuer = walletItem?.cardIssuer, cardIssuer == "Visa", Environment.sharedInstance.opco == .bge, !accountDetail.isResidential {
                return false
            } else {
                return true
            }
        }
    
    private(set) lazy var titleFont: Driver<UIFont> = self.billState
        .map {
            switch $0 {
            case .restoreService, .catchUp, .avoidShutoff, .pastDueTotal, .pastDueNotTotal:
                return OpenSans.regular.of(textStyle: .headline)
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
            if Environment.sharedInstance.opco == .bge && accountDetail.isBGEasy {
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
        switch (Environment.sharedInstance.opco, walletItem.bankOrCard) {
        case (.bge, .bank):
            return NSLocalizedString("Payments made on the Home screen cannot be canceled.", comment: "")
        default:
            return NSLocalizedString("Payments made on the Home screen cannot be canceled. By sliding to pay, you agree to these payment Terms & Conditions.", comment: "")
        }
    }
    
    private(set) lazy var enableOneTouchPayTCButton: Driver<Bool> = self.walletItemDriver.map {
        guard let walletItem = $0 else { return false }
        switch (Environment.sharedInstance.opco, walletItem.bankOrCard) {
        case (.bge, .bank):
            return false
        default:
            return true
        }
    }
    
    private(set) lazy var oneTouchPayTCButtonTextColor: Driver<UIColor> = self.enableOneTouchPayTCButton.map {
        $0 ? UIColor.actionBlue: UIColor.blackText
    }
    
    var paymentTACUrl: URL {
        switch Environment.sharedInstance.opco {
        case .bge:
            return URL(string: "https://www.speedpay.com/terms/")!
        case .comEd, .peco:
            return URL(string:"https://webpayments.billmatrix.com/HTML/terms_conditions_en-us.html")!
        }
    }
}





