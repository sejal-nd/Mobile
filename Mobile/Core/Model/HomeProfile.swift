//
//  HomeProfile.swift
//  Mobile
//
//  Created by Sam Francis on 10/26/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

struct HomeProfile: Mappable, Equatable {
    let numberOfChildren: Int?
    let numberOfAdults: Int?
    let squareFeet: Int?
    let heatType: String?
    let dwellingType: String?
    
    init(map: Mapper) throws {
        numberOfChildren = map.optionalFrom("numberOfChildren")
        numberOfAdults = map.optionalFrom("numberOfAdults")
        squareFeet = map.optionalFrom("squareFeet")
        heatType = map.optionalFrom("heatType")
        dwellingType = map.optionalFrom("dwellingType")
    }
    
    init(numberOfChildren: Int?, numberOfAdults: Int?, squareFeet: Int?, heatType: String?, dwellingType: String?) {
        self.numberOfChildren = numberOfChildren
        self.numberOfAdults = numberOfAdults
        self.squareFeet = squareFeet
        self.heatType = heatType
        self.dwellingType = dwellingType
    }
    
    static func ==(lhs: HomeProfile, rhs: HomeProfile) -> Bool {
        return lhs.numberOfChildren == rhs.numberOfChildren &&
            lhs.numberOfAdults == rhs.numberOfAdults &&
            lhs.squareFeet == rhs.squareFeet &&
            lhs.heatType == rhs.heatType &&
            lhs.dwellingType == rhs.dwellingType
    }
    
}

