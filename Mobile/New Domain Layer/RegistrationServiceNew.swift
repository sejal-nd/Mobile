//
//  RegistrationServiceNew.swift
//  Mobile
//
//  Created by Cody Dillon on 5/7/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct RegistrationServiceNew {
    static func createAccount(request: NewAccountRequest, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .registration(encodable: request), completion: completion)
    }
}
