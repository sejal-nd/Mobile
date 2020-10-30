//
//  AlertService+Rx.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/5/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

extension AlertService: ReactiveCompatible {}
extension Reactive where Base == AlertService {
    static func fetchAlertPreferences(accountNumber: String) -> Observable<AlertPreferences> {
        return Observable.create { observer -> Disposable in
            AlertService.fetchAlertPreferences(accountNumber: accountNumber) { result in
                switch result {
                case .success(let preferences):
                    observer.onNext(preferences)
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    static func setAlertPreferences(accountNumber: String, request: AlertPreferencesRequest) -> Observable<Void> {
        return Observable.create { observer -> Disposable in
            AlertService.setAlertPreferences(accountNumber: accountNumber, request: request) { result in
                switch result {
                case .success:
                    observer.onNext(())
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    static func fetchAlertBanner(bannerOnly: Bool, stormOnly: Bool) -> Observable<[Alert]> {
        return Observable.create { observer -> Disposable in
            AlertService.fetchAlertBanner(bannerOnly: bannerOnly, stormOnly: stormOnly) { result in
                switch result {
                case .success(let alerts):
                    observer.onNext(alerts)
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    static func fetchAlertLanguage(accountNumber: String) -> Observable<String> {
        return Observable.create { observer -> Disposable in
            AlertService.fetchAlertLanguage(accountNumber: accountNumber) { result in
                                switch result {
                case .success(let language):
                    observer.onNext(language)
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    static func setAlertLanguage(accountNumber: String, request: AlertLanguageRequest) -> Observable<Void> {
        return Observable.create { observer -> Disposable in
            AlertService.setAlertLanguage(accountNumber: accountNumber, request: request) { result in
                switch result {
                case .success:
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
}
