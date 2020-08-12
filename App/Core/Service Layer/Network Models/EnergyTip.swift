//
//  EnergyTip.swift
//  Mobile
//
//  Created by Cody Dillon on 7/14/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import UIKit // TODO: should probably remove UIKit from model class

public struct EnergyTip: Decodable, Equatable {
    let title: String
    let image: UIImage?
    let body: String
    
    enum CodingKeys: String, CodingKey {
        case title
        case image
        case body = "shortBody"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        title = try string(fromHtmlString: container.decode(String.self, forKey: .title))
        body = try string(fromHtmlString: container.decode(String.self, forKey: .body))
        image = nil // TODO: how to implement this?
    }
    
    public static func ==(lhs: EnergyTip, rhs: EnergyTip) -> Bool {
        return lhs.title == rhs.title &&
            lhs.image == rhs.image &&
            lhs.body == rhs.body
    }
}

fileprivate func string(fromHtmlString htmlString: String) throws -> String {
    guard let data = htmlString.data(using: .unicode, allowLossyConversion: true) else {
        throw NetworkingError.decoding
    }
    
    let attributedString = try NSAttributedString(data: data,
                                                  options: [.documentType: NSAttributedString.DocumentType.html],
                                                  documentAttributes: nil)
    return attributedString.string
}
