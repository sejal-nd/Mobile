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
    
    let electricGasSelectedSegmentIndex = Variable(0)
    
    /*
     * 0 = No Data
     * 1 = Previous
     * 2 = Current
     */
    let barGraphSelectionStates = Variable([Variable(false), Variable(false), Variable(true)])
    
    required init(accountDetailEvents: Observable<Event<AccountDetail>>,
                  usageService: UsageService,
                  fetchingTracker: ActivityTracker) {
        self.accountDetailEvents = accountDetailEvents
        self.usageService = usageService
        self.fetchingTracker = fetchingTracker
    }
    
    private(set) lazy var billComparisonEvents: Observable<Event<BillComparison>> = Observable.merge(self.accountDetailChanged, self.segmentedControlChanged).shareReplay(1)
    
    private(set) lazy var accountDetailChanged = self.accountDetailEvents.elements()
        .withLatestFrom(Observable.combineLatest(self.accountDetailEvents.elements(),
                                                 self.electricGasSelectedSegmentIndex.asObservable().startWith(0)))
        .flatMapLatest { [unowned self] accountDetail, segmentIndex -> Observable<Event<BillComparison>> in
            guard let premiseNumber = accountDetail.premiseNumber else { return .empty() }
            guard let serviceType = accountDetail.serviceType else { return .empty() }

            // Throw these Observable.errors to trigger a billComparisonDriver event even when we don't make the API call
            if !accountDetail.isResidential || accountDetail.isBGEControlGroup || accountDetail.isFinaled {
                return Observable.error(ServiceError(serviceCode: ServiceErrorCode.TcUnknown.rawValue)).materialize()
            }
            if serviceType.uppercased() != "GAS" && serviceType.uppercased() != "ELECTRIC" && serviceType.uppercased() != "GAS/ELECTRIC" {
                return Observable.error(ServiceError(serviceCode: ServiceErrorCode.TcUnknown.rawValue)).materialize()
            }
            
            var gas = false // Default to electric
            if serviceType.uppercased() == "GAS" { // If account is gas only
                gas = true
            } else if serviceType.uppercased() == "GAS/ELECTRIC" { // Use value of segmented control
                gas = segmentIndex == 1
            }
            
            return self.usageService.fetchBillComparison(accountNumber: accountDetail.accountNumber, premiseNumber: premiseNumber, yearAgo: false, gas: gas)
                .trackActivity(self.fetchingTracker)
                .materialize()
        }
    
    private(set) lazy var segmentedControlChanged = self.electricGasSelectedSegmentIndex.asObservable()
        .withLatestFrom(Observable.combineLatest(self.accountDetailEvents.elements(),
                                                 self.electricGasSelectedSegmentIndex.asObservable()))
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
            
            return self.usageService.fetchBillComparison(accountNumber: accountDetail.accountNumber, premiseNumber: premiseNumber, yearAgo: false, gas: gas)
                .trackActivity(self.loadingTracker)
                .materialize()
        }
    
    private(set) lazy var accountDetailDriver: Driver<AccountDetail> = self.accountDetailEvents.elements().asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var billComparisonDriver: Driver<BillComparison> = self.billComparisonEvents.elements().asDriver(onErrorDriveWith: .empty())
    
    
    // MARK: Bill Comparison
    
    private(set) lazy var shouldShowBillComparison: Driver<Bool> = Driver.combineLatest(self.shouldShowBillComparisonEmptyState,
                                                                                        self.shouldShowSmartEnergyRewards,
                                                                                        self.shouldShowSmartEnergyEmptyState) {
        return !$0 && !$1 && !$2
    }
    
    private(set) lazy var shouldShowBillComparisonEmptyState: Driver<Bool> = Driver.combineLatest(self.billComparisonEvents.asDriver(onErrorDriveWith: .empty()),
                                                                                                  self.shouldShowSmartEnergyRewards,
                                                                                                  self.shouldShowSmartEnergyEmptyState) {
        return $0.error != nil && !$1 && !$2
    }
    
    // Not currently using -- we'll show billComparisonEmptyStateView if any errors occur
    private(set) lazy var shouldShowErrorView: Driver<Bool> =
        Observable.combineLatest(self.loadingTracker.asObservable(), self.billComparisonEvents) { _, _ in
            return false //!$0 && $1.error != nil
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
        let lastMonthDate = Calendar.opCo.date(byAdding: .month, value: -1, to: reference.endDate)!
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
    
    // MARK: Bar Graph Button Accessibility Drivers
    
    private(set) lazy var previousBarA11yLabel: Driver<String?> = self.billComparisonDriver.map {
        guard let compared = $0.compared else { return nil }
        
        let dateString = "\(compared.startDate.fullMonthAndDayString) to \(compared.endDate.fullMonthAndDayString)"
        
        let localizedString = NSLocalizedString("Total bill: %@. Usage: %d %@", comment: "")
        let detailString = String(format: localizedString, compared.charges.currencyString!, Int(compared.usage), $0.meterUnit)
        
        return "\(dateString). \(detailString)"
    }
    
    private(set) lazy var currentBarA11yLabel: Driver<String?> = self.billComparisonDriver.map {
        guard let reference = $0.reference else { return nil }
        
        let dateString = "\(reference.startDate.fullMonthAndDayString) to \(reference.endDate.fullMonthAndDayString)"
        
        let localizedString = NSLocalizedString("Total bill: %@. Usage: %d %@", comment: "")
        let detailString = String(format: localizedString, reference.charges.currencyString!, Int(reference.usage), $0.meterUnit)
        
        return "\(dateString). \(detailString)"
    }
    
    // MARK: Bar Description Box Drivers
    
    private(set) lazy var barDescriptionDateLabelText: Driver<String?> =
        Driver.combineLatest(self.billComparisonDriver, self.barGraphSelectionStates.asDriver()) { [weak self] billComparison, selectionStates in
            guard let `self` = self else { return nil }
            if selectionStates[0].value { // No data
                return NSLocalizedString("Previous Bill - Not enough data available.", comment: "")
            } else if selectionStates[1].value { // Previous
                if let compared = billComparison.compared {
                    return "\(compared.startDate.fullMonthAndDayString) - \(compared.endDate.fullMonthAndDayString)"
                }
            } else if selectionStates[2].value { // Current
                if let reference = billComparison.reference {
                    return "\(reference.startDate.fullMonthAndDayString) - \(reference.endDate.fullMonthAndDayString)"
                }
            }
            return nil
        }
    
    private(set) lazy var barDescriptionTotalBillTitleLabelText: Driver<String?> =
        Driver.combineLatest(self.billComparisonDriver, self.barGraphSelectionStates.asDriver()) { [weak self] billComparison, selectionStates in
            guard let `self` = self else { return nil }
            if selectionStates[0].value {
                return nil
            } else {
                return NSLocalizedString("Total Bill", comment: "")
            }
        }
    
    private(set) lazy var barDescriptionTotalBillValueLabelText: Driver<String?> =
        Driver.combineLatest(self.billComparisonDriver, self.barGraphSelectionStates.asDriver()) { [weak self] billComparison, selectionStates in
            guard let `self` = self else { return nil }
            if selectionStates[1].value { // Previous
                if let compared = billComparison.compared {
                    return compared.charges.currencyString!
                }
            } else if selectionStates[2].value { // Current
                if let reference = billComparison.reference {
                    return reference.charges.currencyString!
                }
            }
            return nil
        }
    
    private(set) lazy var barDescriptionUsageTitleLabelText: Driver<String?> =
        Driver.combineLatest(self.billComparisonDriver, self.barGraphSelectionStates.asDriver()) { [weak self] billComparison, selectionStates in
            guard let `self` = self else { return nil }
            if selectionStates[0].value {
                return nil
            } else {
                return NSLocalizedString("Usage", comment: "")
            }
        }
    
    private(set) lazy var barDescriptionUsageValueLabelText: Driver<String?> =
        Driver.combineLatest(self.billComparisonDriver, self.barGraphSelectionStates.asDriver()) { [weak self] billComparison, selectionStates in
            guard let `self` = self else { return nil }
            if selectionStates[1].value { // Previous
                if let compared = billComparison.compared {
                    return "\(Int(compared.usage)) \(billComparison.meterUnit)"
                }
            } else if selectionStates[2].value { // Current
                if let reference = billComparison.reference {
                    return "\(Int(reference.usage)) \(billComparison.meterUnit)"
                }
            }
            return nil
        }
    
    // MARK: Selection States
    
    func setBarSelected(tag: Int) {
        for i in stride(from: 0, to: barGraphSelectionStates.value.count, by: 1) {
            let boolVar = barGraphSelectionStates.value[i]
            boolVar.value = i == tag
        }
        barGraphSelectionStates.value = barGraphSelectionStates.value // Trigger Variable onNext
    }
    
    // MARK: Smart Energy Rewards
    
    private(set) lazy var shouldShowSmartEnergyRewards: Driver<Bool> = self.accountDetailDriver.map {
        if $0.isBGEControlGroup && $0.isSERAccount {
            return $0.SERInfo.eventResults.count > 0
        }
        return false
    }
    
    private(set) lazy var shouldShowSmartEnergyEmptyState: Driver<Bool> = self.accountDetailDriver.map {
        if $0.isBGEControlGroup && $0.isSERAccount {
            return $0.SERInfo.eventResults.count == 0
        }
        return false
    }
    
    private(set) lazy var smartEnergyRewardsSeasonLabelText: Driver<String?> = self.accountDetailDriver.map {
        let events = $0.SERInfo.eventResults
        if let mostRecentEvent = events.last {
            let latestEventYear = Calendar.opCo.component(.year, from: mostRecentEvent.eventStart)
            return String(format: NSLocalizedString("Summer %d", comment: ""), latestEventYear)
        }
        return nil
    }

}