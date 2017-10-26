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
    
    let numberOfAdultsOptions = (1...10).map { $0 == 10 ? "\($0)+" : "\($0)" }
    let numberOfChildrenOptions = (0...10).map { $0 == 10 ? "\($0)+" : "\($0)" }
    
    let initialHomeProfile: Observable<HomeProfile>
    let accountDetail: AccountDetail
    let usageService: UsageService
    let homeSizeEntry: Observable<String>
    
    let numberOfChildren = Variable<Int?>(nil)
    let numberOfAdults = Variable<Int?>(nil)
    let squareFeet = Variable<Int?>(nil)
    let heatType = Variable<String?>(nil)
    let dwellingType = Variable<String?>(nil)
    
    init(usageService: UsageService, accountDetail: AccountDetail, homeSizeEntry: Observable<String>) {
        self.homeSizeEntry = homeSizeEntry
        self.usageService = usageService
        self.accountDetail = accountDetail
        
        initialHomeProfile = usageService.fetchHomeProfile(accountNumber: accountDetail.accountNumber, premiseNumber: accountDetail.premiseNumber!)
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
    
    private(set) lazy var updatedHomeProfile: Observable<HomeProfile> = Observable.combineLatest(self.numberOfChildren.asObservable(),
                                                                                                 self.numberOfAdults.asObservable(),
                                                                                                 self.squareFeet.asObservable(),
                                                                                                 self.heatType.asObservable(),
                                                                                                 self.dwellingType.asObservable(),
                                                                                                 resultSelector: HomeProfile.init)
    
    private(set) lazy var enableSave: Observable<Bool> = Observable.combineLatest(self.initialHomeProfile,
                                                                                  self.updatedHomeProfile,
                                                                                  self.homeSizeError.isNil())
    { $0 == $1 && !$2 }
}
