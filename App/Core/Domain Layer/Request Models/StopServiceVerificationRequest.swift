//
//  StopServiceVerificationRequest.swift
//  Mobile
//
//  Created by RAMAITHANI on 28/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public struct StopServiceVerificationRequest: Encodable {
    
    var startStopMoveDetails: StartStopMoveDetailsRequest = StopServiceVerificationRequest.StartStopMoveDetailsRequest()
    
    enum CodingKeys: String, CodingKey {
        
        case startStopMoveDetails = "StartStopMoveDetails"
    }
    
    struct StartStopMoveDetailsRequest: Encodable {
        
        var stopServiceAddress: StopServiceAddressRequest = StopServiceAddressRequest()
        
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

            init() {
                self.city = AccountsStore.shared.currentAccount.currentPremise?.townDetail.name ?? ""
                self.state = AccountsStore.shared.currentAccount.currentPremise?.townDetail.stateOrProvince ?? ""
                self.zipCode = AccountsStore.shared.currentAccount.currentPremise?.townDetail.code ?? ""
                self.premiseID = AccountsStore.shared.currentAccount.currentPremise?.premiseNumber ?? ""
                self.accountNumber = AccountsStore.shared.currentAccount.accountNumber
                self.customerID = AccountsStore.shared.currentAccount.customerNumber ?? ""
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
