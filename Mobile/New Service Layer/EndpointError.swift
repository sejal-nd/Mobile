//
//  NewServiceError.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/14/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public protocol EndpointErrorable {
    var errorCode: String? { get set }
    var errorMessage: String? { get set }
}
