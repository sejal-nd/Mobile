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

    let fetchData = PublishSubject<Void>()
    let fetchDataObservable: Observable<Void>

    private let fetchTracker = ActivityTracker()

    required init() {
        self.fetchDataObservable = fetchData.share()
    }

    private(set) lazy var billCardViewModel =
        HomeBillCardViewModel(fetchData: fetchDataObservable,
                              fetchDataMMEvents: fetchDataObservable.mapTo(MaintenanceMode()).materialize(),
                              accountDetailEvents: accountDetailEvents,
                              scheduledPaymentEvents: scheduledPaymentEvents,
                                          fetchTracker: fetchTracker)

    private(set) lazy var accountDetailEvents: Observable<Event<AccountDetail>> = fetchData
        .toAsyncRequest(activityTracker: { [weak self] in self?.fetchTracker },
                        requestSelector: { [weak self] _ in
                            guard let self = self else { return .empty() }
                            return AccountService.rx.fetchAccountDetails()
                        })

    private(set) lazy var scheduledPaymentEvents: Observable<Event<PaymentItem?>> = fetchData
        .toAsyncRequest(activityTracker: { [weak self] in self?.fetchTracker },
                        requestSelector: { [weak self] _ in
                            guard let this = self else { return .empty() }
                            return AccountService.rx.fetchScheduledPayments(accountNumber: AccountsStore.shared.currentAccount.accountNumber).map { $0.last }
                        })

    private lazy var accountDetail = accountDetailEvents.elements()
    private lazy var scheduledPayment = scheduledPaymentEvents.elements()

    private(set) lazy var showBillCard: Driver<Bool> = Observable
        .combineLatest(fetchTracker.asObservable(),
                       accountDetailEvents)
        { isLoading, accountDetailEvent in
            isLoading || accountDetailEvent.element?.prepaidStatus != .active
        }
        .startWith(true)
        .distinctUntilChanged()
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var showButtonStack: Driver<Bool> = Observable
        .combineLatest(fetchTracker.asObservable(),
                       accountDetailEvents)
        { isLoading, accountDetailEvent in
            accountDetailEvent.error == nil && !isLoading &&
                accountDetailEvent.element?.prepaidStatus != .active
        }
        .startWith(false)
        .distinctUntilChanged()
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var showPrepaidCard: Driver<Bool> = Observable
        .combineLatest(fetchTracker.asObservable(),
                       accountDetailEvents)
        { isLoading, accountDetailEvent in
            !isLoading && accountDetailEvent.element?.prepaidStatus == .active
        }
        .startWith(false)
        .distinctUntilChanged()
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var showMakeAPaymentButton: Driver<Bool> = accountDetail
        .map { $0.billingInfo.netDueAmount ?? 0 > 0 || (Environment.shared.opco == .bge || Environment.shared.opco.isPHI) }
        .asDriver(onErrorDriveWith: .empty())

    private lazy var accountDetailNoNetwork: Observable<Bool> = accountDetailEvents
        .map { ($0.error as? NetworkingError) == .noNetwork }

    private lazy var recentPaymentsNoNetwork: Observable<Bool> = scheduledPaymentEvents
        .map { ($0.error as? NetworkingError) == .noNetwork }

    private(set) lazy var showNoNetworkConnectionView: Driver<Bool> = Observable
        .combineLatest(accountDetailNoNetwork, recentPaymentsNoNetwork) { $0 || $1 }
        .startWith(false)
        .distinctUntilChanged()
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var makePaymentScheduledPaymentAlertInfo: Observable<(String?, String?, AccountDetail)> = Observable
        .combineLatest(accountDetail, scheduledPayment)
        .map { accountDetail, scheduledPayment in
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
}
