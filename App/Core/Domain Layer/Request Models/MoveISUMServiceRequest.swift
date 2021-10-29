//
//  MoveISUMServiceRequest.swift
//  EUMobile
//
//  Created by RAMAITHANI on 18/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public struct MoveISUMServiceRequest: Encodable {
    
    let startStopMoveDetails: StartStopMoveDetails
    
    init(moveServiceFlowData: MoveServiceFlowData) {
        
        startStopMoveDetails = StartStopMoveDetails(moveServiceFlowData: moveServiceFlowData)
    }
    
    enum CodingKeys: String, CodingKey {
        
        case startStopMoveDetails = "StartStopMoveDetails"
    }

    struct StartStopMoveDetails: Encodable {
        
        let startServiceAddress: StartServiceAddressRequest
        let startServiceDate: String
        let stopServiceDate: String
        let primaryCustInformation: PrimaryCustInformationRequest
        let primaryCustPersIdentification: PrimaryCustPersIdentificationRequest
        let emailAddress: String?
        var isRCDStopCapable: Bool?
        let serviceLists: [ServiceListsRequest]?
        let selectedStopServicePoints: [String]?
        let accountNumber: String
        let rentOwn: String
        let createOnlineProfile: Bool?
        let stopServiceAddress: StopServiceAddressRequest
        
        init(moveServiceFlowData: MoveServiceFlowData) {

            self.startServiceAddress = StartServiceAddressRequest(moveServiceFlowData: moveServiceFlowData)
            self.startServiceDate = DateFormatter.mmDdYyyyFormatter.string(from: moveServiceFlowData.startServiceDate!)
            self.stopServiceDate = DateFormatter.mmDdYyyyFormatter.string(from: moveServiceFlowData.stopServiceDate)
            self.primaryCustInformation = PrimaryCustInformationRequest(moveServiceFlowData: moveServiceFlowData)
            self.primaryCustPersIdentification = PrimaryCustPersIdentificationRequest(moveServiceFlowData: moveServiceFlowData)
            self.emailAddress = moveServiceFlowData.currentAccountDetail.customerInfo.emailAddress
            self.isRCDStopCapable = moveServiceFlowData.verificationDetail?.isRCDCapable
            self.serviceLists = moveServiceFlowData.verificationDetail?.serviceLists.map { ServiceListsRequest(serviceList: $0) }
            self.selectedStopServicePoints = moveServiceFlowData.verificationDetail?.serviceLists.map { $0.servicePointID }
            self.accountNumber = moveServiceFlowData.currentAccountDetail.accountNumber
            self.rentOwn = moveServiceFlowData.isOwner ? "BUYING OR OWNS" : "RENTING"
            self.createOnlineProfile = false
            self.stopServiceAddress = StopServiceAddressRequest(moveServiceFlowData: moveServiceFlowData)
        }

        enum CodingKeys: String, CodingKey {
            
            case startServiceAddress = "StartServiceAddress"
            case startServiceDate = "StartServiceDate"
            case stopServiceDate = "StopServiceDate"
            case primaryCustInformation = "PrimaryCustInformation"
            case primaryCustPersIdentification = "PrimaryCustPersIdentification"
            case emailAddress = "EmailAddress"
            case isRCDStopCapable = "RCDStopCapable"
            case serviceLists = "ServiceLists"
            case selectedStopServicePoints = "SelectedStopServicePoints"
            case accountNumber = "AccountNumber"
            case rentOwn = "RentOwn"
            case createOnlineProfile = "CreateOnlineProfile"
            case stopServiceAddress = "StopServiceAddress"
        }
    }
    
    public struct StartServiceAddressRequest: Encodable {

        let streetName: String?
        let apartmentUnitNo: String?
        let city: String?
        let zipCode: String?
        let accountNumber: String?
        let customerID: String?
        let state: String?
        let country: String?
        let premiseID: String?
        let serviceType: String?
        let meterInfo: [MeterInfoRequest]?
        
        init(moveServiceFlowData: MoveServiceFlowData) {

            self.streetName = moveServiceFlowData.addressLookupResponse?.first?.streetName ?? moveServiceFlowData.addressLookupResponse?.first?.address
            self.apartmentUnitNo = moveServiceFlowData.addressLookupResponse?.first?.apartmentUnitNo
            self.city = moveServiceFlowData.addressLookupResponse?.first?.city
            self.zipCode = moveServiceFlowData.addressLookupResponse?.first?.zipCode
            self.accountNumber = moveServiceFlowData.currentAccountDetail.accountNumber
            self.customerID = moveServiceFlowData.currentAccountDetail.customerNumber
            self.state = moveServiceFlowData.verificationDetail?.startStopMoveServiceDetails.primaryCustInformation.billingAddress.state
            self.country = moveServiceFlowData.verificationDetail?.startStopMoveServiceDetails.primaryCustInformation.billingAddress.country
            self.premiseID = moveServiceFlowData.addressLookupResponse?.first?.premiseID
            self.serviceType = moveServiceFlowData.currentAccountDetail.serviceType
            self.meterInfo = moveServiceFlowData.addressLookupResponse?.first?.meterInfo.map { MeterInfoRequest(meterInfo: $0) }
        }

   
        enum CodingKeys: String, CodingKey {
            
            case streetName = "StreetName"
            case apartmentUnitNo = "ApartmentUnitNo"
            case city = "City"
            case zipCode = "ZipCode"
            case accountNumber = "AccountNumber"
            case customerID = "CustomerID"
            case state = "State"
            case country = "Country"
            case premiseID = "PremiseID"
            case serviceType = "ServiceType"
            case meterInfo = "meterInfo"
        }
        
        public struct MeterInfoRequest: Encodable {

            let meterID: String?
            let meterType: String?
            let isResidential: Bool?
       
            init(meterInfo: AddressLookupResponse.MeterInfo) {

                self.meterID = meterInfo.meterID
                self.meterType = meterInfo.meterType
                self.isResidential = meterInfo.isResidential
            }
            
            enum CodingKeys: String, CodingKey {
                
                case meterID = "meterID"
                case meterType = "meterType"
                case isResidential = "isResidential"
            }
        }
    }
    
    public struct StopServiceAddressRequest: Encodable {

        let address: String?
        let streetName: String?
        let city: String?
        let state: String?
        let zipCode: String?
        let accountNumber: String?
        let premiseID: String?
        
        init(moveServiceFlowData: MoveServiceFlowData) {

            self.address = moveServiceFlowData.currentAccountDetail.address
            self.streetName = moveServiceFlowData.verificationDetail?.startStopMoveServiceDetails.primaryCustInformation.billingAddress.streetName
            self.city = moveServiceFlowData.verificationDetail?.startStopMoveServiceDetails.primaryCustInformation.billingAddress.city
            self.state = moveServiceFlowData.verificationDetail?.startStopMoveServiceDetails.primaryCustInformation.billingAddress.state
            self.zipCode = moveServiceFlowData.verificationDetail?.startStopMoveServiceDetails.primaryCustInformation.billingAddress.zipCode
            self.accountNumber = moveServiceFlowData.verificationDetail?.startStopMoveServiceDetails.accountNumber
            self.premiseID = moveServiceFlowData.verificationDetail?.startStopMoveServiceDetails.stopServiceAddress.premiseID
        }
        
        enum CodingKeys: String, CodingKey {
            
            case address = "Address"
            case streetName = "StreetName"
            case city = "City"
            case state = "State"
            case zipCode = "ZipCode"
            case accountNumber = "AccountNumber"
            case premiseID = "PremiseID"
        }
    }
    
    public struct PrimaryCustPersIdentificationRequest: Encodable {

        let SSNNumber: String?
        let dateOfBirth: String
        let employmentStatus: String?
        let driverLicenseNumber: String?
        let stateOfIssueDriverLincense: String?
        
        init(moveServiceFlowData: MoveServiceFlowData) {

            self.SSNNumber = moveServiceFlowData.idVerification!.ssn
            self.dateOfBirth = DateFormatter.mmDdYyyyFormatter.string(from: moveServiceFlowData.idVerification!.dateOfBirth!)
            self.employmentStatus = moveServiceFlowData.idVerification!.employmentStatus?.0
            self.driverLicenseNumber = moveServiceFlowData.idVerification!.driverLicenseNumber
            self.stateOfIssueDriverLincense = moveServiceFlowData.idVerification!.stateOfIssueDriverLincense
        }
        
        enum CodingKeys: String, CodingKey {
            
            case SSNNumber = "SSNNumber"
            case dateOfBirth = "DateOfBirth"
            case employmentStatus = "EmploymentStatus"
            case driverLicenseNumber = "DriverLicenseNumber"
            case stateOfIssueDriverLincense = "StateOfIssueDriverLincense"
        }
    }

    public struct ServiceListsRequest: Encodable {
        
        let stop: Bool
        let serviceAgreementID: String?
        let type: String
        let sAType: String
        let sAStatus: String
        let sAEndDate: String?
        let servicePointID: String
        let location: String?
        let appointmentEnd: String?
        let appointmentStart: String?
        let errorMessage: String?
        let hasError: Bool
        let confirmationMessage: String?
        
        init(serviceList: StopServiceVerificationResponse.ServiceList) {

            self.stop = serviceList.stop
            self.serviceAgreementID = serviceList.serviceAgreementID
            self.type = serviceList.type
            self.sAType = serviceList.sAType
            self.sAStatus = serviceList.sAStatus
            self.sAEndDate = serviceList.sAEndDate
            self.servicePointID = serviceList.servicePointID
            self.location = serviceList.location
            self.appointmentEnd = serviceList.appointmentEnd
            self.appointmentStart = serviceList.appointmentStart
            self.errorMessage = serviceList.errorMessage
            self.hasError = serviceList.hasError
            self.confirmationMessage = serviceList.confirmationMessage
        }
        
        enum CodingKeys: String, CodingKey {
            
            case stop = "Stop"
            case serviceAgreementID = "ServiceAgreementID"
            case type = "Type"
            case sAType = "SAType"
            case sAStatus = "SAStatus"
            case sAEndDate = "SAEndDate"
            case servicePointID = "ServicePointID"
            case location = "Location"
            case appointmentEnd = "AppointmentEnd"
            case appointmentStart = "AppointmentStart"
            case errorMessage = "ErrorMessage"
            case hasError = "HasError"
            case confirmationMessage = "ConfirmationMessage"
        }
    }

    public struct PrimaryCustInformationRequest: Encodable {
        
        let FirstName: String?
        let LastName: String?
        let address: String?
        let streetName: String?
        let city: String?
        let state: String?
        let zipCode: String?
        let ContactPhoneNo: String?
        let ContactPhoneExt: String?
        let ContactPhoneNoType: String?
        let AltContactPhoneNo: String?
        let AltContactPhoneNoType: String?
        let email: String?
        let useAltBillingAddress: Bool
        let billingAddress: BillingAddressRequest?
        
        init(moveServiceFlowData: MoveServiceFlowData) {
            
            FirstName = moveServiceFlowData.currentAccountDetail.customerInfo.firstName
            LastName = moveServiceFlowData.currentAccountDetail.customerInfo.lastName
            address = moveServiceFlowData.currentAccountDetail.address
            streetName = moveServiceFlowData.currentAccountDetail.street
            city = moveServiceFlowData.currentAccountDetail.city
            state = moveServiceFlowData.currentAccountDetail.state
            zipCode = moveServiceFlowData.currentAccountDetail.zipCode
            ContactPhoneNo = moveServiceFlowData.currentAccountDetail.customerInfo.primaryPhoneNumber
            ContactPhoneExt = ""
            ContactPhoneNoType = ""
            AltContactPhoneNo = moveServiceFlowData.currentAccountDetail.customerInfo.alternatePhoneNumber
            AltContactPhoneNoType = ""
            email = moveServiceFlowData.currentAccountDetail.customerInfo.emailAddress
            useAltBillingAddress = false
            billingAddress = BillingAddressRequest(moveServiceFlowData: moveServiceFlowData)
        }
        
        enum CodingKeys: String, CodingKey {
            
            case FirstName = "FirstName"
            case LastName = "LastName"
            case address = "Address"
            case streetName = "StreetName"
            case city = "City"
            case state = "State"
            case zipCode = "ZipCode"
            case ContactPhoneNo = "ContactPhoneNo"
            case ContactPhoneExt = "ContactPhoneExt"
            case ContactPhoneNoType = "ContactPhoneNoType"
            case AltContactPhoneNo = "AltContactPhoneNo"
            case AltContactPhoneNoType = "AltContactPhoneNoType"
            case email = "Email"
            case useAltBillingAddress = "UseAltBillingAddress"
            case billingAddress = "BillingAddress"
        }
    }

    public struct BillingAddressRequest: Encodable {

        let streetName: String?
        let city: String?
        let state: String?
        let zipCode: String?
        let apartmentUnitNo: String?
        
        init(moveServiceFlowData: MoveServiceFlowData) {
            
            streetName = moveServiceFlowData.currentAccountDetail.premiseInfo.first?.streetDetail.name
            city = moveServiceFlowData.currentAccountDetail.premiseInfo.first?.townDetail.name
            state = moveServiceFlowData.currentAccountDetail.premiseInfo.first?.townDetail.stateOrProvince
            zipCode = moveServiceFlowData.currentAccountDetail.premiseInfo.first?.townDetail.code
            apartmentUnitNo = nil
        }
        
        enum CodingKeys: String, CodingKey {

            case streetName = "StreetName"
            case apartmentUnitNo = "ApartmentUnitNo"
            case city = "City"
            case state = "State"
            case zipCode = "ZipCode"
        }
    }
}
