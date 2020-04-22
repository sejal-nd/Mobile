//
//  NewBillPDF.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/31/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct BillPDFNew: Decodable {
    public var imageData: String
    public var contentType: String
    
    enum CodingKeys: String, CodingKey {
        case data = "data"
        case imageData = "billImageData"
        case contentType = "contentType"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                 forKey: .data)
        self.imageData = try data.decode(String.self,
                                         forKey: .imageData)
        self.contentType = try data.decode(String.self,
                                           forKey: .contentType)
    }
}
