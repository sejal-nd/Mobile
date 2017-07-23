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
    
    private let fetchingTracker: ActivityTracker
    
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
        .materialize()
    
    private lazy var walletItem: Observable<WalletItem?> = self.walletItemEvents.elements()

    private(set) lazy var data: Observable<Event<(Account, AccountDetail, WalletItem?)>> = Observable.combineLatest(self.account, self.accountDetailElements, self.walletItem)
        .materialize()
        .share()
    
    private func fetchOTPWalletItem() -> Observable<WalletItem?> {
        return walletService.fetchWalletItems()
            .trackActivity(fetchingTracker)
            .map { $0.first(where: { $0.isDefault }) }
    }
    
    private func fetchWorkDays() -> Observable<[Date]> {
        return paymentService.fetchWorkdays()
            .trackActivity(fetchingTracker)
    }
    
    private(set) lazy var workDays: Observable<[Date]> = self.account.map { _ in () }.flatMapLatest(self.fetchWorkDays)
    
    private(set) lazy var shouldShowWeekendWarning: Driver<Bool> = self.workDays
        .map { $0.filter(NSCalendar.current.isDateInToday).isEmpty && Environment.sharedInstance.opco == .peco }
        .asDriver(onErrorDriveWith: .empty())
    
    //MARK: - Loaded States
    
    private lazy var accountDetailDriver: Driver<AccountDetail> = self.accountDetailElements.asDriver(onErrorDriveWith: .empty())
    private lazy var walletItemDriver: Driver<WalletItem?> = self.walletItem.asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var billNotReady: Driver<Bool> = self.accountDetailDriver.map { _ in false }
    
    private(set) lazy var showErrorState: Driver<Bool> = Observable.zip(self.accountDetailEvents, self.walletItem)
        .map { $0.0.error != nil }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var state: Driver<BillCardState> = self.data.map { event -> BillCardState in
        guard let (account, accountDetail, walletItem) = event.element else {
            return .error
        }
        
        let billingInfo = accountDetail.billingInfo
        
        if let paymentDetails = PaymentDetailsStore.shared[account],
            paymentDetails.date.addingTimeInterval(86_400) > Date() {
            return .payment
        }
            
        else if billingInfo.billDate == nil, billingInfo.netDueAmount == 0 {
            return .noBill
        }
        else if (billingInfo.pastDueAmount ?? 0) > 0 {
            return .pastDue
        }
        else if (billingInfo.netDueAmount ?? 0) > 0 {
            return .due
        }
        else if (billingInfo.pendingPaymentAmount ?? 0) > 0 {
            return .paymentPending
        }
        else if billingInfo.isDisconnectNotice {
            return .avoidShutoff
        }
        else if (billingInfo.currentDueAmount ?? 0) < 0 {
            return .credit
        }
        else if (billingInfo.lastPaymentAmount ?? 0) > 0 || billingInfo.netDueAmount == 0 {
            return .payment
        }
        else {
            return .noBill
        }
        }
        .asDriver(onErrorDriveWith: .empty())
    
    
    // MARK: - Title Label
    
    enum TitleState {
        case restoreService, catchUp, avoidShutoff, avoidShutoffBGEMultipremise, pastDueTotal, pastDueNotTotal, billReady, billPaid, credit, multipremiseReady, paymentPending
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
                
                if (billingInfo.netDueAmount ?? 0) == 0 || PaymentDetailsStore.shared[account] != nil {
                    return .billPaid
                }
                
                if opco == .bge && account.isMultipremise {
                    return .multipremiseReady
                }
                return .billReady
            }
            .asDriver(onErrorDriveWith: .empty())
    
    
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
            case .billPaid:
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
        .asDriver(onErrorJustReturn: nil)
    
    private lazy var showAutoPay: Driver<Bool> = Driver.zip(self.isPrecariousBillSituation, self.accountDetailDriver)
        .map { !$0 && $1.isAutoPay }
    
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
    
    private(set) lazy var showPaymentPendingIcon: Driver<Bool> = self.titleState.map { $0 == .paymentPending }
    
    private(set) lazy var showBillPaidIcon: Driver<Bool> = self.titleState.map { $0 == .billPaid }
    
    private(set) lazy var showAmountPaid: Driver<Bool> = self.titleState.map { $0 == .billPaid }
    
    private(set) lazy var showAmount: Driver<Bool> = self.titleState.map { $0 != .billPaid }
    
    private(set) lazy var showDueDate: Driver<Bool> = self.titleState.map {
        switch $0 {
        case .billPaid, .credit:
            return false
        default:
            return true
        }
    }
    
    let showDueDateTooltip = Environment.sharedInstance.opco == .peco
    
    private(set) lazy var showDueAmountAndDate: Driver<Bool> = self.titleState.map {
        switch $0 {
        case .avoidShutoff, .avoidShutoffBGEMultipremise:
            return true
        default:
            return false
        }
    }
    
    let showDueAmountAndDateTooltip = Environment.sharedInstance.opco == .peco
    
    private(set) lazy var showBankCreditButton: Driver<Bool> = Driver.zip(self.titleState, self.isPrecariousBillSituation, self.walletItemDriver)
        .map { $0 != .credit && !$1 && $2 != nil }
    
    private(set) lazy var showSaveAPaymentAccountButton: Driver<Bool> = Driver.zip(self.titleState, self.isPrecariousBillSituation, self.walletItemDriver)
        .map { $0 != .credit && !$1 && $2 == nil }
    
    private(set) lazy var showMinimumPaymentAllowed: Driver<Bool> = Driver.zip(self.titleState, self.isPrecariousBillSituation, self.walletItemDriver, self.accountDetailDriver)
        .map { $0 != .credit && !$1 && $2 != nil && ($3.billingInfo.netDueAmount ?? 0) < 5 }
    
    private(set) lazy var showOneTouchPaySlider: Driver<Bool> = Driver.zip(self.titleState, self.isPrecariousBillSituation, self.showAutoPay, self.walletItemDriver)
        .map { $0 != .credit && !$1 && !$2 && $3 != nil }
    
    private(set) lazy var showScheduledImageView: Driver<Bool> = self.accountDetailDriver
        .map { $0.billingInfo.scheduledPaymentAmount != nil && $0.billingInfo.scheduledPaymentDate != nil }
    
    private(set) lazy var showAutoPayIcon: Driver<Bool> = self.showAutoPay
    
    private(set) lazy var showAutomaticPaymentInfoButton: Driver<Bool> = self.showAutoPay
    
    private(set) lazy var showScheduledPaymentInfoButton: Driver<Bool> = self.showScheduledImageView
    
    
    // MARK: - Text Styling
    private(set) lazy var titleFont: Driver<UIFont> = self.titleState
        .map {
            switch $0 {
            case .restoreService, .catchUp, .avoidShutoff, .avoidShutoffBGEMultipremise, .pastDueTotal, .pastDueNotTotal:
                return OpenSans.regular.of(textStyle: .headline)
            case .billReady, .billPaid, .credit, .multipremiseReady:
                return OpenSans.regular.of(textStyle: .title1)
            case .paymentPending:
                return OpenSans.italic.of(textStyle: .title1)
            }
    }
    
    private(set) lazy var amountFont: Driver<UIFont> = self.titleState
        .map { $0 == .paymentPending ? OpenSans.semiboldItalic.of(size: 28): OpenSans.semibold.of(size: 36) }
    
}








