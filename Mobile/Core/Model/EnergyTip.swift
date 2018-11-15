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
        title = try string(fromHtmlString: map.from("title"))
        body = try string(fromHtmlString: map.from("shortBody"))
        
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

fileprivate func string(fromHtmlString htmlString: String) throws -> String {
    guard let data = htmlString.data(using: .unicode, allowLossyConversion: true) else {
        throw MapperError.convertibleError(value: htmlString, type: String.self)
    }
    
    let attributedString = try NSAttributedString(data: data,
                                                  options: [.documentType: NSAttributedString.DocumentType.html],
                                                  documentAttributes: nil)
    return attributedString.string
}
