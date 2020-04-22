//
//  OutageServiceNew.swift
//  Mobile
//
//  Created by Cody Dillon on 4/22/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct OutageServiceNew {
    static func fetchOutageStatus(account: Account, completion: @escaping (Result<Void, NetworkingError>) -> ()) {
        var path = "accounts/\(account.accountNumber)/outage?meterPing=false"
        if StormModeStatus.shared.isOn && Environment.shared.opco != .bge {
            path.append("&summary=true")
        }
        return MCSApi.shared.get(pathPrefix: .auth, path: path)
            .map { jsonArray in
                guard let outageStatusArray = jsonArray as? NSArray else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                if account.isMultipremise {
                    let outageStatusModels = outageStatusArray.map { $0 as! NSDictionary }
                    guard let premiseNumber = account.currentPremise?.premiseNumber,
                        let dict = outageStatusModels.filter({ $0["premiseNumber"] as? String == premiseNumber }).first,
                        let outageStatus = OutageStatus.from(dict as NSDictionary) else {
                            throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                    }
                    
                    return outageStatus
                } else {
                    guard let dict = outageStatusArray[0] as? NSDictionary,
                        let outageStatus = OutageStatus.from(dict) else {
                            throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                    }
                    
                    return outageStatus
                }
            }
    }
}
