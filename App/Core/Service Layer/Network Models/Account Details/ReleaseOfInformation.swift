//
//  ReleaseOfInformation.swift
//  Mobile
//
//  Created by Cody Dillon on 1/24/23.
//  Copyright © 2023 Exelon Corporation. All rights reserved.
//

import Foundation

enum ReleaseOfInformation: String, DefaultCaseCodable {
    case noInfo = "NOINFO"
    case addressOnly = "ALLINFOEXUSG"
    case allInfo = "ALLINFO"
//    case unknown
}
