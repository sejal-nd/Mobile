//
//  ReleaseOfInfoPreference.swift
//  Mobile
//
//  Created by Cody Dillon on 7/8/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct ReleaseOfInfoRequest: Encodable {
    let value: String
    
    enum CodingKeys: String, CodingKey {
        case value = "release_info_value"
    }
    
    init(selectedIndex: Int) {
        self.value = "0\(selectedIndex + 1)"
    }
}
