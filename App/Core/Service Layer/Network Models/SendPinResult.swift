//
//  SendCodeResult.swift
//  Mobile
//
//  Created by Tiwari, Anurag on 25/04/23.
//  Copyright © 2023 Exelon Corporation. All rights reserved.
//

import Foundation
// MARK: - SendCodeResult
public struct SendPinResult : Decodable{
    var success: Bool?
    var data: Datum?
}
// MARK: - DataClass
public struct Datum: Decodable {
    var message: String?
}

