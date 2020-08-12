//
//  PremiseInfo.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/26/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct PremiseInfo: Decodable, Equatable, Hashable {
    public var premiseNumber: String
    
    public var peakRewards: String?
    public var smartEnergyRewards: String?
    
    public var addressGeneral: String?
    public var addressLine: [String]?
    
    public var streetDetail: StreetDetail
    public var townDetail: TownDetail
    
    enum CodingKeys: String, CodingKey {        
        case premiseNumber
        case peakRewards
        case smartEnergyRewards
        
        case mainAddress
        case addressGeneral
        case addressLine
        case streetDetail
        case townDetail
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.premiseNumber = try container.decode(String.self,
                                                  forKey: .premiseNumber)
        self.peakRewards = try container.decodeIfPresent(String.self,
                                                forKey: .peakRewards)
        self.smartEnergyRewards = try container.decodeIfPresent(String.self,
                                                       forKey: .smartEnergyRewards)
        
        let mainAddressContainer = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                                 forKey: .mainAddress)
        self.addressGeneral = try mainAddressContainer.decodeIfPresent(String.self,
                                                              forKey: .addressGeneral)
        self.addressLine = try mainAddressContainer.decodeIfPresent([String].self,
                                                           forKey: .addressLine)
        self.streetDetail = try mainAddressContainer.decode(StreetDetail.self,
                                                            forKey: .streetDetail)
        
        self.townDetail = try mainAddressContainer.decode(TownDetail.self,
                                                          forKey: .townDetail)
    }
    
    var addressLineString: String {
        guard let addressLineArray = addressLine else { return ""}
        return addressLineArray.joined(separator: ",")
    }
    
    // Equatable
    public static func ==(lhs: PremiseInfo, rhs: PremiseInfo) -> Bool {
        return lhs.premiseNumber == rhs.premiseNumber
    }
    
    // Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(premiseNumber)
    }
}

public struct StreetDetail: Decodable {
    public var mRID: String?
    public var name: String?
    public var suffix: String?
}

public struct TownDetail: Decodable {
    public var code: String?
    public var name: String?
    public var stateOrProvince: String?
}


//{
//    "premiseNumber": "9385710000",
//    "mainAddress": {
//        "addressGeneral": "600 N Eutaw St *Apt C Baltimore MD 21201",
//        "addressLine": [
//        "600 N Eutaw St *Apt C"
//        ],
//        "streetDetail": {
//            "mRID": "600",
//            "name": "EUTAW",
//            "suffix": "ST"
//        },
//        "townDetail": {
//            "code": "21201",
//            "name": "Baltimore",
//            "stateOrProvince": "MD"
//        }
//    },
//    "peakRewards": "NONE",
//    "smartEnergyRewards": "ENROLLED",
//    "servicePoints": [
//    {
//    "name": "service",
//    "ServiceLocation": {
//    "mRID": "9385710765",
//    "type": "E-RES3",
//    "status": {
//    "dateTime": "2014-12-05T00:00:00"
//    }
//    },
//    "status": [
//    {
//    "name": "servicePointLocation",
//    "value": "Inside"
//    }
//    ],
//    "UsagePointLocation": {
//    "mRID": "30101270000"
//    }
//    }
//    ]
//}
