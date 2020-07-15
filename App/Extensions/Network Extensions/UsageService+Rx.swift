//
//  UsageService+Rx.swift
//  Mobile
//
//  Created by Cody Dillon on 7/14/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

extension UsageServiceNew: ReactiveCompatible {}

extension Reactive where Base == UsageServiceNew {
    
    static func compareBill(accountNumber: String, premiseNumber: String, yearAgo: Bool, gas: Bool) -> Observable<NewCompareBillResult> {
        return Observable.create { observer -> Disposable in
            UsageServiceNew.compareBill(accountNumber: accountNumber, premiseNumber: premiseNumber, yearAgo: yearAgo, gas: gas) { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
    
    static func fetchBillForecast(accountNumber: String, premiseNumber: String, useCache: Bool = false) -> Observable<NewBillForecastResult> {
        return Observable.create { observer -> Disposable in
            UsageServiceNew.fetchBillForecast(accountNumber: accountNumber, premiseNumber: premiseNumber, useCache: useCache) { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
    
    static func fetchHomeProfile(accountNumber: String, premiseNumber: String) -> Observable<HomeProfileLoadNew> {
        return Observable.create { observer -> Disposable in
            UsageServiceNew.fetchHomeProfile(accountNumber: accountNumber, premiseNumber: premiseNumber) { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
    
    static func updateHomeProfile(accountNumber: String, premiseNumber: String, request: HomeProfileUpdateRequest) -> Observable<Void> {
        return Observable.create { observer -> Disposable in
            UsageServiceNew.updateHomeProfile(accountNumber: accountNumber, premiseNumber: premiseNumber, request: request) { result in
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
    
    static func fetchEnergyTips(accountNumber: String, premiseNumber: String) -> Observable<[NewEnergyTip]> {
        return Observable.create { observer -> Disposable in
            UsageServiceNew.fetchEnergyTips(accountNumber: accountNumber, premiseNumber: premiseNumber) { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
    
    static func fetchEnergyTipByName(accountNumber: String, premiseNumber: String, tipName:String) -> Observable<NewEnergyTip> {
           return Observable.create { observer -> Disposable in
            UsageServiceNew.fetchEnergyTipByName(accountNumber: accountNumber, premiseNumber: premiseNumber, tipName: tipName) { observer.handle(result: $0) }
               return Disposables.create()
           }
       }
}
