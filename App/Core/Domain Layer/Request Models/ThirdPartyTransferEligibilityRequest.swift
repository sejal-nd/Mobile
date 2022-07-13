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
    public let emailAddress: String
    public let primaryCustPersIdentification: PrimaryCustPersIdentification
    public let primaryCustInformation: PrimaryCustInformation
    public let startServiceDate, stopServiceDate: String
    public let startServiceAddress: StartServiceAddress
    public let stopServiceAddress: StopServiceAddress
    public let rentOwn: String?
    public let premiseOccupied, rcdStopCapable, requestCourtesyCall: Bool?
    public let selectedStopServicePoints, serviceLists: [String]

    enum CodingKeys: String, CodingKey {
        case emailAddress = "EmailAddress"
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

    public init(emailAddress: String, primaryCustPersIdentification: PrimaryCustPersIdentification, primaryCustInformation: PrimaryCustInformation, startServiceDate: String, stopServiceDate: String, startServiceAddress: StartServiceAddress, stopServiceAddress: StopServiceAddress, rentOwn: String?, premiseOccupied: Bool?, rcdStopCapable: Bool?, requestCourtesyCall: Bool?) {//, selectedStopServicePoints: [Any?], serviceLists: [Any?]) {
        self.emailAddress = emailAddress
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
    public let zipCode, contactPhoneNo, altContactPhoneNo: String? //state
    public let email: String
    public let useAltBillingAddress: Bool
//    public var billingAddress: String?

    enum CodingKeys: String, CodingKey {
        case firstName = "FirstName"
        case lastName = "LastName"
        case address = "Address"
        case city = "City"
//        case state = "State" // optional?
        case zipCode = "ZipCode"
        case contactPhoneNo = "ContactPhoneNo"
        case altContactPhoneNo = "AltContactPhoneNo" // optional?
        case email = "Email"
        case useAltBillingAddress = "UseAltBillingAddress"
//        case billingAddress = "BillingAddress" // optional?
    }

    public init(firstName: String?, lastName: String?, address: String?, city: String?, zipCode: String?, contactPhoneNo: String?, altContactPhoneNo: String?, email: String, useAltBillingAddress: Bool) {//, billingAddress: String?) { , state: String?
        self.firstName = firstName
        self.lastName = lastName
        self.address = address
        self.city = city
//        self.state = state
        self.zipCode = zipCode
        self.contactPhoneNo = contactPhoneNo
        self.altContactPhoneNo = altContactPhoneNo
        self.email = email
        self.useAltBillingAddress = useAltBillingAddress
//        self.billingAddress = billingAddress
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
//        case buildingMrID = "BuildingMrID"
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
//        self.buildingMrID = buildingMrID
        self.premiseOrganization = premiseOrganization
        self.accountNumber = accountNumber
    }
}

// MARK: - StopServiceAddress
public struct StopServiceAddress: Codable {
//    public let address: String?
    public let streetName, city, state, country: String?
    public let zipCode, accountNumber, premiseID: String?

    enum CodingKeys: String, CodingKey {
//        case address = "Address"
        case streetName = "StreetName"
        case city = "City"
        case state = "State"
        case country = "Country"
        case zipCode = "ZipCode"
        case premiseID = "PremiseID"
//        case customerID = "CustomerID" // optional?
        case accountNumber = "AccountNumber"
    }

    public init(streetName: String?, city: String?, state: String?, zipCode: String?, premiseID: String?, accountNumber: String?) { //address: String?,
//        self.address = address
        self.streetName = streetName
        self.city = city
        self.state = state
        self.country = "United States of America"
//        self.country = country
        self.zipCode = zipCode
        self.premiseID = premiseID
//        self.customerID = customerID
        self.accountNumber = accountNumber
    }
}

// MARK: - Encode/decode helpers

//public class JSONNull: Codable, Hashable {
//
//    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
//        return true
//    }
//
//    public var hashValue: Int {
//        return 0
//    }
//
//    public init() {}
//
//    public required init(from decoder: Decoder) throws {
//        let container = try decoder.singleValueContainer()
//        if !container.decodeNil() {
//            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
//        }
//    }
//
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.singleValueContainer()
//        try container.encodeNil()
//    }
//}
