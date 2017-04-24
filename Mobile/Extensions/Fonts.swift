//
//  Fonts.swift
//  Mobile
//
//  Created by Sam Francis on 4/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

enum OpenSans: String, FontType {
    case bold = "OpenSans-Bold"
    case boldItalic = "OpenSans-BoldItalic"
    case extraBold = "OpenSans-Extrabold"
    case extraBoldItalic = "OpenSans-ExtraboldItalic"
    case italic = "OpenSans-Italic"
    case light = "OpenSans-Light"
    case lightItalic = "OpenSansLight-Italic"
    case regular = "OpenSans"
    case semibold = "OpenSans-Semibold"
    case semiboldItalic = "OpenSans-SemiboldItalic"
}

protocol FontType: RawRepresentable {
    func ofSize(_ size: CGFloat) -> UIFont
}

extension FontType where RawValue == String {
    func ofSize(_ size: CGFloat) -> UIFont {
        guard let font = UIFont(name: rawValue, size: size) else {
            #if DEBUG
                fatalError("Font \"\(rawValue)\" not found.")
            #else
                return .systemFont(ofSize: size)
            #endif
        }
        return font
    }
}

extension UIFont {
    convenience init<F: FontType>(fontType: F, size: CGFloat) where F.RawValue == String {
        self.init(name: fontType.rawValue, size: size)!
    }
}
