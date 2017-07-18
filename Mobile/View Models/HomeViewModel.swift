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
    
    private let accountService: AccountService
    private let weatherService: WeatherService
    
    let fetchAccountDetail = PublishSubject<FetchingAccountState>()
    let currentAccountDetail = Variable<AccountDetail?>(nil)
    let isFetchingAccountDetail: Driver<Bool>
    let accountDetailErrorMessage: Driver<String>
    
    private let weatherItem = Variable<WeatherItemResult?>(nil)
    private(set) lazy var greeting: Driver<String?> = self.weatherItem.asDriver().map { $0?.greeting }
    private(set) lazy var weatherTemp: Driver<String?> = self.weatherItem.asDriver().map {
        guard let temperature = $0?.temperature else { return nil }
        return "\(temperature)°"
    }
    private(set) lazy var weatherIcon: Driver<UIImage?> = self.weatherItem.asDriver().map { $0?.icon }
    
    required init(accountService: AccountService, weatherService: WeatherService) {
        self.accountService = accountService
        self.weatherService = weatherService
        
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
        fetchAccountDetailResult.elements().map { $0.address ?? "" }
        .flatMap(weatherService.fetchWeather)
        .bind(to: weatherItem)
        .addDisposableTo(disposeBag)
        
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
