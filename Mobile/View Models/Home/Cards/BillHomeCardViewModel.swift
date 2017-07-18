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
    
    let bag = DisposeBag()
    
    private let accountService: AccountService
    private let walletService: WalletService
    
    private let accountDetail = Variable<AccountDetail?>(nil)
    private let walletItem = Variable<WalletItem?>(nil)
    
    let account: Variable<Account>
    
    private let loadingTracker = ActivityTracker()
    
    init(withAccount account: Account, accountService: AccountService, walletService: WalletService) {
        self.accountService = accountService
        self.walletService = walletService
        
        self.account = Variable(account)
        
        fetchResult.elements().map { $0.0 }.bind(to: accountDetail).addDisposableTo(bag)
        fetchResult.elements().map { $0.1 }.bind(to: walletItem).addDisposableTo(bag)
        
    }

    private(set) lazy var fetchResult: Observable<Event<(AccountDetail, WalletItem?)>> = self.account.asObservable()
        .flatMapLatest(self.fetchData)
        .materialize()
        .share()
    
    private func fetchData(forAccount account: Account) -> Observable<(AccountDetail, WalletItem?)> {
        return Observable.zip(fetchAccountDetails(forAccount: account), fetchOTPWalletItem())
    }
    
    private func fetchAccountDetails(forAccount account: Account) -> Observable<AccountDetail> {
        return accountService.fetchAccountDetail(account: account)
            .trackActivity(loadingTracker)
    }
    
    private func fetchOTPWalletItem() -> Observable<WalletItem?> {
        return walletService.fetchWalletItems()
            .trackActivity(loadingTracker)
            .map { $0.first(where: { $0.isDefault }) }
    }
    
    
    private(set) lazy var isLoading: Driver<Bool> = self.loadingTracker.asDriver()
    
    
    //MARK: - Loaded States
    
    // TODO: Implement proper logic for billNotReady.
    private(set) lazy var billNotReady: Driver<Bool> = self.accountDetail.asDriver().map { _ in false }
    
    private(set) lazy var errorOccurred: Driver<Bool> = Driver.combineLatest(self.isLoading,
                                                                             self.accountDetail.asDriver(),
                                                                             self.walletItem.asDriver())
        .map { !$0 && $1 == nil && $2 == nil }
    
    private(set) lazy var isAutoPay: Driver<Bool>  = self.accountDetail.asDriver().map { $0?.isAutoPay == true }
    
    private(set) lazy var paymentScheduled: Driver<Bool>  = self.accountDetail.asDriver().map { $0?.billingInfo.scheduledPaymentAmount != nil }
    
    private(set) lazy var paymentPending: Driver<Bool>  = self.accountDetail.asDriver().map { $0?.billingInfo.pendingPaymentAmount != nil }
    
    private(set) lazy var billPaid: Driver<Bool>  = self.accountDetail.asDriver().map { $0?.billingInfo.netDueAmount == 0 }
    
    // Just a temporary function so I can try to wrap my head around the logic of this mess
    func parseData(accountDetail: AccountDetail, walletItem: WalletItem?) {
        if false { // logic not yet specified
            // show not ready state
        } else if walletItem == nil {
            // show:
            // "Your bill is ready"
            // Amount
            // due date
            // "Save a payment account to One Touch Pay" button
            // disabled OTP slider
            // "View Bill" button
        } else if let walletItem = walletItem {
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








