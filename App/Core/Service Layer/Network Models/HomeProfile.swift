//
//  HomeProfile.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/22/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct HomeProfile: Decodable, Fillable, Equatable {
    public var customerId: Int
    public var dwellingType: HomeType?
    public var squareFeet: Int?
    public var heatType: HeatType?
    public var numberOfAdults: Int?
    public var numberOfChildren: Int?
    
    public static func ==(lhs: HomeProfile, rhs: HomeProfile) -> Bool {
        return lhs.numberOfChildren == rhs.numberOfChildren &&
            lhs.numberOfAdults == rhs.numberOfAdults &&
            lhs.squareFeet == rhs.squareFeet &&
            lhs.heatType == rhs.heatType &&
            lhs.dwellingType == rhs.dwellingType
    }
    
    public static func ==(lhs: HomeProfile, rhs: HomeProfileUpdateRequest) -> Bool {
        return lhs.numberOfChildren == rhs.childCount &&
            lhs.numberOfAdults == rhs.adultCount &&
            lhs.squareFeet == rhs.squareFeet &&
            lhs.heatType == rhs.heatType &&
            lhs.dwellingType == rhs.dwellingType
    }
    
    public static func !=(lhs: HomeProfile, rhs: HomeProfileUpdateRequest) -> Bool {
        return !(lhs == rhs)
    }
    
    var isFilled: Bool {
        return numberOfChildren != nil &&
            numberOfAdults != nil &&
            squareFeet != nil &&
            heatType != nil &&
            dwellingType != nil
    }
}

public enum HomeType: String, Codable {
    case multiFamily = "MULTI_FAMILY"
    case singleFamily = "SINGLE_FAMILY"
    
    var displayString: String {
        switch self {
        case .multiFamily:
            return NSLocalizedString("Apartment/Condo", comment: "")
        case .singleFamily:
            return NSLocalizedString("House, Townhome, Row House", comment: "")
        }
    }
    
    var apiString: String {
        switch self {
        case .multiFamily:
            return "MULTI_FAMILY"
        case .singleFamily:
            return "SINGLE_FAMILY"
        }
    }
    
    static var allCases: [HomeType] {
        return [.multiFamily, .singleFamily]
    }
}

public enum HeatType: String, Codable {
    case naturalGas = "GAS"
    case electric = "ELEC"
    case other = "OTHER"
    case none = "NONE"
    
    var displayString: String {
        switch self {
        case .naturalGas:
            return NSLocalizedString("Natural Gas", comment: "")
        case .electric:
            return NSLocalizedString("Electric", comment: "")
        case .other:
            return NSLocalizedString("Other", comment: "")
        case .none:
            return NSLocalizedString("None", comment: "")
        }
    }
    
    var apiString: String {
        switch self {
        case .naturalGas:
            return "GAS"
        case .electric:
            return "ELEC"
        case .other:
            return "OTHER"
        case .none:
            return "NONE"
        }
    }
    
    static var allCases: [HeatType] {
        return [.naturalGas, .electric, .other, .none]
    }
}
