//
//  RecoverMaskedUsernameRequestWithAuid.swift
//  Mobile
//
//  Created by Mukherjee, Silpi on 17/01/24.
//  Copyright © 2024 Exelon Corporation. All rights reserved.
//

import Foundation

public struct RecoverMaskedUsernameRequestWithAuid: Encodable {
    let phone: String
    let identifier: String
    var auid: String? = nil
    
    enum CodingKeys: String, CodingKey{
        case phone
        case identifier
        case auid
    }
}
