//
//  HomeViewModel.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 7/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

class HomeViewModel {
    
    let disposeBag = DisposeBag()
    
    private var accountService: AccountService
    
    let fetchAccountDetail = PublishSubject<FetchingAccountState>()
    let currentAccountDetail = Variable<AccountDetail?>(nil)
    let isFetchingAccountDetail: Driver<Bool>
    let accountDetailErrorMessage: Driver<String>
    
    let greeting = Variable<String>("")
    let weatherTemp = Variable<String?>(nil)
    let weatherIcon = Variable<UIImage?>(nil)
    
    required init(accountService: AccountService) {
        self.accountService = accountService
        
        let fetchingAccountDetailTracker = ActivityTracker()
        isFetchingAccountDetail = fetchingAccountDetailTracker.asDriver()
        
        let sharedFetchAccountDetail = fetchAccountDetail.share()
        
        sharedFetchAccountDetail
            .filter { $0 != .refresh }
            .map { _ in nil }
            .bind(to: currentAccountDetail)
            .addDisposableTo(disposeBag)
        
        let fetchAccountDetailResult = sharedFetchAccountDetail
            .flatMapLatest { _ in
                accountService.fetchAccountDetail(account: AccountsStore.sharedInstance.currentAccount)
                    .retry(.exponentialDelayed(maxCount: 2, initial: 2.0, multiplier: 1.5))
                    .trackActivity(fetchingAccountDetailTracker)
                    .materialize()
            }
            .shareReplay(1)
        
        fetchAccountDetailResult.elements()
            .bind(to: currentAccountDetail)
            .addDisposableTo(disposeBag)
        
        //bind this to fetchAccountDetailRequest to ensure address is available on sign in/keep me logged in
        let weatherItemResponse = fetchAccountDetailResult.elements().map { $0.address ?? "" }
        .flatMap(WeatherAPI().fetchWeather).shareReplay(2)
        
        weatherItemResponse.map { $0.temperature.stringValue + "°" }
            .bind(to: self.weatherTemp)
            .addDisposableTo(self.disposeBag)
            
        weatherItemResponse.map { $0.icon }
            .bind(to: self.weatherIcon)
            .addDisposableTo(self.disposeBag)
        
        weatherItemResponse.map { $0.greeting }
            .bind(to: self.greeting)
            .addDisposableTo(self.disposeBag)
        
        accountDetailErrorMessage = fetchAccountDetailResult.errors()
            .map { 
                if let serviceError = $0 as? ServiceError {
                    if serviceError.serviceCode == ServiceErrorCode.FnNotFound.rawValue {
                        return NSLocalizedString(ServiceErrorCode.TcUnknown.rawValue, comment: "")
                    } else {
                        return serviceError.localizedDescription
                    }
                } else {
                    return $0.localizedDescription
                }
            }
            .asDriver(onErrorJustReturn: "")
    }
    
    func fetchAccountDetail(isRefresh: Bool) {
        fetchAccountDetail.onNext(isRefresh ? .refresh: .switchAccount)
    }
    
    lazy var currentAccountDetailUnwrapped: Driver<AccountDetail> = self.currentAccountDetail.asObservable()
        .unwrap()
        .asDriver(onErrorDriveWith: Driver.empty())
    
    lazy var isFetchingDifferentAccount: Driver<Bool> = self.currentAccountDetail.asDriver().map { $0 == nil }    
    
}
