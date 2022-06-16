//
//  MoveService.swift
//  EUMobile
//
//  Created by Mithlesh Kumar on 01/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
enum MoveService {
    static func validateZip(code: String = "",
                              completion: @escaping (Result<ValidatedZipCodeResponse, NetworkingError>) -> ()) {
        let validateZipCodeRequest = ValidateZipCodeRequest(zipCode: code)
        NetworkingLayer.request(router: .validateZipCode(request: validateZipCodeRequest), completion: completion)
    }

    static func fetchStreetAddress(address: String = "",zipcode:String = "",
                              completion: @escaping (Result<StreetAddressResponse, NetworkingError>) -> ()) {
        let streetAddressRequest = StreetAddressRequest(address: address, zipcode: zipcode, isFuzzySearch: true)
        NetworkingLayer.request(router: .streetAddress(request: streetAddressRequest), completion: completion)
    }

    static func fetchAppartment(address: String = "",zipcode:String = "",
                              completion: @escaping (Result<[AppartmentResponse], NetworkingError>) -> ()) {
        let premiseIDRequest = AppartmentRequest(address: address, zipcode: zipcode)
        NetworkingLayer.request(router: .appartment(request: premiseIDRequest), completion: completion)
    }
    static func lookupAddress(address: String = "",zipcode:String = "", premiseID:String = "",
                              completion: @escaping (Result<[AddressLookupResponse], NetworkingError>) -> ()) {
        let addressLookupRequest = AddressLookupRequest(address: address, zipcode: zipcode, PremiseID: premiseID)
        NetworkingLayer.request(router: .addressLookup(request: addressLookupRequest), completion: completion)
    }
    
    static func thirdPartyTransferEligibilityCheck(moveFlowData: MoveServiceFlowData, completion: @escaping (Result<ThirdPartyTransferEligibilityResponse, NetworkingError>) -> ()) {
        completion(.success(ThirdPartyTransferEligibilityResponse(isEligible: true)))
//        guard let unwrappedStartDate = moveFlowData.startServiceDate,
//              let startServiceDate = DateFormatter.mmDdYyyyFormatter.string(from: unwrappedStartDate),
//              let stopServiceDate = DateFormatter.mmDdYyyyFormatter.string(from: moveFlowData.stopServiceDate),
//        let ssn = moveFlowData.idVerification?.ssn else {
//                  completion(.failure(.decoding))
//              }
//        let emailAddress = moveFlowData.unauthMoveData?.accountDetails != nil ? (moveFlowData.unauthMoveData?.accountDetails?.customerInfo.emailAddress) : moveFlowData.currentAccountDetail?.customerInfo.emailAddress
//
//
//
//        let startServiceAddress = StartServiceAddress(streetName: moveFlowData.addressLookupResponse?.first?.streetName ?? moveFlowData.addressLookupResponse?.first?.address,
//                                                      houseNo: moveFlowData.addressLookupResponse?.first?.streetNumber,
//                                                      apartmentUnitNo: moveFlowData.addressLookupResponse?.first?.apartmentUnitNo,
//                                                      city: moveFlowData.addressLookupResponse?.first?.city,
//                                                      zipCode: moveFlowData.addressLookupResponse?.first?.zipCode,
//                                                      customerID: moveFlowData.unauthMoveData?.accountDetails != nil ? moveFlowData.unauthMoveData?.accountDetails?.customerInfo.number : moveFlowData.currentAccountDetail?.customerNumber,
//                                                      state: USState.getState(state: moveFlowData.verificationDetail?.startStopMoveServiceDetails.primaryCustInformation.billingAddress.state ?? ""),
//                                                      country: moveFlowData.verificationDetail?.startStopMoveServiceDetails.primaryCustInformation.billingAddress.country,
//                                                      premiseID: moveFlowData.addressLookupResponse?.first?.premiseID,
//                                                      buildingMrID: <#T##String#>,
//                                                      premiseOrganization: moveFlowData.addressLookupResponse?.first?.premiseID)
//        let primaryCustInformation = PrimaryCustInformation(firstName: moveFlowData.unauthMoveData?.accountDetails != nil ? moveFlowData.unauthMoveData?.accountDetails?.customerInfo.firstName :moveFlowData.currentAccountDetail?.customerInfo.firstName,
//                                                            lastName: moveFlowData.unauthMoveData?.accountDetails != nil ? moveFlowData.unauthMoveData?.accountDetails?.customerInfo.lastName : moveFlowData.currentAccountDetail?.customerInfo.lastName,
//                                                            address: moveFlowData.unauthMoveData?.accountDetails != nil ? moveFlowData.unauthMoveData?.accountDetails?.addressLine : moveFlowData.currentAccountDetail?.address,
//                                                            city: moveFlowData.unauthMoveData?.accountDetails != nil ? moveFlowData.unauthMoveData?.accountDetails?.city : moveFlowData.currentAccountDetail?.city,
//                                                            state: moveFlowData.unauthMoveData?.accountDetails != nil ? USState.getState(state: moveFlowData.unauthMoveData?.accountDetails?.state ?? "") : USState.getState(state: moveFlowData.currentAccountDetail?.state ?? ""),
//                                                            zipCode: moveFlowData.unauthMoveData?.accountDetails != nil ? moveFlowData.unauthMoveData?.accountDetails?.zipCode : moveFlowData.currentAccountDetail?.zipCode,
//                                                            contactPhoneNo: moveFlowData.unauthMoveData?.accountDetails != nil ? moveFlowData.unauthMoveData?.accountDetails?.customerInfo.primaryPhoneNumber : moveFlowData.currentAccountDetail?.customerInfo.primaryPhoneNumber,
//                                                            altContactPhoneNo: nil,
//                                                            email: moveFlowData.unauthMoveData?.accountDetails != nil ? moveFlowData.unauthMoveData?.accountDetails?.customerInfo.emailAddress : moveFlowData.currentAccountDetail?.customerInfo.emailAddress,
//                                                            useAltBillingAddress: !moveFlowData.hasCurrentServiceAddressForBill,
//                                                            billingAddress: BillingAddressRequest(moveFlowData: moveFlowData))
//        let primaryCustomerID = PrimaryCustPersIdentification(ssnNumber: ssn)
//        let stopServiceAddress = StopServiceAddress(streetName: moveFlowData.unauthMoveData?.accountDetails != nil ? moveFlowData.unauthMoveData?.accountDetails?.addressLine : (moveFlowData.currentAccountDetail?.addressLine ?? moveFlowData.currentAccountDetail?.street),
//                                                    city: moveFlowData.unauthMoveData?.accountDetails != nil ? moveFlowData.unauthMoveData?.accountDetails?.city : moveFlowData.currentAccountDetail?.city,
//                                                    state: moveFlowData.unauthMoveData?.accountDetails != nil ? USState.getState(state: moveFlowData.unauthMoveData?.accountDetails?.state ?? "") : USState.getState(state: moveFlowData.currentAccountDetail?.state ?? ""),
//                                                    country: "United States of America",
//                                                    zipCode: moveFlowData.unauthMoveData?.accountDetails != nil ? moveFlowData.unauthMoveData?.accountDetails?.zipCode : moveFlowData.currentAccountDetail?.zipCode,
//                                                    premiseID: moveFlowData.unauthMoveData?.accountDetails != nil ? moveFlowData.unauthMoveData?.accountDetails?.premiseNumber : moveFlowData.currentPremise?.premiseNumber,
//                                                    customerID: moveFlowData.unauthMoveData?.accountDetails != nil ? moveFlowData.unauthMoveData?.accountDetails?.customerInfo.number : moveFlowData.currentAccountDetail?.customerNumber,
//                                                    accountNumber: moveFlowData.unauthMoveData?.accountDetails != nil ? moveFlowData.unauthMoveData?.selectedAccountNumber : moveFlowData.currentAccountDetail?.accountNumber,
//                                                    address: moveFlowData.unauthMoveData?.accountDetails != nil ? moveFlowData.unauthMoveData?.accountDetails?.addressLine : moveFlowData.currentAccountDetail?.address)
//
//        let startStopMoveDetails = StartStopMoveDetails(startServiceAddress: startServiceAddress,
//                                                        startServiceDate: startServiceDate,
//                                                        stopServiceDate: stopServiceDate,
//                                                        primaryCustInformation: primaryCustInformation,
//                                                        primaryCustPersIdentification: primaryCustomerID,
//                                                        secondaryCustInformation: nil,
//                                                        secondaryCustPersIdentification: nil,
//                                                        emailAddress: emailAddress,
//                                                        salesAndUseTax: SalesAndUseTax(),
//                                                        covid: "NEGATIVE",
//                                                        stopServiceAddress: stopServiceAddress)
//        let thirdPartyTransferEligibilityRequest = ThirdPartyTransferEligibilityRequest(startStopMoveDetails: startStopMoveDetails, isVerificationReqd: true)
        //        NetworkingLayer.request(router: .thirdPartyTransferEligibility(request: thirdPartyTransferEligibilityRequest), completion: completion)
    }
    
    static func moveService(moveFlowData: MoveServiceFlowData, completion: @escaping (Result<MoveServiceResponse, NetworkingError>) -> ()) {

        let moveISUMServiceRequest = MoveISUMServiceRequest(moveServiceFlowData: moveFlowData)
        NetworkingLayer.request(router: .moveISUMService(request: moveISUMServiceRequest) , completion: completion)
    }
    
    // MARK: Unauth APIs
    static func validateZipAnon(code: String = "",
                              completion: @escaping (Result<ValidatedZipCodeResponse, NetworkingError>) -> ()) {
        let validateZipCodeRequest = ValidateZipCodeRequest(zipCode: code)
        NetworkingLayer.request(router: .validateZipCodeAnon(request: validateZipCodeRequest), completion: completion)
    }

    static func fetchStreetAddressAnon(address: String = "",zipcode:String = "",
                              completion: @escaping (Result<StreetAddressResponse, NetworkingError>) -> ()) {
        let streetAddressRequest = StreetAddressRequest(address: address, zipcode: zipcode, isFuzzySearch: true)
        NetworkingLayer.request(router: .streetAddressAnon(request: streetAddressRequest), completion: completion)
    }

    static func fetchAppartmentAnon(address: String = "",zipcode:String = "",
                              completion: @escaping (Result<[AppartmentResponse], NetworkingError>) -> ()) {
        let premiseIDRequest = AppartmentRequest(address: address, zipcode: zipcode)
        NetworkingLayer.request(router: .appartmentAnon(request: premiseIDRequest), completion: completion)
    }
    static func lookupAddressAnon(address: String = "",zipcode:String = "", premiseID:String = "",
                              completion: @escaping (Result<[AddressLookupResponse], NetworkingError>) -> ()) {
        let addressLookupRequest = AddressLookupRequest(address: address, zipcode: zipcode, PremiseID: premiseID)
        NetworkingLayer.request(router: .addressLookupAnon(request: addressLookupRequest), completion: completion)
    }
    
    static func moveServiceAnon(moveFlowData: MoveServiceFlowData, completion: @escaping (Result<MoveServiceResponse, NetworkingError>) -> ()) {

        let moveISUMServiceRequest = MoveISUMServiceRequest(moveServiceFlowData: moveFlowData)
        NetworkingLayer.request(router: .moveISUMServiceAnon(request: moveISUMServiceRequest) , completion: completion)
    }

}
