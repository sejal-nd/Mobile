//
//  OutageService.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

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
    func fetchOutageStatus(account: Account, completion: @escaping (_ result: ServiceResult<OutageStatus>) -> Swift.Void)
    
    
    /// Report an outage for the current customer.
    ///
    /// - Parameters:
    ///   - outageInfo: the outage information to report
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain a ServiceError on failure.
    func reportOutage(outageInfo: OutageInfo, completion: @escaping (_ result: ServiceResult<Void>) -> Swift.Void)
}
