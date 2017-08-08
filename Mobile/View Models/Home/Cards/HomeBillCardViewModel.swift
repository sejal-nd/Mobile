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
    private let accountDetailElements: Observable<AccountDetail>
    private let accountDetailErrors: Observable<Error>
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
        self.accountDetailElements = accountDetailEvents.elements()
        self.accountDetailErrors = accountDetailEvents.errors()
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
    
    private lazy var walletItemEvents: Observable<Event<WalletItem?>> = self.account
        .flatMapLatest { [unowned self] _ in
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
                                 self.accountDetailElements,
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
                return Observable<Event<[Date]>>.never()
            }
        }
        .shareReplay(1)
    
    private(set) lazy var oneTouchPayResult: Observable<Event<Void>> = self.submitOneTouchPay.asObservable()
        .withLatestFrom(Observable.combineLatest(self.accountDetailElements, self.walletItem.unwrap(), self.cvv2.asObservable()))
        .do(onNext: { _, walletItem, _ in
            switch walletItem.bankOrCard {
            case .bank:
                Analytics().logScreenView(AnalyticsPageView.OneTouchBankComplete.rawValue, dimensionIndex: nil, dimensionValue: nil)
            case .card:
                Analytics().logScreenView(AnalyticsPageView.OneTouchCardComplete.rawValue, dimensionIndex: nil, dimensionValue: nil)
            }
        })
        .map { accountDetail, walletItem, cvv2 in
            Payment(accountNumber: accountDetail.accountNumber,
                    existingAccount: true,
                    saveAccount: true,
                    maskedWalletAccountNumber: walletItem.maskedWalletItemAccountNumber!,
                    paymentAmount: accountDetail.billingInfo.netDueAmount!,
                    paymentType: (walletItem.paymentCategoryType == .check) ? .check : .credit,
                    paymentDate: Date(),
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
                .map { _ in () }
                .trackActivity(self.paymentTracker)
                .materialize()
    }
    
    private(set) lazy var shouldShowWeekendWarning: Driver<Bool> = {
        if Environment.sharedInstance.opco == .peco {
            return self.workDayEvents.elements()
                .map { $0.filter(NSCalendar.current.isDateInToday).isEmpty }
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
    
    //MARK: - Loaded States
    
    private lazy var accountDetailDriver: Driver<AccountDetail> = self.accountDetailElements.asDriver(onErrorDriveWith: .empty())
    private lazy var walletItemDriver: Driver<WalletItem?> = self.walletItem.asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var billNotReady: Driver<Bool> = self.accountDetailDriver
        .map { ($0.billingInfo.netDueAmount ?? 0) == 0 && ($0.billingInfo.lastPaymentAmount ?? 0) <= 0 }
    
    private(set) lazy var showErrorState: Driver<Bool> = Observable.combineLatest(self.accountDetailEvents, self.walletItemEvents)
        .map { $0.0.error != nil || $0.1.error != nil }
        .asDriver(onErrorDriveWith: .empty())
    
    // MARK: - Title States
    
    enum TitleState {
        case restoreService, catchUp, avoidShutoff, avoidShutoffBGEMultipremise, pastDueTotal,
        pastDueNotTotal, billReady, billPaid, billPaidIntermediate, credit, multipremiseReady, paymentPending
    }
    
    private lazy var isPrecariousBillSituation: Driver<Bool> = self.titleState.map {
        switch $0 {
        case .restoreService, .catchUp, .avoidShutoff, .avoidShutoffBGEMultipremise, .pastDueTotal, .pastDueNotTotal:
            return true
        default:
            return false
        }
    }
    
    private lazy var titleState: Driver<TitleState> =
        self.data.elements()
            .map { account, accountDetail, walletItem -> TitleState in
                let billingInfo = accountDetail.billingInfo
                let opco = Environment.sharedInstance.opco
                
                if RecentPaymentsStore.shared[account] != nil {
                    return .billPaidIntermediate
                }
                
                if opco != .bge && (billingInfo.restorationAmount ?? 0) > 0 {
                    return .restoreService
                }
                
                if (billingInfo.disconnectNoticeArrears ?? 0) > 0 && billingInfo.isDisconnectNotice {
                    if opco == .bge && account.isMultipremise {
                        return .avoidShutoffBGEMultipremise
                    }
                    return .avoidShutoff
                }
                
                if opco != .bge && (billingInfo.amtDpaReinst ?? 0 > 0) {
                    return .catchUp
                }
                
                if let pastDueAmount = billingInfo.pastDueAmount,
                    pastDueAmount > 0,
                    let dueByDate = billingInfo.dueByDate {
                    if billingInfo.netDueAmount == pastDueAmount {
                        return .pastDueTotal
                    } else {
                        return .pastDueNotTotal
                    }
                }
                
                if opco == .bge && (billingInfo.netDueAmount ?? 0) < 0 {
                    return .credit
                }
                
                if billingInfo.pendingPayments.first?.amount ?? 0 > 0 {
                    return .paymentPending
                }
                
                if (billingInfo.netDueAmount ?? 0) == 0, let lastPaymentAmount = billingInfo.lastPaymentAmount {
                    return .billPaid
                }
                
                if opco == .bge && account.isMultipremise {
                    return .multipremiseReady
                }
                
                return .billReady
            }
            .asDriver(onErrorDriveWith: .empty())
    
    // MARK: - Show/Hide view logic
    private(set) lazy var showAlertIcon: Driver<Bool> = self.titleState
        .map {
            switch $0 {
            case .restoreService, .catchUp, .avoidShutoff, .avoidShutoffBGEMultipremise, .pastDueTotal, .pastDueNotTotal:
                return true
            default:
                return false
            }
    }
    
    private lazy var billPaidOrPending: Driver<Bool> = self.titleState.map {
        switch $0 {
        case .billPaid, .paymentPending, .billPaidIntermediate:
            return true
        default:
            return false
        }
    }
    
    private lazy var showAutoPay: Driver<Bool> = Driver.combineLatest(self.isPrecariousBillSituation, self.accountDetailDriver, self.billPaidOrPending)
        .map { !$0 && $1.isAutoPay && !$2 }
    
    private(set) lazy var showPaymentPendingIcon: Driver<Bool> = self.titleState.map { $0 == .paymentPending }
    
    private(set) lazy var showBillPaidIcon: Driver<Bool> = self.titleState.map { $0 == .billPaid || $0 == .billPaidIntermediate }
    
    private(set) lazy var showAmount: Driver<Bool> = self.titleState.map { $0 != .billPaidIntermediate }
    
    private(set) lazy var showConvenienceFee: Driver<Bool> = Driver.combineLatest(self.isPrecariousBillSituation,
                                                                                  self.showAutoPay,
                                                                                  self.walletItemDriver,
                                                                                  self.showScheduledImageView,
                                                                                  self.showOneTouchPaySlider)
        .map { !$0 && !$1 && $2 != nil && !$3 && $4 }
    
    private(set) lazy var showDueDate: Driver<Bool> = self.titleState.map {
        switch $0 {
        case .billPaid, .billPaidIntermediate, .credit, .paymentPending:
            return false
        default:
            return true
        }
    }
    
    private(set) lazy var showDueDateTooltip: Driver<Bool> = self.showDueAmountAndDate.map {
        !$0 && Environment.sharedInstance.opco == .peco
    }
    
    private(set) lazy var showDueAmountAndDate: Driver<Bool> = self.titleState.map {
        switch $0 {
        case .avoidShutoff, .pastDueNotTotal, .catchUp, .avoidShutoffBGEMultipremise, .restoreService:
            return true
        default:
            return false
        }
    }
    
    let showDueAmountAndDateTooltip = Environment.sharedInstance.opco == .peco
    
    private(set) lazy var showBankCreditButton: Driver<Bool> = Driver.combineLatest(self.titleState,
                                                                          self.isPrecariousBillSituation,
                                                                          self.walletItemDriver,
                                                                          self.showScheduledImageView,
                                                                          self.showAutoPay,
                                                                          self.showOneTouchPaySlider)
        .map { $0 != .credit && !$1 && $2 != nil && !$3 && !$4 && $5 }
    
    private(set) lazy var showSaveAPaymentAccountButton: Driver<Bool> = Driver.combineLatest(self.titleState,
                                                                                   self.isPrecariousBillSituation,
                                                                                   self.walletItemDriver,
                                                                                   self.showOneTouchPaySlider)
        .map { $0 != .credit && !$1 && $2 == nil && $3 }
    
    private(set) lazy var showMinimumPaymentAllowed: Driver<Bool> = Driver.combineLatest(self.titleState,
                                                                               self.isPrecariousBillSituation,
                                                                               self.walletItemDriver,
                                                                               self.accountDetailDriver,
                                                                               self.showOneTouchPaySlider)
    { titleState, isPrecariousBillSituation, walletItem, accountDetail, showOneTouchPaySlider in
        guard let minPaymentAmount = accountDetail.billingInfo.minPaymentAmount else { return false }
        return titleState != .credit &&
            !isPrecariousBillSituation &&
            walletItem != nil &&
            (accountDetail.billingInfo.netDueAmount ?? 0) < minPaymentAmount &&
            Environment.sharedInstance.opco != .bge &&
            showOneTouchPaySlider
    }
    
    private(set) lazy var showOneTouchPaySlider: Driver<Bool> = Driver.combineLatest(self.isPrecariousBillSituation,
                                                                                     self.showAutoPay,
                                                                                     self.showScheduledImageView,
                                                                                     self.accountDetailDriver,
                                                                                     self.billPaidOrPending)
        .map { !$0 && !$1 && !$2 && !$3.isActiveSeverance && !$3.isCashOnly && !$4 }
    
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
    
    
    private(set) lazy var showScheduledImageView: Driver<Bool> = {
        let currentDate = Date()
        let isScheduled = self.accountDetailDriver
            .map { ($0.billingInfo.scheduledPayment?.amount ?? 0) > 0 &&
                $0.billingInfo.scheduledPayment?.date ?? currentDate > currentDate &&
                ($0.billingInfo.pendingPayments.first?.amount ?? 0) == 0 }
        return Driver.combineLatest(isScheduled, self.showAutoPay, self.isPrecariousBillSituation) { $0 && !$1 && !$2 }
    } ()
    
    private(set) lazy var showAutoPayIcon: Driver<Bool> = self.showAutoPay
    
    private(set) lazy var showAutomaticPaymentInfoButton: Driver<Bool> = self.showAutoPay
    
    private(set) lazy var showScheduledPaymentInfoButton: Driver<Bool> = self.showScheduledImageView
    
    private(set) lazy var showOneTouchPayTCButton: Driver<Bool> = Driver.combineLatest(self.showOneTouchPaySlider,
                                                                             self.enableOneTouchSlider,
                                                                             self.showScheduledImageView) { $0 && $1 && !$2 }
    
    
    // MARK: - View States
    private(set) lazy var titleText: Driver<String?> = self.titleState
        .map {
            switch $0 {
            case .restoreService:
                return NSLocalizedString("Amount Due to Restore Service", comment: "")
            case .catchUp:
                return NSLocalizedString("Amount Due to Catch Up on Agreement", comment: "")
            case .avoidShutoff:
                switch Environment.sharedInstance.opco {
                case .bge:
                    return NSLocalizedString("Amount Due to Avoid Service Interruption", comment: "")
                case .comEd, .peco:
                    return NSLocalizedString("Amount Due to Avoid Shutoff", comment: "")
                }
            case .avoidShutoffBGEMultipremise:
                return NSLocalizedString("Amount due to avoid shutoff for your multi-premise bill", comment: "")
            case .pastDueTotal, .pastDueNotTotal:
                return NSLocalizedString("Amount Past Due", comment: "")
            case .billReady:
                return NSLocalizedString("Your bill is ready", comment: "")
            case .billPaid, .billPaidIntermediate:
                return NSLocalizedString("Thank you for your payment", comment: "")
            case .credit:
                return NSLocalizedString("No Amount Due - Credit Balance", comment: "")
            case .multipremiseReady:
                return NSLocalizedString("Your multi-premise bill is ready", comment: "")
            case .paymentPending:
                switch Environment.sharedInstance.opco {
                case .bge:
                    return NSLocalizedString("Your payment is processing", comment: "")
                case .comEd, .peco:
                    return NSLocalizedString("Your payment is pending", comment: "")
                }
            }
    }
    
    private(set) lazy var titleA11yText: Driver<String?> = self.titleText.map {
        $0?.replacingOccurrences(of: "shutoff", with: "shut-off")
            .replacingOccurrences(of: "Shutoff", with: "shut-off")
    }
    
    private(set) lazy var amountText: Driver<String?> = Driver.combineLatest(self.accountDetailDriver, self.titleState)
        .map {
            switch $1 {
            case .pastDueNotTotal:
                return $0.billingInfo.pastDueAmount?.currencyString
            case .catchUp:
                return $0.billingInfo.amtDpaReinst?.currencyString
            case .restoreService:
                return $0.billingInfo.restorationAmount?.currencyString
            case .avoidShutoff, .avoidShutoffBGEMultipremise:
                return $0.billingInfo.disconnectNoticeArrears?.currencyString
            case .billPaid:
                return $0.billingInfo.lastPaymentAmount?.currencyString
            default:
                return $0.billingInfo.netDueAmount?.currencyString
            }
    }
    
    private(set) lazy var dueDateText: Driver<NSAttributedString?> = self.accountDetailDriver.map {
        if $0.billingInfo.pastDueAmount ?? 0 > 0 {
            return NSAttributedString(string: NSLocalizedString("Due Immediately", comment: ""),
                                      attributes: [NSForegroundColorAttributeName: UIColor.errorRed,
                                                   NSFontAttributeName: SystemFont.regular.of(textStyle: .subheadline)])
        } else if let dueByDate = $0.billingInfo.dueByDate {
            let calendar = NSCalendar.current
            
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
    
    private(set) lazy var dueAmountAndDateText: Driver<String?> = self.accountDetailDriver.map {
        guard let amountDueString = $0.billingInfo.netDueAmount?.currencyString else { return nil }
        guard let dueByDate = $0.billingInfo.dueByDate else { return nil }
        
        let calendar = NSCalendar.current
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
    
    private(set) lazy var bankCreditCardImageAccessibilityLabel: Driver<String?> = self.walletItemDriver.map {
        guard let walletItem = $0 else { return nil }
        switch walletItem.bankOrCard {
        case .bank:
            return NSLocalizedString("Bank account", comment: "")
        case .card:
            return NSLocalizedString("Credit card", comment: "")
        }
    }
    
    private(set) lazy var minPaymentAllowedText: Driver<String?> = self.accountDetailDriver.map {
        guard let minPaymentAmountText = $0.billingInfo.minPaymentAmount?.currencyString else { return nil }
        let localizedText = NSLocalizedString("Minimum payment allowed is %@.", comment: "")
        return String(format: localizedText, minPaymentAmountText)
    }
    
    private(set) lazy var convenienceFeeText: Driver<String?> = Driver.combineLatest(self.accountDetailDriver, self.walletItemDriver)
        .map { accountDetail, walletItem in
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
                localizedText = NSLocalizedString("A %@ convenience fee will be applied by Western Union Speedpay, our payment partner.", comment: "")
                convenienceFeeString = accountDetail.billingInfo.residentialFee?.currencyString
            case (false, .card, .bge):
                localizedText = NSLocalizedString("A %@ convenience fee will be applied by Western Union Speedpay, our payment partner.", comment: "")
                convenienceFeeString = accountDetail.billingInfo.commercialFee?.percentString
            case (_, .bank, _):
                return NSLocalizedString("No fees applied.", comment: "")
            default:
                break
            }
            
            guard let text = localizedText, let convenienceFee = convenienceFeeString else { return nil }
            return String(format: text, convenienceFee)
            
    }
    
    private(set) lazy var enableOneTouchSlider: Driver<Bool> = Driver.combineLatest(self.accountDetailDriver, self.walletItemDriver)
        .map { accountDetail, walletItem in
            if walletItem == nil {
                return false
            } else if let minPaymentAmount = accountDetail.billingInfo.minPaymentAmount,
                accountDetail.billingInfo.netDueAmount ?? 0 < minPaymentAmount && Environment.sharedInstance.opco != .bge {
                return false
            } else if accountDetail.billingInfo.netDueAmount ?? 0 < 0 && Environment.sharedInstance.opco == .bge {
                return false
            } else if let cardIssuer = walletItem!.cardIssuer, cardIssuer == "Visa", Environment.sharedInstance.opco == .bge, !accountDetail.isResidential {
                return false
            } else {
                return true
            }
        }
    
    private(set) lazy var titleFont: Driver<UIFont> = self.titleState
        .map {
            switch $0 {
            case .restoreService, .catchUp, .avoidShutoff, .avoidShutoffBGEMultipremise, .pastDueTotal, .pastDueNotTotal:
                return OpenSans.regular.of(textStyle: .headline)
            case .billReady, .billPaid, .billPaidIntermediate, .credit, .multipremiseReady:
                return OpenSans.regular.of(textStyle: .title1)
            case .paymentPending:
                return OpenSans.italic.of(textStyle: .title1)
            }
    }
    
    private(set) lazy var amountFont: Driver<UIFont> = self.titleState
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
        guard let paymentDateText = $0.billingInfo.scheduledPayment?.date.mmDdYyyyString else { return nil }
        let localizedText = NSLocalizedString("Thank you for scheduling your %@ payment for %@." , comment: "")
        return String(format: localizedText, paymentAmountText, paymentDateText)
    }
    
    private(set) lazy var oneTouchPayTCButtonText: Driver<String?> = self.walletItemDriver.map {
        guard let walletItem = $0 else { return nil }
        switch (Environment.sharedInstance.opco, walletItem.bankOrCard) {
        case (.bge, .bank):
            return NSLocalizedString("One Touch Pay cannot be canceled." , comment: "")
        default:
            return NSLocalizedString("Payments made using One Touch Pay cannot be canceled. By using One Touch Pay, you agree to the payment Terms & Conditions." , comment: "")
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
            return URL(string: "https://www.speedpay.com/westernuniontac_cf.asp")!
        case .comEd, .peco:
            return URL(string:"https://webpayments.billmatrix.com/HTML/terms_conditions_en-us.html")!
        }
    }
}





