//
//  UsageService+Rx.swift
//  Mobile
//
//  Created by Cody Dillon on 7/14/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

extension UsageService: ReactiveCompatible {}

extension Reactive where Base == UsageService {
    
    static func compareBill(accountNumber: String, premiseNumber: String, yearAgo: Bool, gas: Bool, useCache: Bool = true) -> Observable<CompareBillResult> {
        return Observable.create { observer -> Disposable in
            UsageService.compareBill(accountNumber: accountNumber, premiseNumber: premiseNumber, yearAgo: yearAgo, gas: gas, useCache: useCache) { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
    
    static func fetchBillForecast(accountNumber: String, premiseNumber: String, useCache: Bool = true) -> Observable<BillForecastResult> {
        return Observable.create { observer -> Disposable in
            UsageService.fetchBillForecast(accountNumber: accountNumber, premiseNumber: premiseNumber, useCache: useCache) { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
    
    static func fetchHomeProfile(accountNumber: String, premiseNumber: String) -> Observable<HomeProfile> {
        return Observable.create { observer -> Disposable in
            UsageService.fetchHomeProfile(accountNumber: accountNumber, premiseNumber: premiseNumber) { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
    
    static func updateHomeProfile(accountNumber: String, premiseNumber: String, request: HomeProfileUpdateRequest) -> Observable<Void> {
        return Observable.create { observer -> Disposable in
            UsageService.updateHomeProfile(accountNumber: accountNumber, premiseNumber: premiseNumber, request: request) { result in
                switch result {
                case .success(_):
                    observer.onNext(())
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    static func fetchEnergyTips(accountNumber: String, premiseNumber: String) -> Observable<[EnergyTip]> {
        return Observable.create { observer -> Disposable in
            UsageService.fetchEnergyTips(accountNumber: accountNumber, premiseNumber: premiseNumber) { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
    
    static func fetchEnergyTipByName(accountNumber: String, premiseNumber: String, tipName:String) -> Observable<EnergyTip> {
           return Observable.create { observer -> Disposable in
            UsageService.fetchEnergyTipByName(accountNumber: accountNumber, premiseNumber: premiseNumber, tipName: tipName) { observer.handle(result: $0) }
               return Disposables.create()
           }
       }
}
