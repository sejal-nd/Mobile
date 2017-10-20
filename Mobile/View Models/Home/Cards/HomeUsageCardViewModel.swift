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
    //var switchingSegment = false
    
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
    
    // MARK: Bar Description Box Drivers
    
    private(set) lazy var barDescriptionDateLabelText: Driver<String?> =
        Driver.combineLatest(self.billComparisonDriver, self.barGraphSelectionStates.asDriver()) { [weak self] billComparison, selectionStates in
            guard let `self` = self else { return nil }
            if selectionStates[0].value { // No data
                return NSLocalizedString("Previous Bill", comment: "")
            } else if selectionStates[1].value { // Previous
                return "\(billComparison.compared!.startDate.fullMonthAndDayString) - \(billComparison.compared!.endDate.fullMonthAndDayString)"
            } else if selectionStates[2].value { // Current
                return "\(billComparison.reference!.startDate.fullMonthAndDayString) - \(billComparison.reference!.endDate.fullMonthAndDayString)"
            }
            return nil
    }
    
//    private(set) lazy var barDescriptionTotalBillLabelText: Driver<String?> =
//
//    private(set) lazy var barDescriptionDetailLabelText: Driver<String?> =
//        Driver.combineLatest(self.currentBillComparison.asDriver(),
//                             self.barGraphSelectionStates.asDriver(),
//                             self.electricForecast.asDriver(),
//                             self.gasForecast.asDriver(),
//                             self.electricGasSelectedSegmentIndex.asDriver(),
//                             self.isFetching.asDriver()) { [weak self] currentBillComparison, selectionStates, elecForecast, gasForecast, dontUseThis, isFetching in
//                                // We only combine electricGasSelectedSegmentIndex here to trigger a driver update, then we use self.isGas to determine
//                                guard let `self` = self else { return nil }
//                                if isFetching { return nil }
//                                guard let billComparison = currentBillComparison else { return nil }
//                                let localizedPrevCurrString = NSLocalizedString("Your bill was %@. You used an average of %@ %@ per day.", comment: "")
//                                if selectionStates[0].value { // No data
//                                    return NSLocalizedString("Not enough data available.", comment: "")
//                                } else if selectionStates[1].value { // Previous
//                                    let daysInBillPeriod = abs(billComparison.compared!.startDate.interval(ofComponent: .day, fromDate: billComparison.compared!.endDate))
//                                    let avgUsagePerDay = billComparison.compared!.usage / Double(daysInBillPeriod)
//                                    if billComparison.compared!.charges < 0 {
//                                        let billCreditString = NSLocalizedString("You had a bill credit of %@. You used an average of %@ %@ per day.", comment: "")
//                                        return String(format: billCreditString, abs(billComparison.compared!.charges).currencyString!, String(format: "%.2f", avgUsagePerDay), billComparison.meterUnit)
//                                    } else {
//                                        return String(format: localizedPrevCurrString, billComparison.compared!.charges.currencyString!, String(format: "%.2f", avgUsagePerDay), billComparison.meterUnit)
//                                    }
//                                } else if selectionStates[2].value { // Current
//                                    let daysInBillPeriod = abs(billComparison.reference!.startDate.interval(ofComponent: .day, fromDate: billComparison.reference!.endDate))
//                                    let avgUsagePerDay = billComparison.reference!.usage / Double(daysInBillPeriod)
//                                    if billComparison.reference!.charges < 0 {
//                                        let billCreditString = NSLocalizedString("You had a bill credit of %@. You used an average of %@ %@ per day.", comment: "")
//                                        return String(format: billCreditString, abs(billComparison.reference!.charges).currencyString!, String(format: "%.2f", avgUsagePerDay), billComparison.meterUnit)
//                                    } else {
//                                        return String(format: localizedPrevCurrString, billComparison.reference!.charges.currencyString!, String(format: "%.2f", avgUsagePerDay), billComparison.meterUnit)
//                                    }
//                                } else if selectionStates[3].value { // Projected
//                                    let localizedString = NSLocalizedString("Your bill is projected to be around %@. You've spent about %@ so far this bill period. " +
//                                        "This is an estimate and the actual amount may vary based on your energy use, taxes, and fees.", comment: "")
//                                    if let gasForecast = gasForecast, self.isGas {
//                                        if let projectedCost = gasForecast.projectedCost, let toDateCost = gasForecast.toDateCost {
//                                            return String(format: localizedString, projectedCost.currencyString!, toDateCost.currencyString!)
//                                        }
//                                    }
//                                    if let elecForecast = elecForecast, !self.isGas {
//                                        if let projectedCost = elecForecast.projectedCost, let toDateCost = elecForecast.toDateCost {
//                                            return String(format: localizedString, projectedCost.currencyString!, toDateCost.currencyString!)
//                                        }
//                                    }
//                                } else if selectionStates[4].value { // Projection Not Available
//                                    return NSLocalizedString("Data becomes available once you are more than 7 days into the billing cycle.", comment: "")
//                                }
//                                return nil
//    }
//
    
    // MARK: Selection States
    
    func setBarSelected(tag: Int) {
        for i in stride(from: 0, to: barGraphSelectionStates.value.count, by: 1) {
            let boolVar = barGraphSelectionStates.value[i]
            boolVar.value = i == tag
        }
        barGraphSelectionStates.value = barGraphSelectionStates.value // Trigger Variable onNext
    }

}
