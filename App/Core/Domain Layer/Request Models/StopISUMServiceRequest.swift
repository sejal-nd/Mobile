//
//  StopISUMServiceRequest.swift
//  Mobile
//
//  Created by RAMAITHANI on 28/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public struct StopISUMServiceRequest: Encodable {
    
    let startStopMoveDetails: StartStopMoveDetails?

    init(stopFlowData: StopServiceFlowData) {
        self.startStopMoveDetails = StartStopMoveDetails(stopFlowData: stopFlowData)
    }
    
    enum CodingKeys: String, CodingKey {
        
        case startStopMoveDetails = "StartStopMoveDetails"
    }

    struct StartStopMoveDetails: Encodable {
        
        let accountNumber: String
        let customerID: String
        let stopServiceDate: String
        let scheduleAppointmentDate: String?
        let primaryCustInformation: PrimaryCustInformation
        let stopServiceAddress: StopServiceAddressRequest
        let billGroup: String?
        let emailAddress: String?
        let premiseOccupied: Bool
        let premiseOperationCenter: String?
        var isRCDStopCapable: Bool?
        var requestCourtesyCall: Bool
        let serviceLists: [ServiceListsRequest]?
        let selectedStopServicePoints: [String]?
        let courtesyCallPhoneNo: String?


        public init(stopFlowData: StopServiceFlowData) {
            
            self.accountNumber = stopFlowData.currentAccountDetail.accountNumber
            self.customerID = stopFlowData.currentAccountDetail.customerNumber
            self.stopServiceDate = DateFormatter.mmDdYyyyFormatter.string(from: stopFlowData.selectedDate)
            self.scheduleAppointmentDate = nil
            self.primaryCustInformation = PrimaryCustInformation(stopFlowData: stopFlowData)
            self.stopServiceAddress = StopServiceAddressRequest(stopFlowData: stopFlowData)
            self.billGroup = nil
            self.emailAddress = stopFlowData.currentAccountDetail.customerInfo.emailAddress
            self.premiseOccupied = stopFlowData.currentAccountDetail.premiseInfo.count > 0
            self.premiseOperationCenter = nil
            self.isRCDStopCapable = stopFlowData.verificationDetail?.isRCDCapable
            self.requestCourtesyCall = false
            self.serviceLists = stopFlowData.verificationDetail?.serviceLists.map { ServiceListsRequest(serviceList: $0) }
            self.selectedStopServicePoints = stopFlowData.verificationDetail?.serviceLists.map { $0.servicePointID }
            self.courtesyCallPhoneNo = nil
        }
        
        enum CodingKeys: String, CodingKey {
            
            case accountNumber = "AccountNumber"
            case customerID = "CustomerID"
            case stopServiceDate = "StopServiceDate"
            case scheduleAppointmentDate = "ScheduleAppointmentDate"
            case primaryCustInformation = "PrimaryCustInformation"
            case stopServiceAddress = "StopServiceAddress"
            case billGroup = "BillGroup"
            case emailAddress = "EmailAddress"
            case premiseOccupied = "PremiseOccupied"
            case premiseOperationCenter = "PremiseOperationCenter"
            case requestCourtesyCall = "RequestCourtesyCall"
            case serviceLists = "ServiceLists"
            case selectedStopServicePoints = "SelectedStopServicePoints"
            case isRCDStopCapable = "RCDStopCapable"
            case courtesyCallPhoneNo = "CourtesyCallPhoneNo"
        }
    }
    
    public struct StopServiceAddressRequest: Encodable {

        let streetName: String?
        let city: String?
        let state: String?
        let country: String?
        let zipCode: String?
        let accountNumber: String?
        let customerID: String?
        let premiseID: String?
        let revenueClass: String?

        init(stopFlowData: StopServiceFlowData) {
            
            self.streetName = stopFlowData.verificationDetail?.startStopMoveServiceDetails.primaryCustInformation.billingAddress.streetName
            self.city = stopFlowData.verificationDetail?.startStopMoveServiceDetails.primaryCustInformation.billingAddress.city
            self.state = stopFlowData.verificationDetail?.startStopMoveServiceDetails.primaryCustInformation.billingAddress.state
            self.country = stopFlowData.verificationDetail?.startStopMoveServiceDetails.primaryCustInformation.billingAddress.country
            self.zipCode = stopFlowData.verificationDetail?.startStopMoveServiceDetails.primaryCustInformation.billingAddress.zipCode
            self.accountNumber = stopFlowData.verificationDetail?.startStopMoveServiceDetails.accountNumber
            self.customerID = stopFlowData.verificationDetail?.startStopMoveServiceDetails.customerID
            self.premiseID = stopFlowData.verificationDetail?.startStopMoveServiceDetails.stopServiceAddress.premiseID
            self.revenueClass = stopFlowData.currentAccountDetail.revenueClass
        }
        
        enum CodingKeys: String, CodingKey {
            
            case streetName = "StreetName"
            case city = "City"
            case state = "State"
            case country = "Country"
            case zipCode = "ZipCode"
            case accountNumber = "AccountNumber"
            case customerID = "CustomerID"
            case premiseID = "PremiseID"
            case revenueClass = "RevenueClass"
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

    public struct PrimaryCustInformation: Encodable {
        
        
        let firstName: String?
        let lastName: String?
        let contactPhoneNo: String?
        let contactPhoneNoType: String?
        let altContactPhoneNo: String?
        let billingAddress: BillingAddressRequest?
        let useAltBillingAddress: Bool
        let email: String?

        init(stopFlowData: StopServiceFlowData) {

            self.firstName = stopFlowData.currentAccountDetail.customerInfo.firstName
            self.lastName = stopFlowData.currentAccountDetail.customerInfo.lastName
            self.contactPhoneNo = stopFlowData.currentAccountDetail.customerNumber
            self.contactPhoneNoType = ""
            self.altContactPhoneNo = stopFlowData.currentAccountDetail.customerInfo.alternatePhoneNumber
            self.billingAddress = BillingAddressRequest(stopFlowData: stopFlowData)
            self.useAltBillingAddress = !stopFlowData.hasCurrentServiceAddressForBill
            self.email = stopFlowData.currentAccountDetail.customerInfo.emailAddress
        }
        
        enum CodingKeys: String, CodingKey {
            
            case firstName = "FirstName"
            case lastName = "LastName"
            case contactPhoneNo = "ContactPhoneNo"
            case contactPhoneNoType = "ContactPhoneNoType"
            case altContactPhoneNo = "AltContactPhoneNo"
            case billingAddress = "BillingAddress"
            case useAltBillingAddress = "UseAltBillingAddress"
            case email = "Email"
        }
    }

    public struct BillingAddressRequest: Encodable {


        let streetName: String?
        let city: String?
        let state: String?
        let zipCode: String?
        let apartmentUnitNo: String?
        
        init(stopFlowData: StopServiceFlowData) {
            
            self.streetName = stopFlowData.hasCurrentServiceAddressForBill ? stopFlowData.verificationDetail?.startStopMoveServiceDetails.primaryCustInformation.billingAddress.streetName : stopFlowData.mailingAddress?.streetAddress
            self.apartmentUnitNo = ""
            self.city = stopFlowData.hasCurrentServiceAddressForBill ? stopFlowData.verificationDetail?.startStopMoveServiceDetails.primaryCustInformation.billingAddress.city : stopFlowData.mailingAddress?.city
            self.state = stopFlowData.hasCurrentServiceAddressForBill ? stopFlowData.verificationDetail?.startStopMoveServiceDetails.primaryCustInformation.billingAddress.state : stopFlowData.mailingAddress?.state.rawValue
            self.zipCode = stopFlowData.hasCurrentServiceAddressForBill ? stopFlowData.verificationDetail?.startStopMoveServiceDetails.primaryCustInformation.billingAddress.zipCode : stopFlowData.mailingAddress?.zipCode
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
