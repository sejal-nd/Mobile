//
//  Account.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/24/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct Account: Decodable, Equatable, Hashable {
    var accountNumber: String
    let accountNickname: String?
    let address: String?
    let premises: [PremiseInfo]
    var currentPremise: PremiseInfo?
    
    let status: String?
    let isLinked: Bool
    let isDefault: Bool
    var isFinaled: Bool
    let isResidential: Bool
    let serviceType: String?
    let utilityCode: String?
    let accountStatusCode: String?
    let isPasswordProtected: Bool
    
    enum CodingKeys: String, CodingKey {
        case accountNumber
        case accountNickname
        case address
        case premises = "PremiseInfo"
        case status
        case isLinked = "isLinkedProfile"
        case isDefault = "isDefaultProfile"
        case isFinaled = "flagFinaled"
        case isResidential
        case serviceType
        case utilityCode
        case isPasswordProtected
        case accountStatusCode
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        accountNumber = try container.decode(String.self, forKey: .accountNumber)
        accountNickname = try container.decodeIfPresent(String.self, forKey: .accountNickname)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        premises = try container.decodeIfPresent([PremiseInfo].self, forKey: .premises) ?? []
        currentPremise = premises.first
        
        status = try container.decodeIfPresent(String.self, forKey: .status)
        isLinked = try container.decodeIfPresent(Bool.self, forKey: .isLinked) ?? false
        isDefault = try container.decodeIfPresent(Bool.self, forKey: .isDefault) ?? false
        isFinaled = try container.decodeIfPresent(Bool.self, forKey: .isFinaled) ?? false
        isResidential = try container.decodeIfPresent(Bool.self, forKey: .isResidential) ?? false
        serviceType = try container.decodeIfPresent(String.self, forKey: .serviceType)
        utilityCode = try container.decodeIfPresent(String.self, forKey: .utilityCode)
        isPasswordProtected = try container.decodeIfPresent(Bool.self, forKey: .isPasswordProtected) ?? false
        accountStatusCode = try? container.decodeIfPresent(String.self, forKey: .accountStatusCode)
        if status?.lowercased() == "inactive" {
            isFinaled = true
        }
    }
    
    var isMultipremise: Bool {
        return premises.count > 1 //TODO: could be 0 depending on whether each account has matching default premise
    }
    
    // PHI will return nickname if it exists, otherwise account number is returned
    var displayName: String {
        if Configuration.shared.opco.isPHI {
            if let accountNickname = accountNickname {
                return accountNickname
            } else {
                return accountNumber
            }
        } else {
            return accountNumber
        }
    }
    
    
    /// For PHI ocpos, this variable will return the opco type tagged to a a particular account
    /// Note: Currently the functionality is extended only for PHI opcos
    var opcoType: OpCo? {
        if Configuration.shared.opco.isPHI,
           let utilityCode = utilityCode {
            switch utilityCode {
            case "ACE":
                return .ace
            case "DPL":
                return .delmarva
            case "PEP":
                return .pepco
            default:
                return nil
            }
        }
       return nil
    }

    
    // Equatable
    public static func ==(lhs: Account, rhs: Account) -> Bool {
        return lhs.accountNumber == rhs.accountNumber
    }
    
    // Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(accountNumber)
    }
}

