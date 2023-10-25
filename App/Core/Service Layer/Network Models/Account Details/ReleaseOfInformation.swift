//
//  ReleaseOfInformation.swift
//  Mobile
//
//  Created by Joseph Erlandson on 10/25/23.
//  Copyright © 2023 Exelon Corporation. All rights reserved.
//

import Foundation

enum ReleaseOfInformation: String, DefaultCaseCodable {
    case noInfo = "NOINFO"
    case addressOnly = "ALLINFOEXUSG"
    case allInfo = "ALLINFO"
//    case unknown
}
