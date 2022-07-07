//
//  ThirdPartyTransferEligibilityResponse.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 6/14/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import Foundation

public struct ThirdPartyTransferEligibilityResponse: Decodable {
    let isEligible: Bool
    
    public init(seamlessflag: String) {
        self.isEligible = seamlessflag.lowercased() == "y"
    }
    
    public init(isEligible: Bool) {
        self.isEligible = isEligible
    }
}
