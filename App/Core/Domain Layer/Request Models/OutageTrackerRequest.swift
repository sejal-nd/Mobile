//
//  OutageTrackerRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 12/13/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public struct OutageTrackerRequest: Encodable {
    let accountID: String
    let deviceID: String
    let servicePointID: String
}
