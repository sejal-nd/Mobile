//
//  EnergyTip.swift
//  Mobile
//
//  Created by Sam Francis on 10/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

struct EnergyTip: Mappable {
    let title: String
    let image: UIImage?
    let why: String
    
    init(map: Mapper) throws {
        title = try map.from("title")
        why = try map.from("why")
        
        //TODO: Actually implement this
        image = map.optionalFrom("image") {
            $0 as? UIImage
        }
        
    }
}
