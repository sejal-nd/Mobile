//
//  MyHomeProfileViewModel.swift
//  Mobile
//
//  Created by Sam Francis on 10/26/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class MyHomeProfileViewModel {
    
    let numberOfAdultsOptions = Array(1...10)
    var numberOfAdultsDisplayOptions: [String] {
        return numberOfAdultsOptions.map { $0 == 10 ? "\($0)+" : "\($0)" }
    }
    
    let numberOfChildrenOptions = Array(0...10)
    var numberOfChildrenDisplayOptions: [String] {
        return numberOfChildrenOptions.map { $0 == 10 ? "\($0)+" : "\($0)" }
    }
    
    let initialHomeProfile: Observable<HomeProfile>
    let accountDetail: AccountDetail
    let usageService: UsageService
    
    let numberOfChildren = Variable<Int?>(nil)
    let numberOfAdults = Variable<Int?>(nil)
    let heatType = Variable<HeatType?>(nil)
    let homeType = Variable<HomeType?>(nil)
    let homeSizeEntry = Variable<String?>(nil)
    
    let saveAction: Observable<Void>
    let saveTracker = ActivityTracker()
    
    init(usageService: UsageService, accountDetail: AccountDetail, saveAction: Observable<Void>) {
        self.usageService = usageService
        self.accountDetail = accountDetail
        self.saveAction = saveAction
        
        initialHomeProfile = usageService.fetchHomeProfile(accountNumber: accountDetail.accountNumber, premiseNumber: accountDetail.premiseNumber!)
            .shareReplay(1)
        
    }
    
    private(set) lazy var homeSizeError: Observable<String?> = self.homeSizeEntry.asObservable()
        .skip(1)
        .map {
            guard let homeSizeEntry = $0, let squareFeet = Int(homeSizeEntry) else {
                return NSLocalizedString("Square footage is required", comment: "")
            }
            
            if squareFeet < 50 {
                return NSLocalizedString("Must be at least 50", comment: "")
            } else if squareFeet > 1_000_000 {
                return NSLocalizedString("Must be at most 1,000,000", comment: "")
            } else {
                return nil
            }
    }
    
    private(set) lazy var updatedHomeProfile: Observable<HomeProfile> = Observable
        .combineLatest(self.numberOfChildren.asObservable(),
                       self.numberOfAdults.asObservable(),
                       self.homeSizeEntry.asObservable().map { $0.flatMap(Int.init) },
                       self.heatType.asObservable(),
                       self.homeType.asObservable())
        .map(HomeProfile.init)
    
    private(set) lazy var enableSave: Observable<Bool> = Observable.combineLatest(self.initialHomeProfile,
                                                                                  self.updatedHomeProfile,
                                                                                  self.homeSizeError.startWith(nil).isNil())
    { initialHomeProfile, updatedHomeProfile, homeSizeErrorIsNil in
        initialHomeProfile != updatedHomeProfile &&
            updatedHomeProfile.isFilled &&
            homeSizeErrorIsNil
    }
    .startWith(false)
    
    private lazy var save: Observable<Event<Void>> = self.saveAction
        .withLatestFrom(self.updatedHomeProfile)
        .flatMapLatest { [weak self] updatedHomeProfile -> Observable<Event<Void>> in
            guard let `self` = self else { return .empty() }
            return self.usageService.updateHomeProfile(accountNumber: self.accountDetail.accountNumber,
                                                       premiseNumber: self.accountDetail.premiseNumber!,
                                                       homeProfile: updatedHomeProfile)
                .trackActivity(self.saveTracker)
                .materialize()
        }
        .share()
    
    private(set) lazy var saveSuccess: Driver<Void> = self.save.elements()
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var saveErrors: Driver<String> = self.save.errors()
        .map { ($0 as? ServiceError)?.serviceCode ?? $0.localizedDescription }
        .asDriver(onErrorDriveWith: .empty())
    
    
    //MARK: Accessibility
    
    private(set) lazy var homeTypeA11y: Driver<String> = self.homeType.asDriver()
        .map { homeType -> String in
            let localizedText = NSLocalizedString("Home Type, %@", comment: "")
            guard let homeType = homeType else {
                return String(format: localizedText, NSLocalizedString("required", comment: ""))
            }
            return String(format: localizedText, homeType.displayString)
    }
    
    private(set) lazy var heatingFuelA11y: Driver<String> = self.heatType.asDriver()
        .map { heatingFuel -> String in
            let localizedText = NSLocalizedString("Heating Fuel, %@", comment: "")
            guard let heatingFuel = heatingFuel else {
                return String(format: localizedText, NSLocalizedString("required", comment: ""))
            }
            return String(format: localizedText, heatingFuel.displayString)
    }
    
    private(set) lazy var numberOfAdultsA11y: Driver<String> = self.numberOfAdults.asDriver()
        .map { numberOfAdults -> String in
            let localizedText = NSLocalizedString("Number of Adults, %d", comment: "")
            guard let numberOfAdults = numberOfAdults else {
                return String(format: localizedText, NSLocalizedString("required", comment: ""))
            }
            return String(format: localizedText, numberOfAdults)
    }
    
    private(set) lazy var numberOfChildrenA11y: Driver<String> = self.numberOfChildren.asDriver()
        .map { numberOfChildren -> String in
            let localizedText = NSLocalizedString("Number of Children, %d", comment: "")
            guard let numberOfChildren = numberOfChildren else {
                return String(format: localizedText, NSLocalizedString("required", comment: ""))
            }
            return String(format: localizedText, numberOfChildren)
    }
}
