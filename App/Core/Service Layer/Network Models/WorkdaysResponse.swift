//
//  WorkdaysResponse.swift
//  Mobile
//
//  Created by RAMAITHANI on 12/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
public struct WorkdaysResponse: Decodable {
    
    let list: [WorkDay]
    
    struct WorkDay: Decodable {
        let key: Int
        let value: String

        enum CodingKeys: String, CodingKey {
            case key, value
            
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case list = "WorkDayList"
    }
}

