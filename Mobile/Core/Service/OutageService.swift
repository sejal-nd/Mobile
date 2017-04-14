//
//  OutageService.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

/// The AccountService protocol defines the interface necessary
/// to deal with fetching and updating Outage info associated with
/// the currently logged in customer and their accounts.
protocol OutageService {
    
    var outageMap: [String: ReportedOutageResult] { get set }
    
    /// Fetch the outage status for a given Account.
    ///
    /// - Parameters:
    ///   - account: the account to fetch outage status for
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain the OutageStatus on success, or a ServiceError on failure.
    func fetchOutageStatus(account: Account, completion: @escaping (_ result: ServiceResult<OutageStatus>) -> Void)
    
    
    /// Report an outage for the current customer.
    ///
    /// - Parameters:
    ///   - outageInfo: the outage information to report
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain a ServiceError on failure.
    func reportOutage(outageInfo: OutageInfo, completion: @escaping (_ result: ServiceResult<Void>) -> Void)
}

// MARK: - Reactive Extension to OutageService
extension OutageService {
    
    func fetchOutageStatus(account: Account) -> Observable<OutageStatus> {
        return Observable.create { observer in
            self.fetchOutageStatus(account: account, completion: { (result: ServiceResult<OutageStatus>) in
                switch result {
                case ServiceResult.Success(let outageStatus):
                    observer.onNext(outageStatus)
                    observer.onCompleted()
                    break
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                    break
                }

            })
            return Disposables.create()
        }
    }
    
    func reportOutage(outageInfo: OutageInfo) -> Observable<Void> {
        return Observable.create { observer in
            self.reportOutage(outageInfo: outageInfo, completion: { (result: ServiceResult<Void>) in
                switch result {
                case ServiceResult.Success:
                    observer.onNext()
                    observer.onCompleted()
                    break
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                    break
                }
            })
            return Disposables.create()
        }
    }
    
}
