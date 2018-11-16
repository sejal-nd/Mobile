//
//  UIFont+Italic.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 10/12/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIFont {
    
    func withTraits(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else { return UIFont.systemFont(ofSize: 19.0, weight: .regular) }
        return UIFont(descriptor: descriptor, size: 0) //size 0 means keep the size as it is
    }
    
    // unused
    func bold() -> UIFont {
        return withTraits(traits: .traitBold)
    }
    
    func italic() -> UIFont {
        return withTraits(traits: .traitItalic)
    }
    
}
