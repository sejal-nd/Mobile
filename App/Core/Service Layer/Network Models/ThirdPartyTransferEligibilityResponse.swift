//
//  ThirdPartyTransferEligibilityResponse.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 6/14/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import Foundation

public struct ThirdPartyTransferEligibilityResponse: Decodable {
    public let isEligible: Bool
    public let seamlessflag: String
    
    enum CodingKeys: String, CodingKey {
        case seamlessflag = "seamlessflag"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        seamlessflag = try container.decodeIfPresent(String.self, forKey: .seamlessflag) ?? "N"
        isEligible = seamlessflag.lowercased() == "y"
    }
}
