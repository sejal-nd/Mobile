//
//  NewBillPDF.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/31/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct BillPDF: Decodable {
    public var imageData: String
    public var contentType: String
    
    enum CodingKeys: String, CodingKey {
        case imageData = "billImageData"
        case contentType = "contentType"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.imageData = try container.decode(String.self,
                                         forKey: .imageData)
        self.contentType = try container.decode(String.self,
                                           forKey: .contentType)
    }
}
