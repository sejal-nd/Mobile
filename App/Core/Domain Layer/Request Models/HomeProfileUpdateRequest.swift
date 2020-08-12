//
//  HomeProfileUpdateRequest.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/22/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct HomeProfileUpdateRequest: Encodable, Fillable, Equatable {
    let adultCount: Int?
    let childCount: Int?
    let heatType: HeatType?
    let squareFeet: Int?
    let dwellingType: HomeType?
    
    enum CodingKeys: String, CodingKey {
        case adultCount = "adult_count"
        case childCount = "child_count"
        case heatType = "heat_type"
        case squareFeet = "square_feet"
        case dwellingType = "dwelling_type"
    }
    
    init(numberOfChildren: Int? = nil, numberOfAdults: Int? = nil, squareFeet: Int? = nil, heatType: HeatType? = nil, homeType: HomeType? = nil) {
        self.childCount = numberOfChildren
        self.adultCount = numberOfAdults
        self.squareFeet = squareFeet
        self.heatType = heatType
        self.dwellingType = homeType
    }
    
    public static func ==(lhs: HomeProfileUpdateRequest, rhs: HomeProfileUpdateRequest) -> Bool {
        return lhs.childCount == rhs.childCount &&
            lhs.adultCount == rhs.adultCount &&
            lhs.squareFeet == rhs.squareFeet &&
            lhs.heatType == rhs.heatType &&
            lhs.dwellingType == rhs.dwellingType
    }
    
    public static func ==(lhs: HomeProfileUpdateRequest, rhs: HomeProfile) -> Bool {
        return lhs.childCount == rhs.numberOfChildren &&
            lhs.adultCount == rhs.numberOfAdults &&
            lhs.squareFeet == rhs.squareFeet &&
            lhs.heatType == rhs.heatType &&
            lhs.dwellingType == rhs.dwellingType
    }
    
    var isFilled: Bool {
        return childCount != nil &&
            adultCount != nil &&
            squareFeet != nil &&
            heatType != nil &&
            dwellingType != nil
    }
}
