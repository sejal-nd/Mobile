//
//  Version.swift
//  Mobile
//
//  Created by Samuel Francis on 6/26/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

final class Version: Equatable, Comparable, CustomStringConvertible {
    let major: Int
    let minor: Int
    let patch: Int
    
    var string: String {
        return "\(major).\(minor).\(patch)"
    }
    
    static let current: Version = {
        let versionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        return Version(string: versionString)!
    }()
    
    init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
    
    init?(string: String) {
        let numbers = string.split(separator: ".").compactMap { Int($0) }
        guard numbers.count == 3 else { return nil }
        major = numbers[0]
        minor = numbers[1]
        patch = numbers[2]
    }
    
    static func == (lhs: Version, rhs: Version) -> Bool {
        return lhs.major == rhs.major &&
            lhs.minor == rhs.minor &&
            lhs.patch == rhs.patch
    }
    
    static func < (lhs: Version, rhs: Version) -> Bool {
        for (left, right) in zip([lhs.major, lhs.minor, lhs.patch], [rhs.major, rhs.minor, rhs.patch]) where left != right {
            return left < right
        }
        return false
    }
    
    
    var description: String { return string }
}
