//
//  SendCodeRequest.swift
//  Mobile
//
//  Created by Tiwari, Anurag on 25/04/23.
//  Copyright © 2023 Exelon Corporation. All rights reserved.
//

import Foundation

public struct SendCodeRequest: Encodable {
    let phone: String
    let flowType: String
    let isMobile: Bool
}
