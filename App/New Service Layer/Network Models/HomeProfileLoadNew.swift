//
//  HomeProfileLoadNew.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/22/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct HomeProfileLoadNew: Decodable, Fillable, Equatable {
    public var customerId: Int
    public var dwellingType: HomeType?
    public var squareFeet: Int?
    public var heatType: HeatType?
    public var numberOfAdults: Int?
    public var numberOfChildren: Int?
    
    enum CodingKeys: String, CodingKey {
        case data = "data"
        
        case customerId = "customerId"
        case dwellingType = "dwellingType"
        case squareFeet = "squareFeet"
        case heatType = "heatType"
        case numberOfAdults = "numberOfAdults"
        case numberOfChildren = "numberOfChildren"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                 forKey: .data)
        
        self.customerId = try data.decode(Int.self,
                                          forKey: .customerId)
        self.dwellingType = try data.decodeIfPresent(HomeType.self,
                                            forKey: .dwellingType)
        self.squareFeet = try data.decodeIfPresent(Int.self,
                                          forKey: .squareFeet)
        self.heatType = try data.decodeIfPresent(HeatType.self,
                                        forKey: .heatType)
        self.numberOfAdults = try data.decodeIfPresent(Int.self,
                                              forKey: .numberOfAdults)
        self.numberOfChildren = try data.decodeIfPresent(Int.self,
                                                forKey: .numberOfChildren)
    }
    
    public static func ==(lhs: HomeProfileLoadNew, rhs: HomeProfileLoadNew) -> Bool {
        return lhs.numberOfChildren == rhs.numberOfChildren &&
            lhs.numberOfAdults == rhs.numberOfAdults &&
            lhs.squareFeet == rhs.squareFeet &&
            lhs.heatType == rhs.heatType &&
            lhs.dwellingType == rhs.dwellingType
    }
    
    public static func ==(lhs: HomeProfileLoadNew, rhs: HomeProfileUpdateRequest) -> Bool {
        return lhs.numberOfChildren == rhs.childCount &&
            lhs.numberOfAdults == rhs.adultCount &&
            lhs.squareFeet == rhs.squareFeet &&
            lhs.heatType == rhs.heatType &&
            lhs.dwellingType == rhs.dwellingType
    }
    
    public static func !=(lhs: HomeProfileLoadNew, rhs: HomeProfileUpdateRequest) -> Bool {
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

public enum HomeType: Int, Codable {
    case multiFamily, singleFamily
    
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

public enum HeatType: Int, Codable {
    case naturalGas, electric, other, none
    
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
