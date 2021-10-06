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
}
