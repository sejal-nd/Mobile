//
//  HomeUsageCardViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 10/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class HomeUsageCardViewModel {
    
    let disposeBag = DisposeBag()
    
    let accountDetailEvents: Observable<Event<AccountDetail>>
    private let usageService: UsageService
    
    let fetchingTracker: ActivityTracker
    let loadingTracker = ActivityTracker()
    var initialLoadComplete = false
    
    let electricGasSelectedSegmentIndex = Variable(0)
    
    /*
     * 0 = No Data
     * 1 = Previous
     * 2 = Current
     */
    let barGraphSelectionStates = Variable([Variable(false), Variable(false), Variable(false)])
    
    required init(accountDetailEvents: Observable<Event<AccountDetail>>,
                  usageService: UsageService,
                  fetchingTracker: ActivityTracker) {
        self.accountDetailEvents = accountDetailEvents
        self.usageService = usageService
        self.fetchingTracker = fetchingTracker
    }
    
    private(set) lazy var billComparisonEvents: Observable<Event<BillComparison>> = Observable.combineLatest(self.accountDetailEvents.elements(),
                                                                                                             self.electricGasSelectedSegmentIndex.asObservable())
        .flatMapLatest { [unowned self] accountDetail, segmentIndex -> Observable<Event<BillComparison>> in
            guard let premiseNumber = accountDetail.premiseNumber else { return .empty() }
            guard let serviceType = accountDetail.serviceType else { return .empty() }
            if serviceType.uppercased() != "GAS" && serviceType.uppercased() != "ELECTRIC" && serviceType.uppercased() != "GAS/ELECTRIC" {
                 return .empty()
            }

            var gas = false // Default to electric
            if serviceType.uppercased() == "GAS" { // If account is gas only
                gas = true
            } else if serviceType.uppercased() == "GAS/ELECTRIC" { // Use value of segmented control
                gas = segmentIndex == 1
            }
            
            let activeTracker = self.initialLoadComplete ? self.loadingTracker : self.fetchingTracker
            self.initialLoadComplete = true
            return self.usageService.fetchBillComparison(accountNumber: accountDetail.accountNumber, premiseNumber: premiseNumber, yearAgo: false, gas: gas)
                .trackActivity(activeTracker)
                .materialize()
            
        }.shareReplay(1)
    
    private(set) lazy var accountDetailDriver: Driver<AccountDetail> = self.accountDetailEvents.elements().asDriver(onErrorDriveWith: .empty())
    private(set) lazy var billComparisonDriver: Driver<BillComparison> = self.billComparisonEvents.elements().asDriver(onErrorDriveWith: .empty())
    
//    private(set) lazy var billComparisonError: Observable<Bool> = self.billComparisonEvents.errors().map {
//        if let serviceError = $0 as? ServiceError {
//            return true
//        }
//        return false
//    }
    
    private(set) lazy var shouldShowErrorView: Driver<Bool> =
        Observable.combineLatest(self.loadingTracker.asObservable(), self.billComparisonEvents) {
            !$0 && $1.error != nil
        }.asDriver(onErrorDriveWith: .empty())
    
    
    private(set) lazy var shouldShowBillComparisonContentView: Driver<Bool> =
        Observable.combineLatest(self.loadingTracker.asObservable(), self.billComparisonEvents) {
            !$0 && $1.error == nil
        }.asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var shouldShowElectricGasSegmentedControl: Driver<Bool> = self.accountDetailDriver.map {
        guard let serviceType = $0.serviceType else { return false }
        return serviceType.uppercased() == "GAS/ELECTRIC"
    }
    
    private(set) lazy var noPreviousData: Driver<Bool> = self.billComparisonDriver.map {
        return $0.compared == nil
    }
    
    // MARK: No Data Bar Drivers
    
    private(set) lazy var noDataBarDateLabelText: Driver<String?> = self.billComparisonDriver.map {
        guard let reference = $0.reference else { return nil }
        let lastMonthDate = Calendar.opCoTime.date(byAdding: .month, value: -1, to: reference.endDate)!
        return lastMonthDate.shortMonthAndDayString.uppercased()
    }
    
    // MARK: Previous Bar Drivers
    
    private(set) lazy var previousBarHeightConstraintValue: Driver<CGFloat> = self.billComparisonDriver.map {
        guard let reference = $0.reference else { return 134 }
        guard let compared = $0.compared else { return 0 }
        if compared.charges < 0 {
            return 3
        } else if compared.charges >= reference.charges {
                return 134
        } else {
            let fraction = CGFloat(134.0 * (compared.charges / reference.charges))
            return fraction > 3 ? fraction : 3
        }
    }
    
    private(set) lazy var previousBarDollarLabelText: Driver<String?> = self.billComparisonDriver.map {
        guard let compared = $0.compared else { return nil }
        return compared.charges.currencyString
    }
    
    private(set) lazy var previousBarDateLabelText: Driver<String?> = self.billComparisonDriver.map {
        guard let compared = $0.compared else { return nil }
        return compared.endDate.shortMonthAndDayString.uppercased()
    }
    
    // MARK: Current Bar Drivers
    
    private(set) lazy var currentBarHeightConstraintValue: Driver<CGFloat> = self.billComparisonDriver.map {
        guard let reference = $0.reference else { return 0 }
        guard let compared = $0.compared else { return 134 }
        if reference.charges < 0 {
            return 3
        } else if reference.charges >= compared.charges {
                return 134
        } else {
            let fraction = CGFloat(134.0 * (reference.charges / compared.charges))
            return fraction > 3 ? fraction : 3
        }
    }
    
    private(set) lazy var currentBarDollarLabelText: Driver<String?> = self.billComparisonDriver.map {
        guard let reference = $0.reference else { return nil }
        return reference.charges.currencyString
    }
    
    private(set) lazy var currentBarDateLabelText: Driver<String?> = self.billComparisonDriver.map {
        guard let reference = $0.reference else { return nil }
        return reference.endDate.shortMonthAndDayString.uppercased()
    }
    
    
    // MARK: Selection States
    
    func setBarSelected(tag: Int) {
        for i in stride(from: 0, to: barGraphSelectionStates.value.count, by: 1) {
            let boolVar = barGraphSelectionStates.value[i]
            boolVar.value = i == tag
        }
        barGraphSelectionStates.value = barGraphSelectionStates.value // Trigger Variable onNext
    }

}
