//
//  ObfuscatedString.swift
//  Mobile
//
//  Created by Marc Shilling on 3/9/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

extension String {
    func obfuscate() -> String {
        if self.characters.count < 6 {
            return self
        }
        let startIndex = self.index(self.startIndex, offsetBy: 6)
        return self.replacingCharacters(in: startIndex..<self.endIndex, with: "**********")
    }
}
