//
//  BillHomeCard.swift
//  Mobile
//
//  Created by Sam Francis on 7/17/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class HomeBillCardViewModel {
    
    enum BillCardState {
        case error, avoidShutoff, pastDue, due, noBill, credit, payment, paymentPending
    }
    
    let bag = DisposeBag()
    
    private let account: Observable<Account>
    private let accountDetail: Observable<AccountDetail>
    private let walletService: WalletService
    
    private let loadingTracker = ActivityTracker()
    
    required init(withAccount account: Observable<Account>, accountDetail: Observable<AccountDetail>, walletService: WalletService) {
        self.account = account
        self.accountDetail = accountDetail
        self.walletService = walletService
    }
    
    private lazy var walletItem: Observable<WalletItem?> = self.account.map { _ in () }.flatMapLatest(self.fetchOTPWalletItem)

    private(set) lazy var data: Observable<Event<(Account, AccountDetail, WalletItem?)>> = Observable.zip(self.account, self.accountDetail, self.walletItem)
        .materialize()
        .share()
    
    private func fetchOTPWalletItem() -> Observable<WalletItem?> {
        return walletService.fetchWalletItems()
            .trackActivity(loadingTracker)
            .map { $0.first(where: { $0.isDefault }) }
    }
    
    private(set) lazy var isLoading: Driver<Bool> = self.loadingTracker.asDriver()
    
    //MARK: - Loaded States
    
    private lazy var accountDetailDriver: Driver<AccountDetail> = self.data.elements().map { _, detail, _ in detail }.asDriver(onErrorDriveWith: .empty())
    private lazy var walletItemDriver: Driver<WalletItem?> = self.data.elements().map { _, _, walletItem in walletItem }.asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var billNotReady: Driver<Bool> = self.accountDetailDriver.map { _ in false }
    
    private(set) lazy var errorOccurred: Driver<Bool> = Driver.combineLatest(self.isLoading, self.data.asDriver(onErrorDriveWith: .empty()))
        .map { !$0 && $1.error != nil }
    
    private(set) lazy var isAutoPay: Driver<Bool>  = self.accountDetailDriver.map { $0.isAutoPay == true }
    
    private(set) lazy var paymentScheduled: Driver<Bool>  = self.accountDetailDriver.map { $0.billingInfo.scheduledPaymentAmount != nil }
    
    private(set) lazy var paymentPending: Driver<Bool>  = self.accountDetailDriver.map { $0.billingInfo.pendingPaymentAmount != nil }
    
    private(set) lazy var state: Driver<BillCardState> = self.data.map { event -> BillCardState in
        guard let (account, accountDetail, walletItem) = event.element else {
            return .error
        }
        
        let billingInfo = accountDetail.billingInfo
        
        if let paymentDetails = PaymentDetailsStore.shared[account],
            paymentDetails.date.addingTimeInterval(172_800) > Date() {
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
    
    // Just a temporary function so I can try to wrap my head around the logic of this mess
    func parseData(accountDetail: AccountDetail, walletItem: WalletItem?) {
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








