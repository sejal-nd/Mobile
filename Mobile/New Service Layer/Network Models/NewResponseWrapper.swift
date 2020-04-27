//
//  NewResponseWrapper.swift
//  Mobile
//
//  Created by Cody Dillon on 4/27/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct NewResponseWrapper<T: Decodable>: Decodable {
    public let success: Bool
    public let data: T
}
