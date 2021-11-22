//
//  StopServiceResponse.swift
//  Mobile
//
//  Created by RAMAITHANI on 29/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public struct StopServiceResponse: Decodable {
    
    let confirmationNo: String?
    let isManualCallResult: Bool?
    let confirmationMessage: String
    let stopDate: String?
    let stopAddress: StopAddress?
    let accountNumber: String?
    let finalBillEmail: String?
    let finalBillAddress: FinalBillAddress?
    let isResolved: Bool?
    let remoteShutoffCapable: Bool?
    let appointmentRequested: Bool?
    var isEBillEnrollment: Bool?

    enum CodingKeys: String, CodingKey {
        
        case confirmationNo = "ConfirmationNo"
        case isManualCallResult = "IsManualCallResult"
        case confirmationMessage = "ConfirmationMessage"
        case stopDate, stopAddress, accountNumber, finalBillEmail, finalBillAddress, isResolved, remoteShutoffCapable, appointmentRequested
    }
    
    struct StopAddress: Decodable {
        
        let premiseID: String?
        let accountNumber: String?
        let streetName: String
        let city: String
        let state: String
        let country: String
        let zipCode: String

        enum CodingKeys: String, CodingKey {
            
            case premiseID = "PremiseID"
            case accountNumber = "AccountNumber"
            case streetName = "StreetName"
            case city = "City"
            case state = "State"
            case country = "Country"
            case zipCode = "ZipCode"
        }
    }
    
    struct FinalBillAddress: Decodable {
        
        let streetName: String
        let city: String
        let state: String
        let zipCode: String

        enum CodingKeys: String, CodingKey {
            
            case streetName = "StreetName"
            case city = "City"
            case state = "State"
            case zipCode = "ZipCode"
        }
    }
}
