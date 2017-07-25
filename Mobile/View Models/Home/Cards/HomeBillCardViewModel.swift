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
    
    enum BillCardState {
        case error, avoidShutoff, autoPay, pastDue, due, noBill, credit, payment, paymentPending
    }
    
    let bag = DisposeBag()
    
    private let account: Observable<Account>
    private let accountDetailEvents: Observable<Event<AccountDetail>>
    private let accountDetailElements: Observable<AccountDetail>
    private let accountDetailErrors: Observable<Error>
    private let walletService: WalletService
    private let paymentService: PaymentService
    
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
    }
    
    private lazy var walletItemEvents: Observable<Event<WalletItem?>> = self.account.map { _ in () }
        .flatMapLatest(self.fetchOTPWalletItem)
        .shareReplay(1)
    
    private(set) lazy var walletItemNoNetworkConnection: Observable<Bool> = self.walletItemEvents
        .map { ($0.error as? ServiceError)?.serviceCode == ServiceErrorCode.NoNetworkConnection.rawValue }
    
    private(set) lazy var workDaysNoNetworkConnection: Observable<Bool> = self.workDayEvents
        .map { ($0.error as? ServiceError)?.serviceCode == ServiceErrorCode.NoNetworkConnection.rawValue }
    
    private lazy var walletItem: Observable<WalletItem?> = self.walletItemEvents.elements()

    private(set) lazy var data: Observable<Event<(Account, AccountDetail, WalletItem?)>> =
        Observable.combineLatest(self.account,
                                 self.accountDetailElements,
                                 self.walletItem)
            .materialize()
            .share()
    
    private func fetchOTPWalletItem() -> Observable<Event<WalletItem?>> {
        return walletService.fetchWalletItems()
            .trackActivity(fetchingTracker)
            .map { $0.first(where: { $0.isDefault }) }
            .materialize()
    }
    
    private func fetchWorkDays() -> Observable<Event<[Date]>> {
        return paymentService.fetchWorkdays()
            .trackActivity(fetchingTracker)
            .materialize()
    }
    
    private lazy var workDayEvents: Observable<Event<[Date]>> = self.account.map { _ in () }
        .flatMapLatest(self.fetchWorkDays)
        .shareReplay(1)
    
    private func schedulePayment(_ payment: Payment) -> Observable<Void> {
        let paymentDetails = PaymentDetails(amount: payment.paymentAmount, date: payment.paymentDate)
        return paymentService.schedulePayment(payment: payment)
            .withLatestFrom(account)
            .do(onNext: { RecentPaymentsStore.shared[$0] = paymentDetails })
            .map { _ in () }
            .trackActivity(paymentTracker)
    }
    
    private(set) lazy var oneTouchPayResult: Observable<Void> = self.submitOneTouchPay.asObservable()
        .withLatestFrom(Observable.combineLatest(self.accountDetailElements, self.walletItem.unwrap()))
        .map { accountDetail, walletItem in
            Payment(accountNumber: accountDetail.accountNumber,
                    existingAccount: true,
                    saveAccount: true,
                    maskedWalletAccountNumber: walletItem.maskedWalletItemAccountNumber!,
                    paymentAmount: accountDetail.billingInfo.netDueAmount!,
                    paymentType: (walletItem.paymentCategoryType == .check) ? .check : .credit,
                    paymentDate: Date(),
                    walletId: AccountsStore.sharedInstance.customerIdentifier,
                    walletItemId: walletItem.walletItemID!,
                    cvv: nil)
        }
        .flatMapLatest(self.schedulePayment)
    
    private(set) lazy var shouldShowWeekendWarning: Driver<Bool> = {
        if Environment.sharedInstance.opco != .peco {
            return Driver.just(false)
        } else {
            return self.workDayEvents.elements()
                .map { $0.filter(NSCalendar.current.isDateInToday).isEmpty }
                .asDriver(onErrorDriveWith: .empty())
        }
    }()
    
    //MARK: - Loaded States
    
    private lazy var accountDetailDriver: Driver<AccountDetail> = self.accountDetailElements.asDriver(onErrorDriveWith: .empty())
    private lazy var walletItemDriver: Driver<WalletItem?> = self.walletItem.asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var billNotReady: Driver<Bool> = self.accountDetailDriver
        .map { ($0.billingInfo.netDueAmount ?? 0) == 0 && ($0.billingInfo.lastPaymentAmount ?? 0) > 0 }
    
    private(set) lazy var showErrorState: Driver<Bool> = Observable.zip(self.accountDetailEvents, self.walletItemEvents)
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
                
                // ComEd/PECO
                if opco != .bge && (billingInfo.restorationAmount ?? 0) > 0 {
                    return .restoreService
                }
                
                if opco != .bge && (billingInfo.amtDpaReinst ?? 0 > 0) {
                    return .catchUp
                }
                
                // All OpCos
                if let pastDueAmount = billingInfo.pastDueAmount,
                    let dueByDate = billingInfo.dueByDate {
                    if billingInfo.netDueAmount == pastDueAmount {
                        return .pastDueTotal
                    } else {
                        return .pastDueNotTotal
                    }
                }
                
                if billingInfo.disconnectNoticeArrears > 0 && billingInfo.isDisconnectNotice {
                    if opco == .bge && account.isMultipremise {
                        return .avoidShutoffBGEMultipremise
                    }
                    return .avoidShutoff
                }
                
                if opco == .bge && (billingInfo.netDueAmount ?? 0) < 0 {
                    return .credit
                }
                
                if billingInfo.pendingPaymentAmount ?? 0 > 0 {
                    return .paymentPending
                }
                
                if (billingInfo.netDueAmount ?? 0) == 0, let lastPaymentAmount = billingInfo.lastPaymentAmount {
                    return .billPaid
                }
                
                if RecentPaymentsStore.shared[account] != nil {
                    return .billPaidIntermediate
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
    
    private lazy var showAutoPay: Driver<Bool> = Driver.zip(self.isPrecariousBillSituation, self.accountDetailDriver)
        .map { !$0 && $1.isAutoPay }
    
    private(set) lazy var showPaymentPendingIcon: Driver<Bool> = self.titleState.map { $0 == .paymentPending }
    
    private(set) lazy var showBillPaidIcon: Driver<Bool> = self.titleState.map { $0 == .billPaid }
    
    private(set) lazy var showAmountPaid: Driver<Bool> = self.titleState.map { $0 == .billPaid }
    
    private(set) lazy var showAmount: Driver<Bool> = self.titleState.map { $0 != .billPaid }
    
    private(set) lazy var showConvenienceFee: Driver<Bool> = Driver.combineLatest(self.isPrecariousBillSituation, self.showAutoPay, self.walletItemDriver)
        .map { !$0 && !$1 && $2 != nil }
    
    private(set) lazy var showDueDate: Driver<Bool> = self.titleState.map {
        switch $0 {
        case .billPaid, .billPaidIntermediate, .credit:
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
        case .avoidShutoff, .avoidShutoffBGEMultipremise:
            return true
        default:
            return false
        }
    }
    
    let showDueAmountAndDateTooltip = Environment.sharedInstance.opco == .peco
    
    private(set) lazy var showBankCreditButton: Driver<Bool> = Driver.combineLatest(self.titleState,
                                                                          self.isPrecariousBillSituation,
                                                                          self.walletItemDriver)
        .map { $0 != .credit && !$1 && $2 != nil }
    
    private(set) lazy var showSaveAPaymentAccountButton: Driver<Bool> = Driver.combineLatest(self.titleState,
                                                                                   self.isPrecariousBillSituation,
                                                                                   self.walletItemDriver)
        .map { $0 != .credit && !$1 && $2 == nil }
    
    private(set) lazy var showMinimumPaymentAllowed: Driver<Bool> = Driver.combineLatest(self.titleState,
                                                                               self.isPrecariousBillSituation,
                                                                               self.walletItemDriver,
                                                                               self.accountDetailDriver)
    { titleState, isPrecariousBillSituation, walletItem, accountDetail in
        guard let minPaymentAmount = accountDetail.billingInfo.minPaymentAmount else { return false }
        return titleState != .credit &&
            !isPrecariousBillSituation &&
            walletItem != nil &&
            (accountDetail.billingInfo.netDueAmount ?? 0) < minPaymentAmount &&
            Environment.sharedInstance.opco != .bge
    }
    
    private(set) lazy var showOneTouchPaySlider: Driver<Bool> = Driver.combineLatest(self.titleState,
                                                                           self.isPrecariousBillSituation,
                                                                           self.showAutoPay,
                                                                           self.walletItemDriver)
        .map { $0 != .credit && !$1 && !$2 && $3 != nil }
    
    private(set) lazy var showScheduledImageView: Driver<Bool> = self.accountDetailDriver
        .map { $0.billingInfo.scheduledPaymentAmount != nil && $0.billingInfo.scheduledPaymentDate != nil }
    
    private(set) lazy var showAutoPayIcon: Driver<Bool> = self.showAutoPay
    
    private(set) lazy var showAutomaticPaymentInfoButton: Driver<Bool> = self.showAutoPay
    
    private(set) lazy var showScheduledPaymentInfoButton: Driver<Bool> = self.showScheduledImageView
    
    private(set) lazy var showOneTouchPayTCButton: Driver<Bool> = Driver.zip(self.showOneTouchPaySlider,
                                                                             self.enableOneTouchSlider) { $0 && $1 }
    
    
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
    
    private(set) lazy var amountPaidText: Driver<String?> = self.accountDetailDriver.map {
        guard let lastPaymentAmountString = $0.billingInfo.lastPaymentAmount?.currencyString else { return nil }
        return String(format: NSLocalizedString("Amount Paid: %@", comment: ""), lastPaymentAmountString)
    }
    
    private(set) lazy var amountText: Driver<String?> = self.accountDetailDriver.map {
        $0.billingInfo.netDueAmount?.currencyString
    }
    
    private(set) lazy var dueDateText: Driver<NSAttributedString?> = self.accountDetailDriver.map {
        if Environment.sharedInstance.opco == .bge {
            let localizedText = NSLocalizedString("Due by %@", comment: "")
            let dueByDateString = $0.billingInfo.dueByDate?.mmDdYyyyString ?? "--"
            return NSAttributedString(string: String(format: localizedText, dueByDateString),
                                      attributes: [NSForegroundColorAttributeName: UIColor.deepGray,
                                                   NSFontAttributeName: SystemFont.regular.of(textStyle: .subheadline)])
        } else {
            return NSAttributedString(string: NSLocalizedString("Due Immediately", comment: ""),
                                      attributes: [NSForegroundColorAttributeName: UIColor.errorRed,
                                                   NSFontAttributeName: SystemFont.regular.of(textStyle: .subheadline)])
        }
    }
    
    private(set) lazy var dueAmountAndDateText: Driver<String?> = self.accountDetailDriver.map {
        guard let amountDueString = $0.billingInfo.netDueAmount?.currencyString else { return nil }
        guard let dueByDate = $0.billingInfo.dueByDate else { return nil }
        
        let calendar = NSCalendar.current
        let date1 = calendar.startOfDay(for: Date())
        let date2 = calendar.startOfDay(for: dueByDate)
        guard let days = calendar.dateComponents([.day], from: date1, to: date2).day else { return nil }
        
        let localizedText = NSLocalizedString("Your bill total of %@ is due in %d days.", comment: "")
        return String(format: localizedText, amountDueString, days)
    }
    
    private(set) lazy var bankCreditCardNumberText: Driver<String?> = self.walletItemDriver.map {
        $0?.maskedWalletItemAccountNumber
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
            switch (accountDetail.isResidential, walletItem.bankOrCard, Environment.sharedInstance.opco) {
            case (_, .card, .peco):
                return NSLocalizedString("A 2.35 convenience fee will be applied by Bill Matrix, our payment partner.", comment: "")
            case (_, .card, .comEd):
                return NSLocalizedString("A 2.50 convenience fee will be applied by Bill Matrix, our payment partner.", comment: "")
            case (true, .card, .bge):
                return NSLocalizedString("A 1.50 convenience fee will be applied by Western Union Speedpay, our payment partner.", comment: "")
            case (false, .card, .bge):
                return NSLocalizedString("A 2.4% convenience fee will be applied by Western Union Speedpay, our payment partner.", comment: "")
            case (_, .bank, _):
                return NSLocalizedString("No fees applied.", comment: "")
            default:
                return nil
            }
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
    
    //TODO: scheduledPaymentAmount or netDueAmount?
    private(set) lazy var automaticPaymentInfoButtonText: Driver<String?> = self.accountDetailDriver.map {
        switch Environment.sharedInstance.opco {
        case .bge:
            return NSLocalizedString("You are enrolled in AutoPay." , comment: "")
        case .peco, .comEd:
            guard let paymentAmountText = $0.billingInfo.scheduledPaymentAmount?.currencyString else { return nil }
            guard let paymentDateText = $0.billingInfo.scheduledPaymentDate?.mmDdYyyyString else { return nil }
            let localizedText = NSLocalizedString("You have an automatic payment of %@ for $@." , comment: "")
            return String(format: localizedText, paymentAmountText, paymentDateText)
        }
    }
    
    private(set) lazy var thankYouForSchedulingButtonText: Driver<String?> = self.accountDetailDriver.map {
        guard let paymentAmountText = $0.billingInfo.scheduledPaymentAmount?.currencyString else { return nil }
        guard let paymentDateText = $0.billingInfo.scheduledPaymentDate?.mmDdYyyyString else { return nil }
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
    
}





