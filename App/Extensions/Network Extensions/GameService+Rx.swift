//
//  GameService+Rx.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/5/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

extension GameService: ReactiveCompatible {}
extension Reactive where Base == GameService {
    static func fetchGameUser(accountNumber: String) -> Observable<GameUser?> {
        return Observable.create { observer -> Disposable in
            GameService.fetchGameUser(accountNumber: accountNumber) { result in
                switch result {
                case .success(let gameUser):
                    observer.onNext(gameUser)
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }

    static func updateGameUser(accountNumber: String, request: GameUserRequest) -> Observable<GameUser> {
        return Observable.create { observer -> Disposable in
            GameService.updateGameUser(accountNumber: accountNumber, request: request) { result in
                switch result {
                case .success(let gameUser):
                    observer.onNext(gameUser)
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    static func updateGameUserGiftSelections(accountNumber: String) -> Observable<GameUser> {
        return Observable.create { observer -> Disposable in
            GameService.updateGameUserGiftSelections(accountNumber: accountNumber) { result in
                switch result {
                case .success(let gameUser):
                    observer.onNext(gameUser)
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    static func fetchDailyUsage(accountNumber: String, premiseNumber: String, gas: Bool) -> Observable<DailyUsageData> {
        return Observable.create { observer -> Disposable in
            GameService.fetchDailyUsage(accountNumber: accountNumber, premiseNumber: premiseNumber, gas: gas) { result in
                switch result {
                case .success(let dailyUsage):
                    observer.onNext(dailyUsage)
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
}

