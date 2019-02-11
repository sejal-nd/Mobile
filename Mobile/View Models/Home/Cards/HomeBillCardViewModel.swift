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
    let scheduledPaymentEvents: Observable<Event<PaymentItem?>>
    private let walletService: WalletService
    private let paymentService: PaymentService
    private let authService: AuthenticationService
    
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
                  scheduledPaymentEvents: Observable<Event<PaymentItem?>>,
                  walletService: WalletService,
                  paymentService: PaymentService,
                  authService: AuthenticationService,
                  refreshFetchTracker: ActivityTracker,
                  switchAccountFetchTracker: ActivityTracker) {
        self.fetchData = fetchData
        self.fetchDataMMEvents = fetchDataMMEvents
        self.accountDetailEvents = accountDetailEvents
        self.scheduledPaymentEvents = scheduledPaymentEvents
        self.walletService = walletService
        self.paymentService = paymentService
        self.authService = authService
        self.refreshFetchTracker = refreshFetchTracker
        self.switchAccountFetchTracker = switchAccountFetchTracker
        
        oneTouchPayResult
            .withLatestFrom(walletItem.unwrap()) { ($0, $1) }
            .subscribe(onNext: { oneTouchPayEvent, walletItem in
                switch (walletItem.bankOrCard, oneTouchPayEvent.error) {
                case (.bank, nil):
                    Analytics.log(event: .oneTouchBankComplete)
                case (.bank, let error):
                    Analytics.log(event: .oneTouchBankError,
                                         dimensions: [.errorCode: (error as! ServiceError).serviceCode])
                case (.card, nil):
                    Analytics.log(event: .oneTouchCardComplete)
                case (.card, let error):
                    Analytics.log(event: .oneTouchCardError,
                                         dimensions: [.errorCode: (error as! ServiceError).serviceCode])
                }
            })
            .disposed(by: bag)
    }
    
    private lazy var fetchTrigger = Observable
        .merge(fetchData, RxNotifications.shared.defaultWalletItemUpdated.mapTo(FetchingAccountState.switchAccount))
    
    // Awful maintenance mode check
    private lazy var defaultWalletItemUpdatedMMEvents: Observable<Event<Maintenance>> = RxNotifications.shared.defaultWalletItemUpdated
        .toAsyncRequest(activityTracker: { [weak self] _ in self?.fetchTracker(forState: .switchAccount) },
                        requestSelector: { [unowned self] _ in self.authService.getMaintenanceMode() })
    
    private lazy var maintenanceModeEvents: Observable<Event<Maintenance>> = Observable.merge(fetchDataMMEvents, defaultWalletItemUpdatedMMEvents)
    
    private lazy var walletItemEvents: Observable<Event<WalletItem?>> = maintenanceModeEvents
        .filter {
            guard let maint = $0.element else { return false }
            return !maint.allStatus && !maint.billStatus && !maint.homeStatus
        }
        .withLatestFrom(fetchTrigger)
        .toAsyncRequest(activityTracker: { [weak self] in self?.fetchTracker(forState: $0) },
                        requestSelector: { [weak self] _ in
                            guard let this = self else { return .empty() }
                            return this.walletService.fetchWalletItems().map { $0.first(where: { $0.isDefault }) }
        })
    
    private(set) lazy var walletItemNoNetworkConnection: Observable<Bool> = walletItemEvents.errors()
        .map { ($0 as? ServiceError)?.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue }
    
    private(set) lazy var walletItem: Observable<WalletItem?> = walletItemEvents.elements()
    
    private lazy var account: Observable<Account> = fetchData.map { _ in AccountsStore.shared.currentAccount }
    
    private(set) lazy var oneTouchPayResult: Observable<Event<Void>> = submitOneTouchPay.asObservable()
        .withLatestFrom(Observable.combineLatest(accountDetailEvents.elements(),
                                                 walletItem.unwrap()))
        .do(onNext: { _, walletItem in
            switch walletItem.bankOrCard {
            case .bank:
                Analytics.log(event: .oneTouchBankOffer)
            case .card:
                Analytics.log(event: .oneTouchCardOffer)
            }
        })
        .map { accountDetail, walletItem in
            let startOfToday = Calendar.opCo.startOfDay(for: Date())
            let paymentDate: Date
            if Environment.shared.opco == .bge &&
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
                           walletItemId: walletItem.walletItemID!)
        }
        .toAsyncRequest(activityTracker: paymentTracker,
                        requestSelector: { [unowned self] payment in
                            self.paymentService.schedulePayment(payment: payment)
                                .do(onNext: { confirmationNumber in
                                    let paymentDetails = PaymentDetails(amount: payment.paymentAmount, date: payment.paymentDate, confirmationNumber: confirmationNumber)
                                    RecentPaymentsStore.shared[AccountsStore.shared.currentAccount] = paymentDetails
                                })
                                .mapTo(())
        })
    
    //MARK: - Loaded States
    
    private lazy var accountDetailDriver: Driver<AccountDetail> = accountDetailEvents.elements().asDriver(onErrorDriveWith: .empty())
    private lazy var scheduledPaymentDriver: Driver<PaymentItem?> = scheduledPaymentEvents.elements().asDriver(onErrorDriveWith: .empty())
    private lazy var walletItemDriver: Driver<WalletItem?> = walletItem.asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showLoadingState: Driver<Bool> = switchAccountFetchTracker.asDriver()
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
        .map { $0.element?.billStatus ?? false }
        .startWith(false)
        .distinctUntilChanged()
        .asDriver(onErrorDriveWith: .empty())
    
    // MARK: - Title States
    
    enum BillState {
        case restoreService, catchUp, avoidShutoff, pastDue, finaled, eligibleForCutoff, billReady, billReadyAutoPay, billPaid, billPaidIntermediate, credit,
        paymentPending, billNotReady, paymentScheduled
        
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
            let opco = Environment.shared.opco
            
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
            
            if billingInfo.netDueAmount > 0 && (accountDetail.isAutoPay || accountDetail.isBGEasy) {
                return .billReadyAutoPay
            }
            
            if scheduledPayment?.amount > 0 {
                return .paymentScheduled
            }
            
            if opco == .bge && billingInfo.netDueAmount < 0 {
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
    
    private(set) lazy var showBillPaidIcon: Driver<Bool> = billState.map { $0 == .billPaid || $0 == .billPaidIntermediate }
    
    private(set) lazy var showPaymentDescription: Driver<Bool> = paymentDescriptionText.isNil().not()
    
    private(set) lazy var showSlideToPayConfirmationDetailLabel: Driver<Bool> = billState.map { $0 == .billPaidIntermediate }
    
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
    
    let showDueDateTooltip = Environment.shared.opco == .peco
    
    private(set) lazy var showReinstatementFeeText: Driver<Bool> = reinstatementFeeText.isNil().not()
    
    private(set) lazy var showWalletItemInfo: Driver<Bool> = Driver
        .combineLatest(showOneTouchPaySlider,
                       showMinMaxPaymentAllowed)
        { $0 && !$1 }
        .distinctUntilChanged()
    
    private(set) lazy var showBankCreditNumberButton: Driver<Bool> = walletItemDriver.isNil().not()
    
    private(set) lazy var showBankCreditExpiredLabel: Driver<Bool> = walletItemDriver.map {
        $0?.isExpired ?? false
    }
    
    private(set) lazy var showSaveAPaymentAccountButton: Driver<Bool> = Driver
        .combineLatest(billState, walletItemDriver, showOneTouchPaySlider)
        { $0 != .credit && !$0.isPrecariousBillSituation && $0 != .paymentScheduled && $1 == nil && $2 }
        .distinctUntilChanged()
    
    private(set) lazy var showMinMaxPaymentAllowed: Driver<Bool> = Driver
        .combineLatest(billState,
                       walletItemDriver,
                       accountDetailDriver,
                       showOneTouchPaySlider,
                       minMaxPaymentAllowedText)
    { billState, walletItem, accountDetail, showOneTouchPaySlider, minMaxPaymentAllowedText in
        return billState == .billReady &&
            walletItem != nil &&
            showOneTouchPaySlider &&
            minMaxPaymentAllowedText != nil
    }
        .distinctUntilChanged()
    
    private(set) lazy var showOneTouchPaySlider: Driver<Bool> = Driver.combineLatest(billState,
                                                                                     accountDetailDriver)
    { $0 == .billReady && !$1.isActiveSeverance && !$1.isCashOnly }
        .distinctUntilChanged()
    
    private(set) lazy var showCommercialBgeOtpVisaLabel: Driver<Bool> = Driver
        .combineLatest(enableOneTouchSlider,
                       showOneTouchPaySlider,
                       accountDetailDriver,
                       walletItemDriver)
        { enableOneTouchSlider, showOneTouchPaySlider, accountDetail, walletItem in
            guard let walletItem = walletItem else { return false }
            guard showOneTouchPaySlider && !enableOneTouchSlider else { return false }
            guard Environment.shared.opco == .bge else { return false }
            
            // Min/Max payment amount state takes precedence
            guard accountDetail.billingInfo.netDueAmount >= accountDetail.minPaymentAmount(bankOrCard: .card) else { return false }
            guard accountDetail.billingInfo.netDueAmount <= accountDetail.maxPaymentAmount(bankOrCard: .card) else { return false }
            
            guard walletItem.paymentMethodType == .visa else { return false }
            guard !accountDetail.isResidential && !accountDetail.isActiveSeverance && !accountDetail.isCashOnly else { return false }
            
            return true
        }
        .distinctUntilChanged()
    
    private(set) lazy var showScheduledPayment: Driver<Bool> = billState.map { $0 == .paymentScheduled }
    
    private(set) lazy var showAutoPay: Driver<Bool> = billState.map {
        $0 == .billReadyAutoPay
    }
    
    private(set) lazy var showOneTouchPayTCButton: Driver<Bool> = Driver.combineLatest(showOneTouchPaySlider,
                                                                                       showCommercialBgeOtpVisaLabel,
                                                                                       showMinMaxPaymentAllowed)
    { $0 && !$1 && !$2 }
        .distinctUntilChanged()
    
    
    // MARK: - View States
    private(set) lazy var paymentDescriptionText: Driver<NSAttributedString?> = Driver.combineLatest(billState, accountDetailDriver)
    { (billState, accountDetail) in
        let textColor = StormModeStatus.shared.isOn ? UIColor.white : UIColor.deepGray
        switch billState {
        case .billPaid, .billPaidIntermediate:
            let text = NSLocalizedString("Thank you for your payment", comment: "")
            return NSAttributedString(string: text, attributes: [.font: OpenSans.regular.of(textStyle: .title1),
                                                                 .foregroundColor: textColor])
        case .paymentPending:
            let text: String
            switch Environment.shared.opco {
            case .bge:
                text = NSLocalizedString("You have processing payments", comment: "")
            case .comEd, .peco:
                text = NSLocalizedString("You have pending payments", comment: "")
            }
            return NSAttributedString(string: text, attributes: [.font: OpenSans.italic.of(textStyle: .title1),
                                                                 .foregroundColor: textColor])
        default:
            return nil
        }
    }
    
    private(set) lazy var showAlertAnimation: Driver<Bool> = billState.map {
        return $0.isPrecariousBillSituation
    }
    
    private(set) lazy var resetAlertAnimation: Driver<Void> = Driver.merge(refreshFetchTracker.asDriver(),
                                                                           switchAccountFetchTracker.asDriver())
        .filter(!)
        .map(to: ())
    
    private(set) lazy var headerText: Driver<NSAttributedString?> = Driver.combineLatest(accountDetailDriver, billState)
    { accountDetail, billState in
        let billingInfo = accountDetail.billingInfo
        let isMultiPremise = AccountsStore.shared.currentAccount.isMultipremise
        
        let textColor = StormModeStatus.shared.isOn ? UIColor.white : UIColor.errorRed
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = 16
        var attributes: [NSAttributedString.Key: Any] = [.font: SystemFont.semibold.of(textStyle: .footnote),
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
                let format = "%@ of the total is due immediately."
                string = String.localizedStringWithFormat(format, amount)
            case (true, false):
                guard let amount = billingInfo.pastDueAmount?.currencyString else { return nil }
                let format = "%@ of the total is due immediately for your multi-premise account."
                string = String.localizedStringWithFormat(format, amount)
            case (false, true):
                string = NSLocalizedString("Your bill is past due.", comment: "")
            case (true, true):
                string = NSLocalizedString("Your bill is past due for your multi-premise account.", comment: "")
            }
            
            return NSAttributedString(string: string, attributes: attributes)
        case .catchUp:
            guard let amountString = billingInfo.amtDpaReinst?.currencyString,
                let dueByDate = billingInfo.dueByDate else {
                    return nil
            }
            
            let days = dueByDate.interval(ofComponent: .day, fromDate: Calendar.opCo.startOfDay(for: Date()))
            
            let string: String
            switch (days > 0, billingInfo.amtDpaReinst == billingInfo.netDueAmount) {
            case (true, true):
                let format = "The total amount is due in %d day%@ to catch up on your DPA."
                string = String.localizedStringWithFormat(format, days, days == 1 ? "": "s")
            case (true, false):
                let format = "%@ of the total is due in %d day%@ to catch up on your DPA."
                string = String.localizedStringWithFormat(format, amountString, days, days == 1 ? "": "s")
            case (false, true):
                string = NSLocalizedString("The total amount must be paid immediately to catch up on your DPA.", comment: "")
            case (false, false):
                let format = "%@ of the total must be paid immediately to catch up on your DPA."
                string = String.localizedStringWithFormat(format, amountString)
            }
            
            return NSAttributedString(string: string, attributes: attributes)
        case .restoreService:
            guard let amountString = billingInfo.restorationAmount?.currencyString else {
                return nil
            }
            
            let localizedText = NSLocalizedString("%@ of the total must be paid immediately to restore service.", comment: "")
            let string = String.localizedStringWithFormat(localizedText, amountString)
            return NSAttributedString(string: string, attributes: attributes)
        case .avoidShutoff, .eligibleForCutoff:
            guard let amountString = billingInfo.disconnectNoticeArrears?.currencyString else {
                return nil
            }
            
            let date = billingInfo.turnOffNoticeExtendedDueDate ?? billingInfo.turnOffNoticeDueDate
            let days = date?.interval(ofComponent: .day, fromDate: Calendar.opCo.startOfDay(for: Date())) ?? 0
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
            
            let string = String.localizedStringWithFormat("%@ must be paid immediately. Your account has been finaled.", amountString)
            return NSAttributedString(string: string, attributes: attributes)
        default:
            if AccountsStore.shared.currentAccount.isMultipremise {
                attributes[.foregroundColor] = StormModeStatus.shared.isOn ? UIColor.white : UIColor.deepGray
                return NSAttributedString(string: NSLocalizedString("Multi-premise Account", comment: ""),
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
                return accountDetail.billingInfo.netDueAmount?.currencyString
            }
    }
    
    private(set) lazy var dueDateText: Driver<NSAttributedString?> = Driver.combineLatest(accountDetailDriver, billState)
    { accountDetail, billState in
        let grayAttributes: [NSAttributedString.Key: Any] =
            [.foregroundColor: StormModeStatus.shared.isOn ? UIColor.white : UIColor.deepGray,
             .font: OpenSans.regular.of(textStyle: .subheadline)]
        let redAttributes: [NSAttributedString.Key: Any] =
            [.foregroundColor: StormModeStatus.shared.isOn ? UIColor.white : UIColor.errorRed,
             .font: OpenSans.semibold.of(textStyle: .subheadline)]
        
        switch billState {
        case .pastDue, .finaled, .restoreService, .avoidShutoff, .eligibleForCutoff, .catchUp:
            if let netDueAmount = accountDetail.billingInfo.netDueAmount, netDueAmount == accountDetail.billingInfo.pastDueAmount {
                return NSAttributedString(string: NSLocalizedString("Total Amount Due Immediately", comment: ""),
                                          attributes: redAttributes)
            } else {
                return NSAttributedString(string: NSLocalizedString("Total Amount Due", comment: ""),
                                          attributes: grayAttributes)
            }
        case .credit:
            return NSAttributedString(string: NSLocalizedString("No Amount Due", comment: ""),
                                      attributes: grayAttributes)
        default:
            guard let dueByDate = accountDetail.billingInfo.dueByDate else { return nil }
            let calendar = Calendar.opCo
            
            let date1 = calendar.startOfDay(for: Date())
            let date2 = calendar.startOfDay(for: dueByDate)
            
            guard let days = calendar.dateComponents([.day], from: date1, to: date2).day else {
                return nil
            }
            
            if days > 0 {
                let localizedText = NSLocalizedString("Total Amount Due in %d Day%@", comment: "")
                return NSAttributedString(string: String(format: localizedText, days, days == 1 ? "": "s"),
                                          attributes: grayAttributes)
            } else {
                let localizedText = NSLocalizedString("Total Amount Due on %@", comment: "")
                return NSAttributedString(string: String(format: localizedText, dueByDate.mmDdYyyyString),
                                          attributes: grayAttributes)
            }
        }
    }
    
    private(set) lazy var reinstatementFeeText: Driver<String?> = accountDetailDriver.map {
        guard let reinstateString = $0.billingInfo.atReinstateFee?.currencyString,
            Environment.shared.opco == .comEd &&
                $0.billingInfo.amtDpaReinst > 0 &&
                $0.billingInfo.atReinstateFee > 0 &&
                !$0.isLowIncome else {
                    return nil
        }

        let reinstatementText = NSLocalizedString("You are entitled to one free reinstatement per plan. Any additional reinstatement will incur a %@ fee on your next bill.", comment: "")
        return String(format: reinstatementText, reinstateString)
    }
    
    private(set) lazy var bankCreditCardNumberText: Driver<String?> = walletItemDriver.map {
        guard let maskedNumber = $0?.maskedWalletItemAccountNumber else { return nil }
        return "**** " + maskedNumber
    }
    
    private(set) lazy var bankCreditCardImage: Driver<UIImage?> = walletItemDriver.map {
        guard let walletItem = $0 else { return nil }
        switch walletItem.bankOrCard {
        case .bank:
            return StormModeStatus.shared.isOn ? #imageLiteral(resourceName: "ic_bank_white.pdf") : #imageLiteral(resourceName: "ic_bank")
        case .card:
            return StormModeStatus.shared.isOn ? #imageLiteral(resourceName: "ic_creditcard_white.pdf") : #imageLiteral(resourceName: "ic_creditcard")
        }
    }
    
    private(set) lazy var bankCreditCardButtonAccessibilityLabel: Driver<String?> = walletItemDriver.map {
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
    
    private(set) lazy var minMaxPaymentAllowedText: Driver<String?> = Driver.combineLatest(accountDetailDriver, walletItemDriver)
    { accountDetail, walletItemOptional in
        guard let walletItem = walletItemOptional else { return nil }
        guard let paymentAmount = accountDetail.billingInfo.netDueAmount else { return nil }
        
        let minPayment = accountDetail.minPaymentAmount(bankOrCard: walletItem.bankOrCard)
        let maxPayment = accountDetail.maxPaymentAmount(bankOrCard: walletItem.bankOrCard)
        
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
    
    private(set) lazy var convenienceFeeText: Driver<String?> = Driver.combineLatest(accountDetailDriver, walletItemDriver)
        { accountDetail, walletItem in
            guard let walletItem = walletItem else { return nil }
            
            var localizedText: String? = nil
            var convenienceFeeString: String? = nil
            switch (accountDetail.isResidential, walletItem.bankOrCard, Environment.shared.opco) {
            case (_, .card, .peco):
                fallthrough
            case (_, .card, .comEd):
                localizedText = NSLocalizedString("A %@ convenience fee will be applied by Paymentus, our payment partner.", comment: "")
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
    
    private(set) lazy var enableOneTouchSlider: Driver<Bool> = Driver.combineLatest(accountDetailDriver, walletItemDriver, showMinMaxPaymentAllowed)
        { accountDetail, walletItem, showMinMaxPaymentAllowed in
            guard let walletItem = walletItem else { return false }
            if showMinMaxPaymentAllowed {
                return false
            }
            
            if walletItem.isExpired {
                return false
            }
            
            let minPaymentAmount = accountDetail.minPaymentAmount(bankOrCard: walletItem.bankOrCard)
            if accountDetail.billingInfo.netDueAmount ?? 0 < minPaymentAmount && Environment.shared.opco != .bge {
                return false
            }
            
            if accountDetail.billingInfo.netDueAmount < 0 && Environment.shared.opco == .bge {
                return false
            }
            
            if Environment.shared.opco == .bge &&
                walletItem.paymentMethodType == .visa &&
                !accountDetail.isResidential &&
                !accountDetail.isActiveSeverance &&
                !accountDetail.isCashOnly {
                return false
            }
            
            return true
        }
        .distinctUntilChanged()
    
    private(set) lazy var titleFont: Driver<UIFont> = billState
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
    
    private(set) lazy var amountFont: Driver<UIFont> = billState
        .map { $0 == .paymentPending ? OpenSans.semiboldItalic.of(size: 28): OpenSans.semibold.of(size: 36) }
    
    private(set) lazy var automaticPaymentInfoButtonText: Driver<String> = Driver.combineLatest(accountDetailDriver, scheduledPaymentDriver)
        .map { accountDetail, scheduledPayment in
            if let paymentAmountText = scheduledPayment?.amount.currencyString,
                let paymentDateText = scheduledPayment?.date?.mmDdYyyyString {
                return String.localizedStringWithFormat("You have an automatic payment of %@ for %@.",
                                                        paymentAmountText,
                                                        paymentDateText)
            } else if Environment.shared.opco == .bge && accountDetail.isBGEasy {
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
    
    private(set) lazy var oneTouchPayTCButtonText: Driver<String?> = walletItemDriver.map {
        guard let walletItem = $0 else { return nil }
        switch (Environment.shared.opco, walletItem.bankOrCard) {
        case (.bge, .bank):
            return NSLocalizedString("Payments made on the Home screen cannot be canceled.", comment: "")
        default:
            return NSLocalizedString("Payments made on the Home screen cannot be canceled. By sliding to pay, you agree to these payment Terms & Conditions.", comment: "")
        }
    }
    
    private(set) lazy var enableOneTouchPayTCButton: Driver<Bool> = walletItemDriver.map {
        guard let walletItem = $0 else { return false }
        switch (Environment.shared.opco, walletItem.bankOrCard) {
        case (.bge, .bank):
            return false
        default:
            return true
        }
    }
    
    private(set) lazy var oneTouchPayTCButtonTextColor: Driver<UIColor> = enableOneTouchPayTCButton
        .map { enable in
            if StormModeStatus.shared.isOn {
                return .white
            } else if enable {
                return .actionBlue
            } else {
                return .blackText
            }
    }
    
    private(set) lazy var slideToPayConfirmationDetailText: Driver<String?> = accountDetailDriver
        .map { _ in
            switch Environment.shared.opco {
            case .bge:
                return NSLocalizedString("It may take 24 hours for your payment status to update.", comment: "")
            case .comEd, .peco:
                guard let payment = RecentPaymentsStore.shared[AccountsStore.shared.currentAccount] else {
                    return nil
                }
                
                return String.localizedStringWithFormat("Your confirmation number is %@", payment.confirmationNumber)
            }
    }
    
    private(set) lazy var bankCreditButtonBorderWidth: Driver<CGFloat> = walletItemDriver.map {
        $0?.isExpired ?? false ? 1 : 0
    }
    
    var paymentTACUrl: URL {
        return URL(string: "https://ipn2.paymentus.com/rotp/www/terms-and-conditions.html")!
    }
    
    var errorPhoneNumber: String {
        switch Environment.shared.opco {
        case .bge:
            return "1-800-685-0123"
        case .comEd:
            return "1-800-334-7661"
        case .peco:
            return "1-800-494-4000"
        }
    }
    
}





