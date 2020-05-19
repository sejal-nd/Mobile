//
//  MinimumVersion.swift
//  Mobile
//
//  Created by Constantin Koehler on 8/3/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

struct MinimumVersion: Mappable {
    var iosObject: Versions
    
    init() {
        iosObject = Versions()
    }
    
    init(map: Mapper) throws {
        iosObject = try map.from("ios")
    }
}

struct Versions: Mappable {
    var minVersion: String
    
    init() {
        minVersion = "0.0.0"
    }
    
    init(map: Mapper) throws {
        minVersion = try map.from("minVersion")
    }
}
