//
//  StopServiceVerificationRequest.swift
//  Mobile
//
//  Created by RAMAITHANI on 28/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public struct StopServiceVerificationRequest: Encodable {
    
    var startStopMoveDetails: StartStopMoveDetailsRequest

    init(accountDetails: UnAuthAccountDetails? = nil) {
        
        startStopMoveDetails = StopServiceVerificationRequest.StartStopMoveDetailsRequest(accountDetails: accountDetails)
    }

    enum CodingKeys: String, CodingKey {
        
        case startStopMoveDetails = "StartStopMoveDetails"
    }
    
    struct StartStopMoveDetailsRequest: Encodable {
        
        var stopServiceAddress: StopServiceAddressRequest
        
        init(accountDetails: UnAuthAccountDetails? = nil) {
            stopServiceAddress = StopServiceAddressRequest(accountDetails: accountDetails)
        }

        enum CodingKeys: String, CodingKey {
            
            case stopServiceAddress = "StopServiceAddress"
        }
        
        struct StopServiceAddressRequest: Encodable {
            
            var city: String
            var state: String
            let zipCode: String
            let premiseID: String
            let accountNumber: String
            let customerID: String

            init(accountDetails: UnAuthAccountDetails? = nil) {
                self.city = accountDetails != nil ? (accountDetails?.city ?? "") : (AccountsStore.shared.currentAccount.currentPremise?.townDetail.name ?? "")
                self.state = accountDetails != nil ? (accountDetails?.state ?? "") : (AccountsStore.shared.currentAccount.currentPremise?.townDetail.stateOrProvince ?? "")
                self.zipCode = accountDetails != nil ? (accountDetails?.zipCode ?? "") : AccountsStore.shared.currentAccount.currentPremise?.townDetail.code ?? ""
                self.premiseID = accountDetails != nil ? (accountDetails?.premiseNumber ?? "") : AccountsStore.shared.currentAccount.currentPremise?.premiseNumber ?? ""
                self.accountNumber = accountDetails != nil ? (accountDetails?.accountNumber ?? "") : AccountsStore.shared.currentAccount.accountNumber
                self.customerID = accountDetails != nil ? (accountDetails?.state ?? "") : AccountsStore.shared.currentAccount.customerNumber ?? ""
            }

            enum CodingKeys: String, CodingKey {
                case city = "City"
                case state = "State"
                case premiseID = "PremiseID"
                case zipCode = "ZipCode"
                case customerID = "CustomerID"
                case accountNumber = "AccountNumber"
             }
        }
    }
    
    
}
