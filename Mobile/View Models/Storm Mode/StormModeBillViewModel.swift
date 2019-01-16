//
//  StormModeBillViewModel.swift
//  Mobile
//
//  Created by Samuel Francis on 9/10/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class StormModeBillViewModel {
    
    let fetchData = PublishSubject<FetchingAccountState>()
    let fetchDataObservable: Observable<FetchingAccountState>
    
    private let accountService: AccountService
    private let walletService: WalletService
    private let paymentService: PaymentService
    private let authService: AuthenticationService
    
    private let refreshTracker = ActivityTracker()
    private let switchAccountTracker = ActivityTracker()
    
    required init(accountService: AccountService,
                  walletService: WalletService,
                  paymentService: PaymentService,
                  authService: AuthenticationService) {
        self.fetchDataObservable = fetchData.share()
        self.accountService = accountService
        self.walletService = walletService
        self.paymentService = paymentService
        self.authService = authService
    }
    
    private(set) lazy var billCardViewModel =
        HomeBillCardViewModel(fetchData: fetchDataObservable,
                              fetchDataMMEvents: fetchDataObservable.mapTo(Maintenance.from([:])!).materialize(),
                              accountDetailEvents: accountDetailEvents,
                              walletService: walletService,
                              paymentService: paymentService,
                              authService: authService,
                              refreshFetchTracker: refreshTracker,
                              switchAccountFetchTracker: switchAccountTracker)
    
    private(set) lazy var accountDetailEvents: Observable<Event<AccountDetail>> = fetchData
        .toAsyncRequest(activityTrackers: { [weak self] state in
            guard let self = self else { return nil }
            switch state {
            case .refresh:
                return [self.refreshTracker]
            case .switchAccount:
                return [self.switchAccountTracker]
            }
            }, requestSelector: { [weak self] _ in
                guard let self = self else { return .empty() }
                return self.accountService.fetchAccountDetail(account: AccountsStore.shared.currentAccount)
        })
    
    private(set) lazy var didFinishRefresh: Driver<Void> = refreshTracker
        .asDriver()
        .filter(!)
        .map(to: ())
    
    private(set) lazy var isSwitchingAccounts: Driver<Bool> = switchAccountTracker
        .asDriver()
        .distinctUntilChanged()
    
    private(set) lazy var showButtonStack: Driver<Bool> = Observable
        .combineLatest(switchAccountTracker.asObservable(),
                       accountDetailEvents)
        { isLoading, accountDetailEvent in
            accountDetailEvent.error == nil && !isLoading
        }
        .startWith(false)
        .distinctUntilChanged()
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showMakeAPaymentButton: Driver<Bool> = accountDetailEvents.elements()
        .map { $0.billingInfo.netDueAmount ?? 0 > 0 || Environment.shared.opco == .bge }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showNoNetworkConnectionView: Driver<Bool> = accountDetailEvents
        .map { ($0.error as? ServiceError)?.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue }
        .startWith(false)
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var makePaymentScheduledPaymentAlertInfo: Observable<(String?, String?, AccountDetail)> = accountDetailEvents
        .elements()
        .map { accountDetail in
            if Environment.shared.opco == .bge && accountDetail.isBGEasy {
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
            } else if let scheduledPaymentAmount = accountDetail.billingInfo.scheduledPayment?.amount,
                let scheduledPaymentDate = accountDetail.billingInfo.scheduledPayment?.date,
                let amountString = scheduledPaymentAmount.currencyString, scheduledPaymentAmount > 0 {
                let localizedTitle = NSLocalizedString("Existing Scheduled Payment", comment: "")
                return (localizedTitle, String(format: NSLocalizedString("You have a payment of %@ scheduled for %@. " +
                    "To avoid a duplicate payment, please review your payment activity before proceeding. Would " +
                    "you like to continue making an additional payment?", comment: ""),
                                               amountString, scheduledPaymentDate.mmDdYyyyString), accountDetail)
            }
            return (nil, nil, accountDetail)
    }
}
