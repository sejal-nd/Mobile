//
//  HomeProfile.swift
//  Mobile
//
//  Created by Sam Francis on 10/26/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import Mapper

enum HomeType: Int {
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

enum HeatType: Int {
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

struct HomeProfile: Mappable, Equatable, Fillable {
    let numberOfChildren: Int?
    let numberOfAdults: Int?
    let squareFeet: Int?
    let heatType: HeatType?
    let homeType: HomeType?
    
    init(map: Mapper) throws {
        numberOfChildren = map.optionalFrom("numberOfChildren")
        numberOfAdults = map.optionalFrom("numberOfAdults")
        squareFeet = map.optionalFrom("squareFeet")
        
        heatType = map.optionalFrom("heatType") { heatType -> HeatType? in
            guard let heatTypeString = heatType as? String else { return nil }
            switch heatTypeString {
            case HeatType.naturalGas.apiString: return .naturalGas
            case HeatType.electric.apiString: return .electric
            case HeatType.other.apiString: return .other
            case HeatType.none.apiString: return HeatType.none
            default: return nil
            }
        }
        
        homeType = map.optionalFrom("dwellingType") { homeType -> HomeType? in
            guard let homeTypeString = homeType as? String else { return nil }
            switch homeTypeString {
            case HomeType.multiFamily.apiString: return .multiFamily
            case HomeType.singleFamily.apiString: return .singleFamily
            default: return nil
            }
        }
    }
    
    init(numberOfChildren: Int? = nil, numberOfAdults: Int? = nil, squareFeet: Int? = nil, heatType: HeatType? = nil, homeType: HomeType? = nil) {
        self.numberOfChildren = numberOfChildren
        self.numberOfAdults = numberOfAdults
        self.squareFeet = squareFeet
        self.heatType = heatType
        self.homeType = homeType
    }
    
    static func ==(lhs: HomeProfile, rhs: HomeProfile) -> Bool {
        return lhs.numberOfChildren == rhs.numberOfChildren &&
            lhs.numberOfAdults == rhs.numberOfAdults &&
            lhs.squareFeet == rhs.squareFeet &&
            lhs.heatType == rhs.heatType &&
            lhs.homeType == rhs.homeType
    }
    
    var isFilled: Bool {
        return numberOfChildren != nil &&
            numberOfAdults != nil &&
            squareFeet != nil &&
            heatType != nil &&
            homeType != nil
    }
    
}

