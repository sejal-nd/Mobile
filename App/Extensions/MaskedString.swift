//
//  MaskedString.swift
//  Mobile
//
//  Created by Marc Shilling on 3/9/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

extension String {
    func mask() -> String {
        if count < 6 {
            return self
        }
        let startIndex = self.index(self.startIndex, offsetBy: 6)
        return self.replacingCharacters(in: startIndex..<self.endIndex, with: "**********")
    }
    
    func maskAllButLast4Digits() -> String {
        let endIndex = self.index(self.endIndex, offsetBy: -4)
        return self.replacingCharacters(in: self.startIndex..<endIndex, with: "****")
    }
    
    func last4Digits() -> String {
        let endIndex = self.index(self.endIndex, offsetBy: -4)
        return self.replacingCharacters(in: self.startIndex..<endIndex, with: "")
    }
}
