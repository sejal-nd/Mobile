//
//  MyHomeProfileViewModel.swift
//  Mobile
//
//  Created by Sam Francis on 10/26/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class MyHomeProfileViewModel {
    let homeTypes = [NSLocalizedString("Apartment/Condo", comment: ""),
                     NSLocalizedString("House, Townhome, Row House", comment: "")]
    
    let heatingFuels = [NSLocalizedString("Natural Gas", comment: ""),
                        NSLocalizedString("Electric", comment: ""),
                        NSLocalizedString("Other", comment: ""),
                        NSLocalizedString("None", comment: "")]
    
    let numberOfAdults = (1...10).map { $0 == 10 ? "\($0)+" : "\($0)" }
    let numberOfChildren = (0...10).map { $0 == 10 ? "\($0)+" : "\($0)" }
    
    let homeSizeEntry: Observable<String>
    
    init(usageService: UsageService, homeSizeEntry: Observable<String>) {
        self.homeSizeEntry = homeSizeEntry
        
//        usageService.fetch
    }
    
    private(set) lazy var homeSizeError: Observable<String?> = self.homeSizeEntry
        .map {
            guard let squareFeet = Int($0) else {
                return NSLocalizedString("Square footage is required", comment: "")
            }
            
            if squareFeet < 50 {
                return NSLocalizedString("Must be at least 50", comment: "")
            } else if squareFeet > 1_000_000 {
                return NSLocalizedString("Must be less than 1,000,000", comment: "")
            } else {
                return nil
            }
    }
}
