//
//  EnergyTip.swift
//  Mobile
//
//  Created by Sam Francis on 10/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper
import Foundation

struct EnergyTip: Mappable, Equatable {
    let title: String
    let image: UIImage?
    let body: String
    
    init(map: Mapper) throws {
        title = try map.from("title")
        
        let htmlBody: String = try map.from("shortBody")
        
        guard let data = htmlBody.data(using: .unicode, allowLossyConversion: true) else {
            throw MapperError.convertibleError(value: htmlBody, type: String.self)
        }
        
        let attributedBody = try NSAttributedString(data: data,
                                         options: [.documentType: NSAttributedString.DocumentType.html],
                                         documentAttributes: nil)
        body = attributedBody.string
        
        //TODO: Actually implement something for this
        image = map.optionalFrom("image") {
            $0 as? UIImage
        }
        
    }
    
    static func ==(lhs: EnergyTip, rhs: EnergyTip) -> Bool {
        return lhs.title == rhs.title &&
            lhs.image == rhs.image &&
            lhs.body == rhs.body
    }
    
}
