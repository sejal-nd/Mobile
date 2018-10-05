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
    func fetchOutageStatus(account: Account) -> Observable<OutageStatus>
    
    /// Fetch the meter data for a given Account.
    ///
    /// - Parameters:
    ///   - account: the account to fetch outage status for
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain the MeterPingInfo on success, or a ServiceError on failure.
    func pingMeter(account: Account) -> Observable<MeterPingInfo>
    
    /// Report an outage for the current customer.
    ///
    /// - Parameters:
    ///   - outageInfo: the outage information to report
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain a ServiceError on failure.
    func reportOutage(outageInfo: OutageInfo) -> Observable<Void>
    
    func getReportedOutageResult(accountNumber: String) -> ReportedOutageResult?
    
    func fetchOutageStatusAnon(phoneNumber: String?, accountNumber: String?) -> Observable<[OutageStatus]>
    
    func reportOutageAnon(outageInfo: OutageInfo) -> Observable<ReportedOutageResult>
}
