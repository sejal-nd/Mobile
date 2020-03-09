//
//  NewMinimumVersion.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/9/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct NewMinimumVersion: Codable {
    var iosObject: NewVersions
}

struct NewVersions: Codable {
    var minVersion: String = "0.0.0"
}
