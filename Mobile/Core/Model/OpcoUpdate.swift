//
//  OpcoUpdate.swift
//  Mobile
//
//  Created by Marc Shilling on 11/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

struct OpcoUpdate: Mappable {
    let title: String
    let message: String
    
    init(map: Mapper) throws {
        try title = map.from("Title")
        try message = map.from("Message")
    }
}
