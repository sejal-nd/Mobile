//
//  NewMeterPingResult.swift
//  Mobile
//
//  Created by Cody Dillon on 4/24/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct NewMeterPingResult: Decodable {
    let pingResult: Bool
    let voltageResult: Bool
    let voltageReads: String?
}
