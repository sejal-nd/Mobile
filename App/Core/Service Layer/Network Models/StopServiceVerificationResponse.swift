//
//  StopServiceVerificationResponse.swift
//  Mobile
//
//  Created by RAMAITHANI on 28/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public struct StopServiceVerificationResponse: Decodable {
    
    let startStopMoveServiceDetails: StartStopMoveServiceDetails
    let appointmentExists: Bool
    let appointmentRequired: Bool
    let canStop: Bool
    let isPartialStop: Bool
    let stopExists: Bool
    let availableDates: [AvailableDates]
    let isRCDCapable: Bool
    let serviceLists: [ServiceList]

    enum CodingKeys: String, CodingKey {
        
        case startStopMoveServiceDetails = "StartStopMoveServiceDetails"
        case appointmentExists = "AppointmentExists"
        case appointmentRequired = "AppointmentRequired"
        case canStop = "CanStop"
        case isPartialStop = "IspartialStop"
        case stopExists = "StopExists"
        case availableDates = "AvailableDates"
        case isRCDCapable = "RCDCapable"
        case serviceLists = "ServiceLists"
    }
    
    struct StartStopMoveServiceDetails: Decodable {

        let stopServiceAddress: PremiseID
        let accountNumber: String
        let customerID: String
        let primaryCustInformation: PrimaryCustInformation

        enum CodingKeys: String, CodingKey {
            
            case stopServiceAddress = "StopServiceAddress"
            case accountNumber = "AccountNumber"
            case primaryCustInformation = "PrimaryCustInformation"
            case customerID = "CustomerID"
        }
        
        struct PremiseID: Decodable {

            let premiseID: String

            enum CodingKeys: String, CodingKey {
                
                case premiseID = "PremiseID"
            }
        }
        
        struct PrimaryCustInformation: Decodable {

            let billingAddress: BillingAddress
            let email: String

            enum CodingKeys: String, CodingKey {
                
                case billingAddress = "BillingAddress"
                case email = "Email"
            }
            
            struct BillingAddress: Decodable {

                let streetName: String
                let city: String
                let state: String
                let zipCode: String
                let country: String

                enum CodingKeys: String, CodingKey {
                    
                    case streetName = "StreetName"
                    case city = "City"
                    case state = "State"
                    case zipCode = "ZipCode"
                    case country = "Country"
                }
            }
        }
    }
    
    struct AvailableDates: Decodable {

        let startDateTime: String
        let endDateTime: String

        enum CodingKeys: String, CodingKey {
            
            case startDateTime = "StartDateTime"
            case endDateTime = "EndDateTime"
        }
    }
    
    struct ServiceList: Decodable {

        let stop: Bool
        let serviceAgreementID: String
        let type: String
        let sAType: String
        let sAStatus: String
        let sAEndDate: String?
        let servicePointID: String
        let meterNumber: String?
        let location: String
        let meterLocation: String?
        let appointmentEnd: String?
        let appointmentStart: String?
        let errorMessage: String?
        let hasError: Bool
        let confirmationMessage: String?

        enum CodingKeys: String, CodingKey {
            
            case stop = "Stop"
            case serviceAgreementID = "ServiceAgreementID"
            case type = "Type"
            case sAType = "SAType"
            case sAStatus = "SAStatus"
            case sAEndDate = "SAEndDate"
            case servicePointID = "ServicePointID"
            case meterNumber = "MeterNumber"
            case location = "Location"
            case meterLocation = "MeterLocation"
            case appointmentEnd = "AppointmentEnd"
            case appointmentStart = "AppointmentStart"
            case errorMessage = "ErrorMessage"
            case hasError = "HasError"
            case confirmationMessage = "ConfirmationMessage"
        }
    }
}
