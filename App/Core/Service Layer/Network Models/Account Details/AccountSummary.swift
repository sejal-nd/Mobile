//
//  AccountSummary.swift
//  Mobile
//
//  Created by Cody Dillon on 12/14/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public struct AccountSummary: Decodable {
    public var accountNumber: String
    public var premiseInfo: [AccountSummary.PremiseInfo]?
    
    enum CodingKeys: String, CodingKey {
        case accountNumber
        case premiseInfo = "PremiseInfo"
    }
    
    var isOutageTrackerAvailable: Bool {
        return premiseInfo?.first?.deviceId != nil && premiseInfo?.first?.servicePointId != nil
    }
    
    var deviceId: String? {
        return premiseInfo?.first?.deviceId
    }
    
    var servicePointId: String? {
        return premiseInfo?.first?.servicePointId
    }
    
    public struct PremiseInfo: Decodable {
        public var premiseNumber: String?
        public var deviceId: String?
        public var servicePointId: String?
        
        enum CodingKeys: String, CodingKey {
            case premiseNumber
            case deviceId = "deviceID"
            case servicePointId = "servicePointID"
        }
    }
}
