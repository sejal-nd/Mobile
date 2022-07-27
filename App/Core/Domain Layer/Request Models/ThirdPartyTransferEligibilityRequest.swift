//
//  ThirdPartyTransferEligibilityRequest.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 6/14/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import Foundation

// MARK: - ThirdPartyTransferEligibilityRequest
public struct ThirdPartyTransferEligibilityRequest: Codable {
    public let startStopMoveDetails: StartStopMoveDetails
    public let isVerificationReqd: Bool

    enum CodingKeys: String, CodingKey {
        case startStopMoveDetails = "StartStopMoveDetails"
        case isVerificationReqd
    }

    public init(startStopMoveDetails: StartStopMoveDetails, isVerificationReqd: Bool) {
        self.startStopMoveDetails = startStopMoveDetails
        self.isVerificationReqd = isVerificationReqd
    }
}

// MARK: - StartStopMoveDetails
public struct StartStopMoveDetails: Codable {
    public let accountNumber, emailAddress: String
    public let createOnlineProfile: Bool
    public let primaryCustPersIdentification: PrimaryCustPersIdentification
    public let primaryCustInformation: PrimaryCustInformation
    public let startServiceDate, stopServiceDate: String
    public let startServiceAddress: StartServiceAddress
    public let stopServiceAddress: StopServiceAddress
    public let rentOwn: String?
    public let premiseOccupied, rcdStopCapable, requestCourtesyCall: Bool?
    public let selectedStopServicePoints, serviceLists: [String]

    enum CodingKeys: String, CodingKey {
        case accountNumber = "AccountNumber"
        case emailAddress = "EmailAddress"
        case createOnlineProfile = "CreateOnlineProfile"
        case primaryCustPersIdentification = "PrimaryCustPersIdentification"
        case primaryCustInformation = "PrimaryCustInformation"
        case startServiceDate = "StartServiceDate"
        case stopServiceDate = "StopServiceDate"
        case startServiceAddress = "StartServiceAddress"
        case stopServiceAddress = "StopServiceAddress"
        case rentOwn = "RentOwn"
        case premiseOccupied = "PremiseOccupied"
        case rcdStopCapable = "RCDStopCapable"
        case requestCourtesyCall = "RequestCourtesyCall"
        case selectedStopServicePoints = "SelectedStopServicePoints"
        case serviceLists = "ServiceLists"
    }

    public init(accountNumber: String, emailAddress: String, primaryCustPersIdentification: PrimaryCustPersIdentification, primaryCustInformation: PrimaryCustInformation, startServiceDate: String, stopServiceDate: String, startServiceAddress: StartServiceAddress, stopServiceAddress: StopServiceAddress, rentOwn: String?, premiseOccupied: Bool?, rcdStopCapable: Bool?, requestCourtesyCall: Bool?) {
        self.accountNumber = accountNumber
        self.emailAddress = emailAddress
        self.createOnlineProfile = false
        self.primaryCustPersIdentification = primaryCustPersIdentification
        self.primaryCustInformation = primaryCustInformation
        self.startServiceDate = startServiceDate
        self.stopServiceDate = stopServiceDate
        self.startServiceAddress = startServiceAddress
        self.stopServiceAddress = stopServiceAddress
        self.rentOwn = rentOwn
        self.premiseOccupied = premiseOccupied
        self.rcdStopCapable = rcdStopCapable
        self.requestCourtesyCall = requestCourtesyCall
        self.selectedStopServicePoints = []
        self.serviceLists = []
    }
}

// MARK: - PrimaryCustInformation
public struct PrimaryCustInformation: Codable {
    public let firstName, lastName, address, city: String?
    public let zipCode, contactPhoneNo, altContactPhoneNo: String?
    public let email: String
    public let useAltBillingAddress: Bool
    public let billingAddress: TPSBillingAddress?

    enum CodingKeys: String, CodingKey {
        case firstName = "FirstName"
        case lastName = "LastName"
        case address = "Address"
        case city = "City"
        case zipCode = "ZipCode"
        case contactPhoneNo = "ContactPhoneNo"
        case altContactPhoneNo = "AltContactPhoneNo"
        case email = "Email"
        case useAltBillingAddress = "UseAltBillingAddress"
        case billingAddress = "BillingAddress"
    }

    public init(firstName: String?, lastName: String?, address: String?, city: String?, zipCode: String?, contactPhoneNo: String?, altContactPhoneNo: String?, email: String, useAltBillingAddress: Bool, billingAddress: TPSBillingAddress?) {
        self.firstName = firstName
        self.lastName = lastName
        self.address = address
        self.city = city
        self.zipCode = zipCode
        self.contactPhoneNo = contactPhoneNo
        self.altContactPhoneNo = altContactPhoneNo
        self.email = email
        self.useAltBillingAddress = useAltBillingAddress
        self.billingAddress = billingAddress
    }
}

// MARK: - PrimaryCustPersIdentification
public struct PrimaryCustPersIdentification: Codable {
    public let ssnNumber, dateOfBirth, employmentStatus, driverLicenseNumber: String

    enum CodingKeys: String, CodingKey {
        case ssnNumber = "SSNNumber"
        case dateOfBirth = "DateOfBirth"
        case employmentStatus = "EmploymentStatus"
        case driverLicenseNumber = "DriverLicenseNumber"
    }

    public init(ssnNumber: String, dateOfBirth: String, employmentStatus: String, driverLicenseNumber: String) {
        self.ssnNumber = ssnNumber
        self.dateOfBirth = dateOfBirth
        self.employmentStatus = employmentStatus
        self.driverLicenseNumber = driverLicenseNumber
    }
}

// MARK: - StartServiceAddress
public struct StartServiceAddress: Codable {
    public let streetName, houseNo: String?
    public var apartmentUnitNo: String?
    public let city, zipCode, state: String? //customerID
    public let country, customerID, premiseID, premiseOrganization, accountNumber: String?

    enum CodingKeys: String, CodingKey {
        case streetName = "StreetName"
        case houseNo = "HouseNo"
        case apartmentUnitNo = "ApartmentUnitNo"
        case city = "City"
        case zipCode = "ZipCode"
        case customerID = "CustomerID"
        case state = "State"
        case country = "Country"
        case premiseID = "PremiseID"
        case premiseOrganization = "PremiseOrganization"
        case accountNumber = "AccountNumber"
    }

    public init(streetName: String?, houseNo: String?, apartmentUnitNo: String?, city: String?, zipCode: String?, state: String?, premiseID: String?, premiseOrganization: String?, customerID: String?, accountNumber: String?) {
        self.streetName = streetName
        self.houseNo = houseNo
        self.apartmentUnitNo = apartmentUnitNo
        self.city = city
        self.zipCode = zipCode
        self.customerID = customerID
        self.state = state
        self.country = "United States of America"
        self.premiseID = premiseID
        self.premiseOrganization = premiseOrganization
        self.accountNumber = accountNumber
    }
}

// MARK: - StopServiceAddress
public struct StopServiceAddress: Codable {
    public let streetName, city, state, country: String?
    public let zipCode, accountNumber, premiseID: String?

    enum CodingKeys: String, CodingKey {
        case streetName = "StreetName"
        case city = "City"
        case state = "State"
        case country = "Country"
        case zipCode = "ZipCode"
        case premiseID = "PremiseID"
        case accountNumber = "AccountNumber"
    }
    
        self.streetName = streetName
        self.city = city
        self.state = state
        self.country = "United States of America"
        self.zipCode = zipCode
        self.premiseID = premiseID
        self.accountNumber = accountNumber
    }
}

// MARK: - TPSBillingAddress
public struct TPSBillingAddress: Codable {
    public let streetName, apartmentUnitNo, city, state: String?
    public let zipCode: String?
    
    enum CodingKeys: String, CodingKey {
        case streetName = "StreetName"
        case apartmentUnitNo = "ApartmentUnitNo"
        case city = "City"
        case state = "State"
        case zipCode = "ZipCode"
    }
    
    public init(streetName: String?, apartmentUnitNo: String?, city: String?, state: String?, zipCode: String?) {
        self.streetName = streetName
        self.apartmentUnitNo = apartmentUnitNo
        self.city = city
        self.state = state
        self.zipCode = zipCode
    }
    
    init(moveFlowData: MoveServiceFlowData) {
        
        streetName =  moveFlowData.hasCurrentServiceAddressForBill ? (moveFlowData.addressLookupResponse?.first?.streetName ?? moveFlowData.addressLookupResponse?.first?.address) : moveFlowData.mailingAddress?.streetAddress
        
        city = moveFlowData.hasCurrentServiceAddressForBill ? moveFlowData.addressLookupResponse?.first?.city : moveFlowData.mailingAddress?.city
        state = moveFlowData.hasCurrentServiceAddressForBill ? USState.getState(state: moveFlowData.addressLookupResponse?.first?.state ?? "") : USState.getState(state: moveFlowData.mailingAddress?.state.rawValue ?? "")
        zipCode = moveFlowData.hasCurrentServiceAddressForBill ? moveFlowData.addressLookupResponse?.first?.zipCode : moveFlowData.mailingAddress?.zipCode
        apartmentUnitNo = moveFlowData.hasCurrentServiceAddressForBill ? moveFlowData.addressLookupResponse?.first?.apartmentUnitNo : nil
    }
}

// MARK: - ServiceList
public struct ServiceList: Codable {
    public let stop: Bool?
    public let serviceAgreementID, type, saType, saStatus: String?
    public let servicePointID, location: String?
    public let hasError: Bool?

    public init(stop: Bool?, serviceAgreementID: String?, type: String?, saType: String?, saStatus: String?, servicePointID: String?, location: String?, hasError: Bool?) {
        self.stop = stop
        self.serviceAgreementID = serviceAgreementID
        self.type = type
        self.saType = saType
        self.saStatus = saStatus
        self.servicePointID = servicePointID
        self.location = location
        self.hasError = hasError
    }
}
