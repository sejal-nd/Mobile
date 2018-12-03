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
    
    /// Fetch the outage status for a given Account.
    ///
    /// - Parameters:
    ///   - account: the account to fetch outage status for
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain the OutageStatus on success, or a ServiceError on failure.
    func fetchOutageStatus(account: Account, completion: @escaping (_ result: ServiceResult<OutageStatus>) -> Void)
    
    /// Fetch the meter data for a given Account.
    ///
    /// - Parameters:
    ///   - account: the account to fetch outage status for
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain the MeterPingInfo on success, or a ServiceError on failure.
    func pingMeter(account: Account, completion: @escaping (_ result: ServiceResult<MeterPingInfo>) -> Void)
    
    /// Report an outage for the current customer.
    ///
    /// - Parameters:
    ///   - outageInfo: the outage information to report
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain a ServiceError on failure.
    func reportOutage(outageInfo: OutageInfo, completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
    func getReportedOutageResult(accountNumber: String) -> ReportedOutageResult?
    
    func fetchOutageStatusAnon(phoneNumber: String?, accountNumber: String?, completion: @escaping (_ result: ServiceResult<[OutageStatus]>) -> Void)
    
    func reportOutageAnon(outageInfo: OutageInfo, completion: @escaping (_ result: ServiceResult<ReportedOutageResult>) -> Void)
}

// MARK: - Reactive Extension to OutageService
extension OutageService {
    
    func fetchOutageStatus(account: Account) -> Observable<OutageStatus> {
        return Observable.create { observer in
            self.fetchOutageStatus(account: account, completion: { (result: ServiceResult<OutageStatus>) in
                switch result {
                case ServiceResult.success(let outageStatus):
                    observer.onNext(outageStatus)
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }

            })
            return Disposables.create()
        }
    }
    
    func reportOutage(outageInfo: OutageInfo) -> Observable<Void> {
        return Observable.create { observer in
            self.reportOutage(outageInfo: outageInfo, completion: { (result: ServiceResult<Void>) in
                switch result {
                case ServiceResult.success:
                    observer.onNext(())
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    func fetchOutageStatusAnon(phoneNumber: String?, accountNumber: String?) -> Observable<[OutageStatus]> {
        return Observable.create { observer in
            self.fetchOutageStatusAnon(phoneNumber: phoneNumber, accountNumber: accountNumber, completion: { (result: ServiceResult<[OutageStatus]>) in
                switch result {
                case ServiceResult.success(let outageStatusArray):
                    observer.onNext(outageStatusArray)
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
                
            })
            return Disposables.create()
        }
    }
    
    func reportOutageAnon(outageInfo: OutageInfo) -> Observable<ReportedOutageResult> {
        return Observable.create { observer in
            self.reportOutageAnon(outageInfo: outageInfo, completion: { (result: ServiceResult<ReportedOutageResult>) in
                switch result {
                case ServiceResult.success(let reportedOutageResult):
                    observer.onNext(reportedOutageResult)
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    func pingMeter(account: Account) -> Observable<MeterPingInfo> {
        return Observable.create { observer in
            self.pingMeter(account: account, completion: { (result: ServiceResult<MeterPingInfo>) in
                switch result {
                case ServiceResult.success(let outageStatus):
                    observer.onNext(outageStatus)
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }

}
