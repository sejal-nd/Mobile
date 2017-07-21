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
    
    private(set) lazy var shouldShowErrorState: Driver<Bool> = Observable.zip(self.accountDetailEvents, self.walletItem)
        .map { $0.0.error != nil }
        .asDriver(onErrorDriveWith: .empty())
    
    
    private(set) lazy var isAutoPay: Driver<Bool>  = self.accountDetailDriver.map { $0.isAutoPay == true }
    
    private(set) lazy var paymentScheduled: Driver<Bool>  = self.accountDetailDriver.map { $0.billingInfo.scheduledPaymentAmount != nil }
    
    private(set) lazy var paymentPending: Driver<Bool>  = self.accountDetailDriver.map { $0.billingInfo.pendingPaymentAmount != nil }
    
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
    
    
    private(set) lazy var titleText: Driver<String?> = self.data.elements()
        .map { account, accountDetail, walletItem in
            let opco = Environment.sharedInstance.opco
            if let _ = accountDetail.billingInfo.restorationAmount { // TODO: Due immediately
                if opco == .bge {
                    return NSLocalizedString("Amount Due to Avoid Service Interruption", comment: "")
                } else {
                    return NSLocalizedString("Amount Due to Avoid Shutoff", comment: "")
                }
            }
            
            if Environment.sharedInstance.opco != .bge {
                if let catchUpAmount = accountDetail.billingInfo.amtDpaReinst,
                    let dueByDate = accountDetail.billingInfo.dueByDate {
                    
                } else if let pastDueAmount = accountDetail.billingInfo.pastDueAmount,
                    let dueByDate = accountDetail.billingInfo.dueByDate { // needs due immediately
                }
            }
            
            return NSLocalizedString("Your bill is ready", comment: "")
        }
        .asDriver(onErrorJustReturn: nil)
    
    private(set) lazy var titleFont: Driver<UIFont?> = self.data.elements()
        .map { account, accountDetail, walletItem in
            if Environment.sharedInstance.opco != .bge {
                if let _ = accountDetail.billingInfo.restorationAmount {
                    return OpenSans.regular.of(textStyle: .headline)
                } else if let catchUpAmount = accountDetail.billingInfo.amtDpaReinst,
                    let dueByDate = accountDetail.billingInfo.dueByDate {
                    
                } else if let pastDueAmount = accountDetail.billingInfo.pastDueAmount,
                    let dueByDate = accountDetail.billingInfo.dueByDate { // needs due immediately
                }
            }
            
            return OpenSans.regular.of(textStyle: .title1)
        }
        .asDriver(onErrorJustReturn: nil)
    
    
    private(set) lazy var shouldShowAlertIcon: Driver<Bool> = self.data.elements()
        .map { account, accountDetail, walletItem in
            let opco = Environment.sharedInstance.opco
            
            if opco != .bge {
                if let _ = accountDetail.billingInfo.restorationAmount {
                    return true
                } else if let catchUpAmount = accountDetail.billingInfo.amtDpaReinst,
                    let dueByDate = accountDetail.billingInfo.dueByDate {
                    
                } else if let pastDueAmount = accountDetail.billingInfo.pastDueAmount,
                    let dueByDate = accountDetail.billingInfo.dueByDate { // needs due immediately
                }
            } else if let restorationAmount = accountDetail.billingInfo.restorationAmount,
                let dueByDate = accountDetail.billingInfo.dueByDate { // needs due immediately
                
            }
            
            // All OpCos
            if let pastDueAmount = accountDetail.billingInfo.pastDueAmount,
                let netDueAmount = accountDetail.billingInfo.netDueAmount { // needs due immediately
                if pastDueAmount == netDueAmount {
                    
                } else {
                    
                }
            }
            return false
        }
        .asDriver(onErrorJustReturn: false)
    
    // Just a temporary function so I can try to wrap my head around the logic of this mess
    func parseData(account: Account, accountDetail: AccountDetail, walletItem: WalletItem?) {
        if false { // bill not ready logic not yet specified // 4.1
            // show not ready state
        } else if let walletItem = walletItem {
            // show:
            // "Your bill is ready"
            // Amount
            // due date
            // "Save a payment account to One Touch Pay" button
            // disabled OTP slider
            // "View Bill" button
            
            let opco = Environment.sharedInstance.opco
            
            // 4.5
            // PECO/ComEd
            if opco != .bge {
                if let restorationAmount = accountDetail.billingInfo.restorationAmount,
                    let dueByDate = accountDetail.billingInfo.dueByDate { // needs due immediately
                    
                } else if let catchUpAmount = accountDetail.billingInfo.amtDpaReinst,
                    let dueByDate = accountDetail.billingInfo.dueByDate {
                    
                } else if let pastDueAmount = accountDetail.billingInfo.pastDueAmount,
                    let dueByDate = accountDetail.billingInfo.dueByDate { // needs due immediately
                }
            } else if let restorationAmount = accountDetail.billingInfo.restorationAmount,
                let dueByDate = accountDetail.billingInfo.dueByDate { // needs due immediately
                
            }
           
            // All OpCos
            if let pastDueAmount = accountDetail.billingInfo.pastDueAmount,
                let netDueAmount = accountDetail.billingInfo.netDueAmount { // needs due immediately
                if pastDueAmount == netDueAmount {
                    
                } else {
                    
                }
            }
            
            
                
            // BGE
            
                
            // 4.6
            else if accountDetail.isAutoPay {
                
            }
            
            // 4.7
            else if let scheduledPaymentDate = accountDetail.billingInfo.scheduledPaymentDate,
                let scheduledPaymentAmount = accountDetail.billingInfo.scheduledPaymentAmount {
                
            }
            
            // 4.8
            else if let pendingPaymentAmount = accountDetail.billingInfo.pendingPaymentAmount {
                
            }
            
            // 4.9
            else if accountDetail.billingInfo.netDueAmount == 0 {
                
            }
            
            // 4.3
            else {
                
            }
        } else { // 4.2
            // show:
            // "Your bill is ready"
            // Amount
            // due date
            // "Save a payment account to One Touch Pay" button
            // disabled OTP slider
            // "View Bill" button
        }
    }
}








