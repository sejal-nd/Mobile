//
//  ThirdPartyTransferEligibilityResponse.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 6/14/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import Foundation

public struct ThirdPartyTransferEligibilityResponse: Decodable {
    public let isEligible: Bool
    public let seamlessflag: String
    public let queryStartPayload: QueryStartPayload?
    
    enum CodingKeys: String, CodingKey {
        case seamlessflag = "seamlessflag"
        case queryStartPayload = "queryStartPayload"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        seamlessflag = try container.decode(String.self, forKey: .seamlessflag)// ?? "N"
        queryStartPayload = try container.decodeIfPresent(QueryStartPayload.self, forKey: .queryStartPayload)
        isEligible = seamlessflag.lowercased() == "y"
    }
}

// MARK: - QueryStartPayload

public struct QueryStartPayload: Codable {
    public let startServiceResultForSecondStep: StartServiceResultForSecondStep
    public let noun: String
    
    enum CodingKeys: String, CodingKey {
        case startServiceResultForSecondStep = "StartServiceResultForSecondStep"
        case noun = "Noun"
    }
}

// MARK: - StartServiceResultForSecondStep

public struct StartServiceResultForSecondStep: Codable {
    public let serviceOrderID, packageID: String?
    public let rcdCapable, serviceOff, appointmentRequired: Bool
    public let firstAvailableDate: FirstAvailableDate
    
    enum CodingKeys: String, CodingKey {
        case serviceOrderID = "ServiceOrderID"
        case packageID = "PackageID"
        case rcdCapable = "RCDCapable"
        case serviceOff = "ServiceOff"
        case appointmentRequired = "AppointmentRequired"
        case firstAvailableDate = "FirstAvailableDate"
    }
}

// MARK: - FirstAvailableDate

public struct FirstAvailableDate: Codable {
    public let startDateTime, endDateTime: String?
    
    enum CodingKeys: String, CodingKey {
        case startDateTime = "StartDateTime"
        case endDateTime = "EndDateTime"
    }
}
