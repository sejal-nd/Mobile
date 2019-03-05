//
//  Fonts.swift
//  Mobile
//
//  Created by Sam Francis on 4/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

//MARK: - Fonts

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

enum SystemFont: FontType {
    case ultraLight, thin, light, regular, medium, semibold, bold, heavy, black, italic
    
    private var weight: UIFont.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        case .italic: return .regular
        }
    }
    
    func of(size: CGFloat) -> UIFont {
        switch self {
        case .italic:
            return .italicSystemFont(ofSize: size)
        default:
            return .systemFont(ofSize: size, weight: weight)
        }
    }
    
    func of(textStyle: UIFont.TextStyle) -> UIFont {
        let size = UIFont.preferredSize(forTextStyle: textStyle)
        switch self {
        case .italic:
            return .italicSystemFont(ofSize: size)
        default:
            return .systemFont(ofSize: size, weight: weight)
        }
    }
}

//MARK: - FontType

protocol FontType {
    func of(size: CGFloat) -> UIFont
    func of(textStyle: UIFont.TextStyle) -> UIFont
}

extension FontType where Self: RawRepresentable, Self.RawValue == String {
    func of(size: CGFloat) -> UIFont {
        guard let font = UIFont(name: rawValue, size: size) else {
            #if DEBUG
                fatalError("Font \"\(rawValue)\" not found.")
            #else
                return .systemFont(ofSize: size)
            #endif
        }
        return font
    }
    
    func of(textStyle: UIFont.TextStyle) -> UIFont {
        let size = UIFont.preferredSize(forTextStyle: textStyle)
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

//MARK: - Size Table

extension UIFont {
    
    static func preferredSize(forTextStyle textStyle: UIFont.TextStyle) -> CGFloat {
        let category = UIApplication.shared.preferredContentSizeCategory
        
        #if DEBUG
            guard let size = sizeTable[textStyle]?[category] else {
                fatalError("Font size not specified for style \"\(textStyle)\" and category \"\(category)\"")
            }
            return size
        #else
            // If the provided style isn't in the table, just use .body
            let categoryDict = sizeTable[textStyle] ?? sizeTable[.body]!
            // If the provided category isn't in the table, just use .large
            let size = categoryDict[category] ?? categoryDict[.large]!
            return size
        #endif
    }
    
    @nonobjc private static let sizeTable: [UIFont.TextStyle : [UIContentSizeCategory : CGFloat]] =
        [
            .title1: [
                .accessibilityExtraExtraExtraLarge: 23,
                .accessibilityExtraExtraLarge: 23,
                .accessibilityExtraLarge: 23,
                .accessibilityLarge: 23,
                .accessibilityMedium: 23,
                .extraExtraExtraLarge: 23,
                .extraExtraLarge: 21,
                .extraLarge: 19,
                .large: 18,
                .medium: 17,
                .small: 16,
                .extraSmall: 15],
            .title2: [
                .accessibilityExtraExtraExtraLarge: 20,
                .accessibilityExtraExtraLarge: 20,
                .accessibilityExtraLarge: 20,
                .accessibilityLarge: 20,
                .accessibilityMedium: 20,
                .extraExtraExtraLarge: 20,
                .extraExtraLarge: 20,
                .extraLarge: 19,
                .large: 18,
                .medium: 17,
                .small: 16,
                .extraSmall: 15],
            .title3: [
                .accessibilityExtraExtraExtraLarge: 20,
                .accessibilityExtraExtraLarge: 20,
                .accessibilityExtraLarge: 20,
                .accessibilityLarge: 20,
                .accessibilityMedium: 20,
                .extraExtraExtraLarge: 20,
                .extraExtraLarge: 20,
                .extraLarge: 19,
                .large: 18,
                .medium: 17,
                .small: 16,
                .extraSmall: 15],
            .headline: [
                .accessibilityExtraExtraExtraLarge: 21,
                .accessibilityExtraExtraLarge: 21,
                .accessibilityExtraLarge: 21,
                .accessibilityLarge: 21,
                .accessibilityMedium: 21,
                .extraExtraExtraLarge: 21,
                .extraExtraLarge: 19,
                .extraLarge: 17,
                .large: 16,
                .medium: 15,
                .small: 14,
                .extraSmall: 13],
            .subheadline: [
                .accessibilityExtraExtraExtraLarge: 18,
                .accessibilityExtraExtraLarge: 18,
                .accessibilityExtraLarge: 18,
                .accessibilityLarge: 18,
                .accessibilityMedium: 18,
                .extraExtraExtraLarge: 18,
                .extraExtraLarge: 17,
                .extraLarge: 16,
                .large: 14,
                .medium: 13,
                .small: 12,
                .extraSmall: 11],
            .body: [
                .accessibilityExtraExtraExtraLarge: 53,
                .accessibilityExtraExtraLarge: 47,
                .accessibilityExtraLarge: 40,
                .accessibilityLarge: 33,
                .accessibilityMedium: 28,
                .extraExtraExtraLarge: 24,
                .extraExtraLarge: 20,
                .extraLarge: 18,
                .large: 16,
                .medium: 15,
                .small: 14,
                .extraSmall: 13],
            .callout: [
                .accessibilityExtraExtraExtraLarge: 53,
                .accessibilityExtraExtraLarge: 47,
                .accessibilityExtraLarge: 40,
                .accessibilityLarge: 33,
                .accessibilityMedium: 28,
                .extraExtraExtraLarge: 24,
                .extraExtraLarge: 20,
                .extraLarge: 18,
                .large: 16,
                .medium: 15,
                .small: 14,
                .extraSmall: 13],
            .footnote: [
                .accessibilityExtraExtraExtraLarge: 16,
                .accessibilityExtraExtraLarge: 16,
                .accessibilityExtraLarge: 16,
                .accessibilityLarge: 16,
                .accessibilityMedium: 16,
                .extraExtraExtraLarge: 16,
                .extraExtraLarge: 15,
                .extraLarge: 14,
                .large: 12,
                .medium: 11,
                .small: 11,
                .extraSmall: 11],
            .caption1: [
                .accessibilityExtraExtraExtraLarge: 14,
                .accessibilityExtraExtraLarge: 14,
                .accessibilityExtraLarge: 14,
                .accessibilityLarge: 14,
                .accessibilityMedium: 14,
                .extraExtraExtraLarge: 14,
                .extraExtraLarge: 13,
                .extraLarge: 12,
                .large: 11,
                .medium: 11,
                .small: 11,
                .extraSmall: 11],
            .caption2: [
                .accessibilityExtraExtraExtraLarge: 12,
                .accessibilityExtraExtraLarge: 12,
                .accessibilityExtraLarge: 12,
                .accessibilityLarge: 12,
                .accessibilityMedium: 12,
                .extraExtraExtraLarge: 12,
                .extraExtraLarge: 12,
                .extraLarge: 12,
                .large: 10,
                .medium: 10,
                .small: 10,
                .extraSmall: 10]
    ]
}
