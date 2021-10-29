//
//  MoveServiceResponse.swift
//  EUMobile
//
//  Created by RAMAITHANI on 18/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public struct MoveServiceResponse: Decodable {
    
    let isFinalStepResult: Bool
    let confirmationNo: String?
    let isManualCallResult: Bool
    let confirmationMessage: String
    let stopDate: String
    let stopAddress: StopAddress?
    let startDate: String
    let startAddress: StartAddress?
    let remoteShutoffCapable:  Bool?
    let accountNumber: String
    let finalBillEmail: String?
    let useAltBillingAddress: Bool?
    let finalBillAddress: FinalBillAddress?
    let isResolved: Bool?
    let isServiceChargeFee: Bool?
    
    enum CodingKeys: String, CodingKey {
        
        case isFinalStepResult = "IsFinalStepResult"
        case confirmationNo = "ConfirmationNo"
        case isManualCallResult = "IsManualCallResult"
        case confirmationMessage = "ConfirmationMessage"
        case stopDate, stopAddress, startDate, startAddress, remoteShutoffCapable, accountNumber, finalBillEmail, useAltBillingAddress, finalBillAddress, isResolved, isServiceChargeFee
    }
    
    struct StopAddress: Decodable {
        
        let address: String
        let streetName: String
        let city: String
        let state: String
        let zipCode: String
        let premiseID: String?
        let accountNumber: String?

        enum CodingKeys: String, CodingKey {
            
            case address = "Address"
            case streetName = "StreetName"
            case city = "City"
            case state = "State"
            case zipCode = "ZipCode"
            case premiseID = "PremiseID"
            case accountNumber = "AccountNumber"
        }
    }
    
    struct StartAddress: Decodable {
        
        let streetName: String?
        let houseNo: String?
        let apartmentUnitNo: String?
        let city: String
        let zipCode: String
        let state: String
        let country: String?

        enum CodingKeys: String, CodingKey {
            
            case streetName = "StreetName"
            case houseNo = "HouseNo"
            case apartmentUnitNo = "ApartmentUnitNo"
            case city = "City"
            case zipCode = "ZipCode"
            case state = "State"
            case country = "Country"
        }
    }
    
    struct FinalBillAddress: Decodable {
        
        let streetName: String?
        let apartmentUnitNo: String?
        let houseNo: String?
        let city: String
        let state: String
        let zipCode: String

        enum CodingKeys: String, CodingKey {
            
            case streetName = "StreetName"
            case apartmentUnitNo = "ApartmentUnitNo"
            case houseNo = "HouseNo"
            case city = "City"
            case state = "State"
            case zipCode = "ZipCode"
        }
    }
}
