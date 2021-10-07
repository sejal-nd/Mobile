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
}
