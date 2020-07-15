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
    
    let initialHomeProfile: Observable<HomeProfileLoadNew>
    let accountDetail: AccountDetail
    
    let numberOfChildren = BehaviorRelay<Int?>(value: nil)
    let numberOfAdults = BehaviorRelay<Int?>(value: nil)
    let heatType = BehaviorRelay<HeatType?>(value: nil)
    let homeType = BehaviorRelay<HomeType?>(value: nil)
    let homeSizeEntry = BehaviorRelay<String?>(value: nil)
    
    let saveAction: Observable<Void>
    let saveTracker = ActivityTracker()
    
    init(accountDetail: AccountDetail, saveAction: Observable<Void>) {
        self.accountDetail = accountDetail
        self.saveAction = saveAction
        
        initialHomeProfile = UsageServiceNew.rx.fetchHomeProfile(accountNumber: accountDetail.accountNumber, premiseNumber: accountDetail.premiseNumber!)
            .share(replay: 1)
    }
    
    private(set) lazy var homeSizeError: Observable<String?> = self.homeSizeEntry.asObservable()
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
    
    private(set) lazy var updatedHomeProfile: Observable<HomeProfileUpdateRequest> = Observable
        .combineLatest(self.numberOfChildren.asObservable(),
                       self.numberOfAdults.asObservable(),
                       self.homeSizeEntry.asObservable().map { $0.flatMap(Int.init) },
                       self.heatType.asObservable(),
                       self.homeType.asObservable())
        .map {
            HomeProfileUpdateRequest(numberOfChildren: $0.0, numberOfAdults: $0.1, squareFeet: $0.2, heatType: $0.3, homeType: $0.4)
    }
    
    private(set) lazy var enableSave: Observable<Bool> = Observable.combineLatest(self.initialHomeProfile,
                                                                                  self.updatedHomeProfile,
                                                                                  self.homeSizeError.startWith(nil).isNil())
    { initialHomeProfile, updatedHomeProfile, homeSizeErrorIsNil in
        initialHomeProfile != updatedHomeProfile &&
            updatedHomeProfile.isFilled &&
            homeSizeErrorIsNil
    }
    .startWith(false)
    
    private(set) lazy var saveA11yLabel: Driver<String> = Observable.combineLatest(self.homeType.asObservable(),
                                                                                    self.heatType.asObservable(),
                                                                                    self.numberOfAdults.asObservable(),
                                                                                    self.numberOfChildren.asObservable(),
                                                                                    self.homeSizeError)
    { homeType, heatType, numAdults, numChild, homeSizeError in
        var a11yString = ""
        if homeType == nil {
            a11yString += NSLocalizedString("Home type is required,", comment: "")
        }
        if heatType == nil {
            a11yString += NSLocalizedString("Heating fuel is required,", comment: "")
        }
        if numAdults == nil {
            a11yString += NSLocalizedString("Number of adults is required,", comment: "")
        }
        if numChild == nil {
            a11yString += NSLocalizedString("Number of children is required,", comment: "")
        }
        if let homeSizeErr = homeSizeError {
            a11yString += homeSizeErr + ","
        }
        
        if a11yString.isEmpty {
            return NSLocalizedString("Save Profile", comment: "")
        } else {
            return String(format: NSLocalizedString("%@ Save Profile", comment: ""), a11yString)
        }
    }.asDriver(onErrorJustReturn: "")
    
    private lazy var save: Observable<Event<Void>> = self.saveAction
        .do(onNext: { GoogleAnalytics.log(event: .homeProfileSave) })
        .withLatestFrom(self.updatedHomeProfile)
        .flatMapLatest { [weak self] updatedHomeProfile -> Observable<Event<Void>> in
            guard let self = self else { return .empty() }
            return UsageServiceNew.rx.updateHomeProfile(accountNumber: self.accountDetail.accountNumber, premiseNumber: self.accountDetail.premiseNumber!, request: updatedHomeProfile)
                .trackActivity(self.saveTracker)
                .materialize()
    }
    .share()
    
    private(set) lazy var saveSuccess: Driver<Void> = self.save.elements()
        .do(onNext: { GoogleAnalytics.log(event: .homeProfileConfirmation) })
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
            let localizedText = NSLocalizedString("Number of Adults, %@", comment: "")
            guard let numberOfAdults = numberOfAdults else {
                return String(format: localizedText, NSLocalizedString("required", comment: ""))
            }
            return String(format: localizedText, String(numberOfAdults))
        }
    
    private(set) lazy var numberOfChildrenA11y: Driver<String> = self.numberOfChildren.asDriver()
        .map { numberOfChildren -> String in
            let localizedText = NSLocalizedString("Number of Children, %@", comment: "")
            guard let numberOfChildren = numberOfChildren else {
                return String(format: localizedText, NSLocalizedString("required", comment: ""))
            }
            return String(format: localizedText, String(numberOfChildren))
        }
}
