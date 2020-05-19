//
//  SSOData.swift
//  Mobile
//
//  Created by Marc Shilling on 10/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

struct SSOData: Mappable {
    let utilityCustomerId: String
    let ssoPostURL: URL
    let relayState: URL
    let samlResponse: String
    let username: String?
    
    init(map: Mapper) throws {
        try utilityCustomerId = map.from("utilityCustomerId")
        try ssoPostURL = map.from("ssoPostURL")
        try relayState = map.from("relayState")
        try samlResponse = map.from("samlResponse")
        username = map.optionalFrom("username")
    }
}
