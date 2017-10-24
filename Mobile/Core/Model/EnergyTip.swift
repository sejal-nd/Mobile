//
//  EnergyTip.swift
//  Mobile
//
//  Created by Sam Francis on 10/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper
import Foundation

struct EnergyTip: Mappable {
    let title: String
    let image: UIImage?
    let body: String
    
    init(map: Mapper) throws {
        title = try map.from("title")
        body = try map.from("shortBody")
        
        //TODO: Actually implement this
        image = map.optionalFrom("image") {
            $0 as? UIImage
        }
        
    }
    
    var parsedBody: String? {
        do {
            let data = body.data(using: String.Encoding.utf8, allowLossyConversion: true)
            if let d = data {
                let str = try NSAttributedString(data: d,
                                                 options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType],
                                                 documentAttributes: nil)
                return str.string
            }
        } catch {
        }
        return nil
    }
}
