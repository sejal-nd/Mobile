//
//  UsageTabViewModel.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/20/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class UsageTabViewModel {
    
    let disposeBag = DisposeBag()
    
    
    // MARK: - Account Details
    
    let accountService: AccountService

    var accountDetail: AccountDetail? {
        didSet {
            guard let accountDetail = accountDetail else { return }
            
            switch Environment.shared.opco {
            case .bge:
                if accountDetail.peakRewards == "ACTIVE" {
                    usageToolCards.insert(MyUsageToolCard(image: UIImage(named: "ic_thermostat"), title: "PeakRewards"), at: 1) // Todo
                }
                
                if accountDetail.isSERAccount {
                    usageToolCards.append(MyUsageToolCard(image: UIImage(named: "ic_smartenergy"), title: "Smart Energy Rewards"))
                }
            case .comEd:
                usageToolCards.insert(MyUsageToolCard(image: UIImage(named: "ic_hourlypricing"), title: "Hourly Pricing"), at: 1)

                if accountDetail.isPTSAccount {
                    usageToolCards.append(MyUsageToolCard(image:UIImage(named: "ic_smartenergy"), title: "Peak Time Savings"))
                }
            case .peco:
                break
            }
        }
    }
    
    var usageToolCards = [MyUsageToolCard(image: UIImage(named: "ic_usagedata"), title: "View My Usage Data"), MyUsageToolCard(image: UIImage(named: "ic_Top5"), title: "Top 5 Energy Tips"), MyUsageToolCard(image: UIImage(named: "ic_residential"), title: "My Home Profile")]
    
    let fetchAllDataTrigger = PublishSubject<FetchingAccountState>()
    let fetchBillDataTrigger = PublishSubject<Void>()
    
    let refreshTracker = ActivityTracker()
    let switchAccountTracker = ActivityTracker()
    let billAnalysisTracker = ActivityTracker()
    
    private func activityTracker(forState state: FetchingAccountState) -> ActivityTracker {
        switch state {
        case .refresh:
            return refreshTracker
        case .switchAccount:
            return switchAccountTracker
        }
    }

    //MARK: - Init
    
    required init(accountService: AccountService, usageService: UsageService) {
        self.accountService = accountService
        self.usageService = usageService
    }
    
    private(set) lazy var accountDetailEvents: Observable<Event<AccountDetail>> = self.fetchAllDataTrigger
        .toAsyncRequest(activityTracker: { [weak self] in self?.activityTracker(forState: $0) },
                        requestSelector: { [unowned self] _ in
                            self.accountService.fetchAccountDetail(account: AccountsStore.shared.currentAccount)
        })
    
    private lazy var eligibleAccountDetails: Observable<AccountDetail> = self.accountDetailEvents.elements()
        .filter { $0.premiseNumber != nil }
    
    private(set) lazy var billComparisonEvents: Observable<Event<BillComparison>> = Observable
        .combineLatest(self.eligibleAccountDetails, self.lastYearPreviousBillSelectedSegmentIndex.asObservable())
        .toAsyncRequest(activityTracker: billAnalysisTracker,
                        requestSelector: { [unowned self] (accountDetail, index) in
                            self.usageService.fetchBillComparison(accountNumber: accountDetail.accountNumber,
                                                                  premiseNumber: accountDetail.premiseNumber!,
                                                                  yearAgo: index == 0,
                                                                  gas: self.isGas)
        })
    
    private(set) lazy var billForecastEvents: Observable<Event<BillForecastResult?>> = self.eligibleAccountDetails
        .toAsyncRequest(activityTracker: billAnalysisTracker,
                        requestSelector: { [unowned self] accountDetail in
                            guard !accountDetail.isAMIAccount else { return Observable.just(nil) }
                            return self.usageService.fetchBillForecast(accountNumber: accountDetail.accountNumber,
                                                                       premiseNumber: accountDetail.premiseNumber!)
                                .map { $0 }
        })
    
    private(set) lazy var billComparison: Driver<BillComparison> = self.billComparisonEvents.elements()
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var billForecast: Driver<BillForecastResult?> = self.billForecastEvents.elements()
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var noPreviousData: Driver<Bool> = self.billComparison.map { $0.compared == nil }

    
    // RX CODE C / P Bill ANalysis
    
    
    let usageService: UsageService
    
    
    /*
     * 0 = No Data
     * 1 = Previous
     * 2 = Current
     * 3 = Projected
     * 4 = Projection Not Available
     */
    let barGraphSelectionStates = Variable([Variable(false), Variable(false), Variable(false), Variable(false), Variable(false)])
    
    /*
     * 0 = Bill Period
     * 1 = Weather
     * 2 = Other
     */
    let likelyReasonsSelectionStates = Variable([Variable(true), Variable(false), Variable(false)])
    
    private var currentFetchDisposable: Disposable?
    let isFetching = Variable(false)
    let isError = Variable(false)
    
    let electricGasSelectedSegmentIndex = Variable(0)
    let lastYearPreviousBillSelectedSegmentIndex = Variable(1)
    var fetchedForecast = false // Used so that we only fetch it the first load
    
    private(set) lazy var shouldShowBillComparisonContentView: Driver<Bool> =
        Driver.combineLatest(self.isFetching.asDriver(), self.isError.asDriver(), self.shouldShowBillComparisonEmptyState).map {
            !$0 && !$1 && !$2
    }
    
    private(set) lazy var shouldShowBillComparisonEmptyState: Driver<Bool> =
        Driver.combineLatest(self.isFetching.asDriver(), self.isError.asDriver(), self.billComparison).map {
            if $0 || $1 {
                return false
            }
            
            return $2.reference == nil
    }
    
    // MARK: No Data Bar Drivers
    
    private(set) lazy var noDataBarDateLabelText: Driver<String?> =
        Driver.combineLatest(self.billComparison, self.lastYearPreviousBillSelectedSegmentIndex.asDriver()) {
            guard let reference = $0.reference else { return nil }
            if $1 == 0 { // Last Year
                let lastYearDate = Calendar.opCo.date(byAdding: .year, value: -1, to: reference.endDate)!
                return "\(Calendar.opCo.component(.year, from: lastYearDate))"
            } else { // Previous Bill
                let lastMonthDate = Calendar.opCo.date(byAdding: .month, value: -1, to: reference.endDate)!
                return lastMonthDate.shortMonthAndDayString.uppercased()
            }
    }
    
    // MARK: Previous Bar Drivers
    
    private(set) lazy var previousBarHeightConstraintValue: Driver<CGFloat> =
        Driver.combineLatest(self.billComparison, self.projectedCost) { billComparison, projectedCost in
            guard let reference = billComparison.reference else { return 134 }
            guard let compared = billComparison.compared else { return 0 }
            if compared.charges < 0 {
                return 3
            } else if let projectedCost = projectedCost { // We are displaying a projection
                if max(projectedCost, reference.charges, compared.charges) == compared.charges {
                    return 134
                } else if max(projectedCost, reference.charges) == projectedCost {
                    let fraction = CGFloat(134.0 * (compared.charges / projectedCost))
                    return fraction > 3 ? fraction : 3
                } else {
                    let fraction = CGFloat(134.0 * (compared.charges / reference.charges))
                    return fraction > 3 ? fraction : 3
                }
            } else {
                if compared.charges >= reference.charges {
                    return 134
                } else {
                    let fraction = CGFloat(134.0 * (compared.charges / reference.charges))
                    return fraction > 3 ? fraction : 3
                }
            }
    }
    
    private(set) lazy var previousBarDollarLabelText: Driver<String?> = self.billComparison
        .map { $0.compared?.charges.currencyString }
    
    private(set) lazy var previousBarDateLabelText: Driver<String?> =
        Driver.combineLatest(self.billComparison, self.lastYearPreviousBillSelectedSegmentIndex.asDriver()) {
            guard let compared = $0.compared else { return nil }
            if $1 == 0 { // Last Year
                return "\(Calendar.opCo.component(.year, from: compared.endDate))"
            } else { // Previous Bill
                return compared.endDate.shortMonthAndDayString.uppercased()
            }
    }
    
    // MARK: Current Bar Drivers
    
    private(set) lazy var currentBarHeightConstraintValue: Driver<CGFloat> =
        Driver.combineLatest(self.billComparison, self.projectedCost) { billComparison, projectedCost in
            guard let reference = billComparison.reference else { return 0 }
            guard let compared = billComparison.compared else { return 134 }
            if reference.charges < 0 {
                return 3
            } else if let projectedCost = projectedCost { // We are displaying a projection
                if max(projectedCost, reference.charges, compared.charges) == reference.charges {
                    return 134
                } else if max(projectedCost, compared.charges) == projectedCost {
                    let fraction = CGFloat(134.0 * (reference.charges / projectedCost))
                    return fraction > 3 ? fraction : 3
                } else {
                    let fraction = CGFloat(134.0 * (reference.charges / compared.charges))
                    return fraction > 3 ? fraction : 3
                }
            } else {
                if reference.charges >= compared.charges {
                    return 134
                } else {
                    let fraction = CGFloat(134.0 * (reference.charges / compared.charges))
                    return fraction > 3 ? fraction : 3
                }
            }
    }
    
    private(set) lazy var currentBarDollarLabelText: Driver<String?> = self.billComparison.map {
        guard let reference = $0.reference else { return nil }
        return reference.charges.currencyString
    }
    
    private(set) lazy var currentBarDateLabelText: Driver<String?> =
        Driver.combineLatest(self.billComparison, self.lastYearPreviousBillSelectedSegmentIndex.asDriver()) {
            guard let reference = $0.reference else { return nil }
            if $1 == 0 { // Last Year
                return "\(Calendar.opCo.component(.year, from: reference.endDate))"
            } else { // Previous Bill
                return reference.endDate.shortMonthAndDayString.uppercased()
            }
    }
    
    // MARK: Projection Bar Drivers
    
    private(set) lazy var projectedCost: Driver<Double?> =
        Driver.combineLatest(self.billForecast,
                             self.electricGasSelectedSegmentIndex.asDriver()) { [weak self] billForecast, segmentIndex in
                                // We only combine electricGasSelectedSegmentIndex here to trigger a driver update, then we use self.isGas to determine
                                guard let `self` = self else { return nil }
                                if let gasForecast = billForecast?.gas, self.isGas {
                                    return gasForecast.projectedCost
                                }
                                if let elecForecast = billForecast?.electric, !self.isGas {
                                    return elecForecast.projectedCost
                                }
                                return nil
    }
    
    private(set) lazy var projectedUsage: Driver<Double?> =
        Driver.combineLatest(self.billForecast,
                             self.electricGasSelectedSegmentIndex.asDriver()) { [weak self] billForecast, segmentIndex in
                                // We only combine electricGasSelectedSegmentIndex here to trigger a driver update, then we use self.isGas to determine
                                guard let `self` = self else { return nil }
                                if let gasForecast = billForecast?.gas, self.isGas {
                                    return gasForecast.projectedUsage
                                }
                                if let elecForecast = billForecast?.electric, !self.isGas {
                                    return elecForecast.projectedUsage
                                }
                                return nil
    }
    
    private(set) lazy var shouldShowProjectedBar: Driver<Bool> =
        Driver.combineLatest(self.lastYearPreviousBillSelectedSegmentIndex.asDriver(), self.projectedCost, self.shouldShowProjectionNotAvailableBar) {
            // Projections are only for "Previous Bill" selection
            $0 == 1 && $1 != nil && !$2
    }
    
    private(set) lazy var projectedBarHeightConstraintValue: Driver<CGFloat> =
        Driver.combineLatest(self.billComparison, self.projectedCost) { billComparison, projectedCost in
            guard let projectedCost = projectedCost else { return 0 }
            let reference = billComparison.reference?.charges ?? 0
            let compared = billComparison.compared?.charges ?? 0
            if max(projectedCost, reference, compared) == projectedCost {
                return 134
            } else if max(reference, compared) == reference {
                let fraction = CGFloat(134.0 * (projectedCost / reference))
                return fraction > 3 ? fraction : 3
            } else {
                let fraction = CGFloat(134.0 * (projectedCost / compared))
                return fraction > 3 ? fraction : 3
            }
    }
    
    private(set) lazy var projectedBarDollarLabelText: Driver<String?> =
        Driver.combineLatest(self.projectedCost, self.projectedUsage, self.billComparison) { [weak self] in
            guard let `self` = self, let accountDetail = self.accountDetail else { return nil }
            if accountDetail.isModeledForOpower {
                guard let cost = $0 else { return nil }
                return cost.currencyString!
            } else {
                guard let usage = $1 else { return nil }
                return String(format: "%d %@", Int(usage), $2.meterUnit)
            }
    }
    
    
    private(set) lazy var projectedBarDateLabelText: Driver<String?> =
        Driver.combineLatest(self.billForecast,
                             self.electricGasSelectedSegmentIndex.asDriver()) { [weak self] billForecast, segmentIndex in
                                // We only combine electricGasSelectedSegmentIndex here to trigger a driver update, then we use self.isGas to determine
                                guard let `self` = self else { return nil }
                                if let gasForecast = billForecast?.electric, self.isGas {
                                    if let endDate = gasForecast.billingEndDate {
                                        return endDate.shortMonthAndDayString.uppercased()
                                    }
                                }
                                if let elecForecast = billForecast?.electric, !self.isGas {
                                    if let endDate = elecForecast.billingEndDate {
                                        return endDate.shortMonthAndDayString.uppercased()
                                    }
                                }
                                return nil
    }
    
    // MARK: Projection Not Available Bar Drivers
    private(set) lazy var shouldShowProjectionNotAvailableBar: Driver<Bool> =
        Driver.combineLatest(self.lastYearPreviousBillSelectedSegmentIndex.asDriver(),
                             self.billForecast,
                             self.electricGasSelectedSegmentIndex.asDriver())
        { [weak self] lastYearPrevBillSegmentIndex, billForecast, elecGasSegmentIndex in
            // We only combine electricGasSelectedSegmentIndex here to trigger a driver update, then we use self.isGas to determine
            guard let `self` = self else { return false }
            if lastYearPrevBillSegmentIndex == 0 { return false } // Projections are only for "Previous Bill" selection
            let today = Calendar.opCo.startOfDay(for: Date())
            if let gasForecast = billForecast?.gas, self.isGas {
                if let startDate = gasForecast.billingStartDate {
                    let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
                    return daysSinceBillingStart < 7
                }
            }
            if let elecForecast = billForecast?.electric, !self.isGas {
                if let startDate = elecForecast.billingStartDate {
                    let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
                    return daysSinceBillingStart < 7
                }
            }
            return false
    }
    
    private(set) lazy var projectionNotAvailableDaysRemainingText: Driver<String?> =
        Driver.combineLatest(self.billForecast,
                             self.electricGasSelectedSegmentIndex.asDriver())
        { [weak self] billForecast, segmentIndex in
            // We only combine electricGasSelectedSegmentIndex here to trigger a driver update, then we use self.isGas to determine
            guard let `self` = self else { return nil }
            let today = Calendar.opCo.startOfDay(for: Date())
            
            let localizedString = NSLocalizedString("%@ days", comment: "")
            if let gasForecast = billForecast?.gas, self.isGas {
                if let startDate = gasForecast.billingStartDate {
                    let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
                    let daysRemaining = 7 - daysSinceBillingStart
                    if daysRemaining == 1 {
                        return NSLocalizedString("1 day", comment: "")
                    } else {
                        return String(format: localizedString, "\(daysRemaining)")
                    }
                }
            }
            
            if let elecForecast = billForecast?.electric, !self.isGas {
                if let startDate = elecForecast.billingStartDate {
                    let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
                    let daysRemaining = 7 - daysSinceBillingStart
                    if daysRemaining == 1 {
                        return NSLocalizedString("1 day", comment: "")
                    } else {
                        return String(format: localizedString, "\(daysRemaining)")
                    }
                }
            }
            return nil
    }
    
    // MARK: Bar Graph Button Accessibility Drivers
    
    private(set) lazy var noDataBarA11yLabel: Driver<String?> = self.lastYearPreviousBillSelectedSegmentIndex.asDriver().map {
        if $0 == 0 {
            return NSLocalizedString("Last year. Not enough data available.", comment: "")
        }
        return NSLocalizedString("Previous bill. Not enough data available.", comment: "")
    }
    
    private(set) lazy var previousBarA11yLabel: Driver<String?> = self.billComparison.map {
        guard let compared = $0.compared else { return nil }
        
        let dateString = "\(compared.startDate.shortMonthDayAndYearString) to \(compared.endDate.shortMonthDayAndYearString)"
        
        var tempString = ""
        if let temp = compared.averageTemperature {
            tempString = String(format: NSLocalizedString("Average temperature %d° F", comment: ""), Int(temp.rounded()))
        }
        
        var detailString = ""
        let daysInBillPeriod = abs(compared.startDate.interval(ofComponent: .day, fromDate: compared.endDate))
        let avgUsagePerDay = compared.usage / Double(daysInBillPeriod)
        if compared.charges < 0 {
            let billCreditString = NSLocalizedString("You had a bill credit of %@. You used an average of %@ %@ per day.", comment: "")
            detailString = String(format: billCreditString, abs(compared.charges).currencyString!, String(format: "%.2f", avgUsagePerDay), $0.meterUnit)
        } else {
            let localizedString = NSLocalizedString("Your bill was %@. You used an average of %@ %@ per day.", comment: "")
            detailString = String(format: localizedString, compared.charges.currencyString!, String(format: "%.2f", avgUsagePerDay), $0.meterUnit)
        }
        
        return "\(dateString). \(tempString). \(detailString)"
    }
    
    private(set) lazy var currentBarA11yLabel: Driver<String?> = self.billComparison.map {
        guard let reference = $0.reference else { return nil }
        
        let dateString = "\(reference.startDate.shortMonthDayAndYearString) to \(reference.endDate.shortMonthDayAndYearString)"
        
        var tempString = ""
        if let temp = reference.averageTemperature {
            tempString = String(format: NSLocalizedString("Average temperature %d° F", comment: ""), Int(temp.rounded()))
        }
        
        var detailString = ""
        let daysInBillPeriod = abs(reference.startDate.interval(ofComponent: .day, fromDate: reference.endDate))
        let avgUsagePerDay = reference.usage / Double(daysInBillPeriod)
        if reference.charges < 0 {
            let billCreditString = NSLocalizedString("You had a bill credit of %@. You used an average of %@ %@ per day.", comment: "")
            detailString = String(format: billCreditString, abs(reference.charges).currencyString!, String(format: "%.2f", avgUsagePerDay), $0.meterUnit)
        } else {
            let localizedString = NSLocalizedString("Your bill was %@. You used an average of %@ %@ per day.", comment: "")
            detailString = String(format: localizedString, reference.charges.currencyString!, String(format: "%.2f", avgUsagePerDay), $0.meterUnit)
        }
        
        return "\(dateString). \(tempString). \(detailString)"
    }
    
    private(set) lazy var projectedBarA11yLabel: Driver<String?> =
        Driver.combineLatest(self.billComparison,
                             self.billForecast,
                             self.electricGasSelectedSegmentIndex.asDriver(),
                             self.isFetching.asDriver()) { [weak self] billComparison, billForecast, dontUseThis, isFetching in
                                // We only combine electricGasSelectedSegmentIndex here to trigger a driver update, then we use self.isGas to determine
                                guard let `self` = self else { return nil }
                                if isFetching { return nil }
                                
                                var dateString = ""
                                if let gasForecast = billForecast?.gas, self.isGas {
                                    if let startDate = gasForecast.billingStartDate, let endDate = gasForecast.billingEndDate {
                                        dateString = "\(startDate.shortMonthDayAndYearString) to \(endDate.shortMonthDayAndYearString)"
                                    }
                                }
                                if let elecForecast = billForecast?.electric, !self.isGas {
                                    if let startDate = elecForecast.billingStartDate, let endDate = elecForecast.billingEndDate {
                                        dateString = "\(startDate.shortMonthDayAndYearString) to \(endDate.shortMonthDayAndYearString)"
                                    }
                                }
                                
                                var detailString = ""
                                if let accountDetail = self.accountDetail, accountDetail.isModeledForOpower {
                                    let localizedString = NSLocalizedString("Your bill is projected to be around %@. You've spent about %@ so far this bill period. " +
                                        "This is an estimate and the actual amount may vary based on your energy use, taxes, and fees.", comment: "")
                                    if let gasForecast = billForecast?.gas, self.isGas {
                                        if let projectedCost = gasForecast.projectedCost, let toDateCost = gasForecast.toDateCost {
                                            detailString = String(format: localizedString, projectedCost.currencyString!, toDateCost.currencyString!)
                                        }
                                    }
                                    if let elecForecast = billForecast?.electric, !self.isGas {
                                        if let projectedCost = elecForecast.projectedCost, let toDateCost = elecForecast.toDateCost {
                                            detailString = String(format: localizedString, projectedCost.currencyString!, toDateCost.currencyString!)
                                        }
                                    }
                                } else {
                                    let localizedString = NSLocalizedString("You are projected to use around %d %@. You've used about %d %@ so far this bill period. " +
                                        "This is an estimate and the actual amount may vary based on your energy use, taxes, and fees.", comment: "")
                                    let meterUnit = billComparison.meterUnit
                                    if let gasForecast = billForecast?.gas, self.isGas {
                                        if let projectedUsage = gasForecast.projectedUsage, let toDateUsage = gasForecast.toDateUsage {
                                            detailString = String(format: localizedString, Int(projectedUsage), meterUnit, Int(toDateUsage), meterUnit)
                                        }
                                    }
                                    if let elecForecast = billForecast?.electric, !self.isGas {
                                        if let projectedUsage = elecForecast.projectedUsage, let toDateUsage = elecForecast.toDateUsage {
                                            detailString = String(format: localizedString, Int(projectedUsage), meterUnit, Int(toDateUsage), meterUnit)
                                        }
                                    }
                                }
                                
                                return "\(dateString). \(detailString)"
    }
    
    private(set) lazy var projectionNotAvailableA11yLabel: Driver<String?> =
        Driver.combineLatest(self.billForecast,
                             self.electricGasSelectedSegmentIndex.asDriver())
        { [weak self] billForecast, segmentIndex in
            // We only combine electricGasSelectedSegmentIndex here to trigger a driver update, then we use self.isGas to determine
            guard let `self` = self else { return nil }
            let today = Calendar.opCo.startOfDay(for: Date())
            var daysRemainingString = ""
            let localizedDaysRemaining = NSLocalizedString("%@ days until next forecast.", comment: "")
            if let gasForecast = billForecast?.gas, self.isGas {
                if let startDate = gasForecast.billingStartDate {
                    let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
                    let daysRemaining = 7 - daysSinceBillingStart
                    if daysRemaining == 1 {
                        daysRemainingString = NSLocalizedString("1 day until next forecast.", comment: "")
                    } else {
                        daysRemainingString = String(format: localizedDaysRemaining, "\(daysRemaining)")
                    }
                }
            }
            if let elecForecast = billForecast?.electric, !self.isGas {
                if let startDate = elecForecast.billingStartDate {
                    let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
                    let daysRemaining = 7 - daysSinceBillingStart
                    if daysRemaining == 1 {
                        daysRemainingString = NSLocalizedString("1 day until next forecast.", comment: "")
                    } else {
                        daysRemainingString = String(format: localizedDaysRemaining, "\(daysRemaining)")
                    }
                }
            }
            
            let localizedString = NSLocalizedString("Projection not available. Data becomes available once you are more than 7 days into the billing cycle. %@", comment: "")
            return String(format: localizedString, daysRemainingString)
    }
    
    // MARK: Bar Description Box Drivers
    
    private(set) lazy var barDescriptionDateLabelText: Driver<String?> =
        Driver.combineLatest(self.billComparison,
                             self.lastYearPreviousBillSelectedSegmentIndex.asDriver(),
                             self.barGraphSelectionStates.asDriver(),
                             self.billForecast,
                             self.electricGasSelectedSegmentIndex.asDriver()) { [weak self] billComparison, segmentIndex, selectionStates, billForecast, dontUseThis in
                                // We only combine electricGasSelectedSegmentIndex here to trigger a driver update, then we use self.isGas to determine
                                guard let `self` = self else { return nil }
                                
                                if selectionStates[0].value { // No data
                                    if segmentIndex == 0 {
                                        return NSLocalizedString("Last Year", comment: "")
                                    } else {
                                        return NSLocalizedString("Previous Bill", comment: "")
                                    }
                                } else if selectionStates[1].value { // Previous
                                    if let compared = billComparison.compared {
                                        return "\(compared.startDate.shortMonthDayAndYearString) - \(compared.endDate.shortMonthDayAndYearString)"
                                    }
                                } else if selectionStates[2].value { // Current
                                    if let reference = billComparison.reference {
                                        return "\(reference.startDate.shortMonthDayAndYearString) - \(reference.endDate.shortMonthDayAndYearString)"
                                    }
                                } else if selectionStates[3].value { // Projected
                                    if let gasForecast = billForecast?.electric, self.isGas {
                                        if let startDate = gasForecast.billingStartDate, let endDate = gasForecast.billingEndDate {
                                            return "\(startDate.shortMonthDayAndYearString) - \(endDate.shortMonthDayAndYearString)"
                                        }
                                    }
                                    if let elecForecast = billForecast?.electric, !self.isGas {
                                        if let startDate = elecForecast.billingStartDate, let endDate = elecForecast.billingEndDate {
                                            return "\(startDate.shortMonthDayAndYearString) - \(endDate.shortMonthDayAndYearString)"
                                        }
                                    }
                                } else if selectionStates[4].value { // Projection Not Available
                                    return NSLocalizedString("Projection Not Available", comment: "")
                                }
                                return nil
    }
    
    private(set) lazy var barDescriptionAvgTempLabelText: Driver<String?> =
        Driver.combineLatest(self.billComparison,
                             self.barGraphSelectionStates.asDriver(),
                             self.isFetching.asDriver()) { billComparison, selectionStates, isFetching in
                                if isFetching { return nil }
                                let localizedString = NSLocalizedString("Avg. Temp %d° F", comment: "")
                                if selectionStates[1].value { // Previous
                                    if let compared = billComparison.compared, let temp = compared.averageTemperature {
                                        return String(format: localizedString, Int(temp.rounded()))
                                    }
                                } else if selectionStates[2].value { // Current
                                    if let reference = billComparison.reference, let temp = reference.averageTemperature {
                                        return String(format: localizedString, Int(temp.rounded()))
                                    }
                                }
                                return nil
    }
    
    private(set) lazy var barDescriptionDetailLabelText: Driver<String?> =
        Driver.combineLatest(self.billComparison,
                             self.barGraphSelectionStates.asDriver(),
                             self.billForecast,
                             self.electricGasSelectedSegmentIndex.asDriver()) { [weak self] billComparison, selectionStates, billForecast, dontUseThis in
                                // We only combine electricGasSelectedSegmentIndex here to trigger a driver update, then we use self.isGas to determine
                                guard let `self` = self else { return nil }
                                
                                let localizedPrevCurrString = NSLocalizedString("Your bill was %@. You used an average of %@ %@ per day.", comment: "")
                                if selectionStates[0].value { // No data
                                    return NSLocalizedString("Not enough data available.", comment: "")
                                } else if selectionStates[1].value { // Previous
                                    if let compared = billComparison.compared {
                                        let daysInBillPeriod = abs(compared.startDate.interval(ofComponent: .day, fromDate: compared.endDate))
                                        let avgUsagePerDay = compared.usage / Double(daysInBillPeriod)
                                        if compared.charges < 0 {
                                            let billCreditString = NSLocalizedString("You had a bill credit of %@. You used an average of %@ %@ per day.", comment: "")
                                            return String(format: billCreditString, abs(compared.charges).currencyString!, String(format: "%.2f", avgUsagePerDay), billComparison.meterUnit)
                                        } else {
                                            return String(format: localizedPrevCurrString, compared.charges.currencyString!, String(format: "%.2f", avgUsagePerDay), billComparison.meterUnit)
                                        }
                                    }
                                } else if selectionStates[2].value { // Current
                                    if let reference = billComparison.reference {
                                        let daysInBillPeriod = abs(reference.startDate.interval(ofComponent: .day, fromDate: reference.endDate))
                                        let avgUsagePerDay = reference.usage / Double(daysInBillPeriod)
                                        if reference.charges < 0 {
                                            let billCreditString = NSLocalizedString("You had a bill credit of %@. You used an average of %@ %@ per day.", comment: "")
                                            return String(format: billCreditString, abs(reference.charges).currencyString!, String(format: "%.2f", avgUsagePerDay), billComparison.meterUnit)
                                        } else {
                                            return String(format: localizedPrevCurrString, reference.charges.currencyString!, String(format: "%.2f", avgUsagePerDay), billComparison.meterUnit)
                                        }
                                    }
                                } else if selectionStates[3].value { // Projected
                                    if let accountDetail = self.accountDetail, accountDetail.isModeledForOpower {
                                        let localizedString = NSLocalizedString("Your bill is projected to be around %@. You've spent about %@ so far this bill period. " +
                                            "This is an estimate and the actual amount may vary based on your energy use, taxes, and fees.", comment: "")
                                        if let gasForecast = billForecast?.gas, self.isGas {
                                            if let projectedCost = gasForecast.projectedCost, let toDateCost = gasForecast.toDateCost {
                                                return String(format: localizedString, projectedCost.currencyString!, toDateCost.currencyString!)
                                            }
                                        }
                                        if let elecForecast = billForecast?.electric, !self.isGas {
                                            if let projectedCost = elecForecast.projectedCost, let toDateCost = elecForecast.toDateCost {
                                                return String(format: localizedString, projectedCost.currencyString!, toDateCost.currencyString!)
                                            }
                                        }
                                    } else {
                                        let localizedString = NSLocalizedString("You are projected to use around %d %@. You've used about %d %@ so far this bill period. " +
                                            "This is an estimate and the actual amount may vary based on your energy use, taxes, and fees.", comment: "")
                                        let meterUnit = billComparison.meterUnit
                                        if let gasForecast = billForecast?.gas, self.isGas {
                                            if let projectedUsage = gasForecast.projectedUsage, let toDateUsage = gasForecast.toDateUsage {
                                                return String(format: localizedString, Int(projectedUsage), meterUnit, Int(toDateUsage), meterUnit)
                                            }
                                        }
                                        if let elecForecast = billForecast?.electric, !self.isGas {
                                            if let projectedUsage = elecForecast.projectedUsage, let toDateUsage = elecForecast.toDateUsage {
                                                return String(format: localizedString, Int(projectedUsage), meterUnit, Int(toDateUsage), meterUnit)
                                            }
                                        }
                                    }
                                } else if selectionStates[4].value { // Projection Not Available
                                    return NSLocalizedString("Data becomes available once you are more than 7 days into the billing cycle.", comment: "")
                                }
                                return nil
    }
    
    // MARK: Up/Down Arrow Image Drivers
    
    private(set) lazy var billPeriodArrowImage: Driver<UIImage?> = self.billComparison.map {
        if $0.billPeriodCostDifference >= 1 {
            return #imageLiteral(resourceName: "ic_billanalysis_positive")
        } else if $0.billPeriodCostDifference <= -1 {
            return #imageLiteral(resourceName: "ic_billanalysis_negative")
        } else {
            return #imageLiteral(resourceName: "no_change_icon")
        }
    }
    
    private(set) lazy var weatherArrowImage: Driver<UIImage?> = self.billComparison.map {
        if $0.weatherCostDifference >= 1 {
            return #imageLiteral(resourceName: "ic_billanalysis_positive")
        } else if $0.weatherCostDifference <= -1 {
            return #imageLiteral(resourceName: "ic_billanalysis_negative")
        } else {
            return #imageLiteral(resourceName: "no_change_icon")
        }
    }
    
    private(set) lazy var otherArrowImage: Driver<UIImage?> = self.billComparison.map {
        if $0.otherCostDifference >= 1 {
            return #imageLiteral(resourceName: "ic_billanalysis_positive")
        } else if $0.otherCostDifference <= -1 {
            return #imageLiteral(resourceName: "ic_billanalysis_negative")
        } else {
            return #imageLiteral(resourceName: "no_change_icon")
        }
    }
    
    // MARK: Likely Reasons Button Accessibility Drivers
    
    private(set) lazy var billPeriodA11yLabel: Driver<String?> = self.billComparison.map { billComparison in
        if billComparison.compared == nil {
            return NSLocalizedString("Bill period. No data.", comment: "")
        }
        
        guard let reference = billComparison.reference, let compared = billComparison.compared else { return nil }
        let daysInCurrentBillPeriod = abs(reference.startDate.interval(ofComponent: .day, fromDate: reference.endDate))
        let daysInPreviousBillPeriod = abs(compared.startDate.interval(ofComponent: .day, fromDate: compared.endDate))
        let billPeriodDiff = abs(daysInCurrentBillPeriod - daysInPreviousBillPeriod)
        
        var localizedString: String!
        if billComparison.billPeriodCostDifference >= 1 {
            localizedString = NSLocalizedString("Bill period. Your bill was about %@ more. You used more %@ because this bill period was %d days longer.", comment: "")
        } else if billComparison.billPeriodCostDifference <= -1 {
            localizedString = NSLocalizedString("Bill period. Your bill was about %@ less. You used less %@ because this bill period was %d days shorter.", comment: "")
        } else {
            return NSLocalizedString("Bill period. You spent about the same based on the number of days in your billing period.", comment: "")
        }
        return String(format: localizedString, abs(billComparison.billPeriodCostDifference).currencyString!, self.gasOrElectricityString, billPeriodDiff)
    }
    
    private(set) lazy var weatherA11yLabel: Driver<String?> = self.billComparison
        .map { billComparison in
        if billComparison.compared == nil {
            return NSLocalizedString("Weather. No data.", comment: "")
        }
        
        guard let reference = billComparison.reference, let compared = billComparison.compared else { return nil }
        
        var localizedString: String!
        if billComparison.weatherCostDifference >= 1 {
            localizedString = NSLocalizedString("Weather. Your bill was about %@ more. You used more %@ due to changes in weather.", comment: "")
        } else if billComparison.weatherCostDifference <= -1 {
            localizedString = NSLocalizedString("Weather. Your bill was about %@ less. You used less %@ due to changes in weather.", comment: "")
        } else {
            return NSLocalizedString("Weather. You spent about the same based on weather conditions.", comment: "")
        }
        return String(format: localizedString, abs(billComparison.weatherCostDifference).currencyString!, self.gasOrElectricityString)
    }
    
    private(set) lazy var otherA11yLabel: Driver<String?> = self.billComparison
        .map { billComparison in
        if billComparison.compared == nil {
            return NSLocalizedString("Other. No data.", comment: "")
        }
        
        guard let reference = billComparison.reference, let compared = billComparison.compared else { return nil }
        
        var localizedString: String!
        if billComparison.otherCostDifference >= 1 {
            localizedString = NSLocalizedString("Other. Your bill was about %@ more. Your charges increased based on how you used energy. Your bill may be different for " +
                "a variety of reasons, including:\n• Number of people and amount of time spent in your home\n• New appliances or electronics\n• Differences in rate " +
                "plans or cost of energy", comment: "")
        } else if billComparison.otherCostDifference <= -1 {
            localizedString = NSLocalizedString("Other. Your bill was about %@ less. Your charges decreased based on how you used energy. Your bill may be different for " +
                "a variety of reasons, including:\n• Number of people and amount of time spent in your home\n• New appliances or electronics\n• Differences in rate " +
                "plans or cost of energy", comment: "")
        } else {
            return NSLocalizedString("Other. You spent about the same based on a variety reasons, including:\n• Number of people and amount of time spent in your home\n" +
                "• New appliances or electronics\n• Differences in rate plans or cost of energy", comment: "")
        }
        return String(format: localizedString, abs(billComparison.otherCostDifference).currencyString!, self.gasOrElectricityString)
    }
    
    // MARK: Likely Reasons Drivers
    
    private(set) lazy var likelyReasonsLabelText: Driver<String?> =
        Driver.combineLatest(self.billComparison, self.lastYearPreviousBillSelectedSegmentIndex.asDriver()) { [weak self] currentBillComparison, segmentIndex in
            guard let `self` = self else { return nil }
            guard let reference = currentBillComparison.reference, let compared = currentBillComparison.compared else {
                return String(format: NSLocalizedString("Data not available to explain likely reasons for changes in your %@ charges.", comment: ""), self.gasOrElectricString)
            }
            
            let currentCharges = reference.charges
            let prevCharges = compared.charges
            let difference = abs(currentCharges - prevCharges)
            if difference < 1 { // About the same
                if segmentIndex == 0 { // Last Year
                    let localizedString = NSLocalizedString("Likely reasons your %@ charges are about the same as last year.", comment: "")
                    return String(format: localizedString, self.gasOrElectricString)
                } else { // Previous Bill
                    let localizedString = NSLocalizedString("Likely reasons your %@ charges are about the same as your previous bill.", comment: "")
                    return String(format: localizedString, self.gasOrElectricString)
                }
            } else {
                if currentCharges > prevCharges {
                    if segmentIndex == 0 { // Last Year
                        let localizedString = NSLocalizedString("Likely reasons your %@ charges are about %@ more than last year.", comment: "")
                        return String(format: localizedString, self.gasOrElectricString, difference.currencyString!)
                    } else { // Previous Bill
                        let localizedString = NSLocalizedString("Likely reasons your %@ charges are about %@ more than your previous bill.", comment: "")
                        return String(format: localizedString, self.gasOrElectricString, difference.currencyString!)
                    }
                } else {
                    if segmentIndex == 0 { // Last Year
                        let localizedString = NSLocalizedString("Likely reasons your %@ charges are about %@ less than last year.", comment: "")
                        return String(format: localizedString, self.gasOrElectricString, difference.currencyString!)
                    } else { // Previous Bill
                        let localizedString = NSLocalizedString("Likely reasons your %@ charges are about %@ less than your previous bill.", comment: "")
                        return String(format: localizedString, self.gasOrElectricString, difference.currencyString!)
                    }
                }
            }
    }
    
    private(set) lazy var likelyReasonsDescriptionTitleText: Driver<String?> = self.likelyReasonsSelectionStates.asDriver().map {
        if $0[0].value {
            return NSLocalizedString("Bill Period", comment: "")
        } else if $0[1].value {
            return NSLocalizedString("Weather", comment: "")
        } else if $0[2].value {
            return NSLocalizedString("Other", comment: "")
        }
        return nil
    }
    
    private(set) lazy var likelyReasonsDescriptionDetailText: Driver<String?> =
        Driver.combineLatest(self.billComparison, self.likelyReasonsSelectionStates.asDriver()) { [weak self] billComparison, selectionStates in
            guard let `self` = self else { return nil }
            guard let reference = billComparison.reference, let compared = billComparison.compared else { return nil }
            if selectionStates[0].value { // Bill Period
                let daysInCurrentBillPeriod = abs(reference.startDate.interval(ofComponent: .day, fromDate: reference.endDate))
                let daysInPreviousBillPeriod = abs(compared.startDate.interval(ofComponent: .day, fromDate: compared.endDate))
                let billPeriodDiff = abs(daysInCurrentBillPeriod - daysInPreviousBillPeriod)
                
                var localizedString: String!
                if billComparison.billPeriodCostDifference >= 1 {
                    localizedString = NSLocalizedString("Your bill was about %@ more. You used more %@ because this bill period was %d days longer.", comment: "")
                } else if billComparison.billPeriodCostDifference <= -1 {
                    localizedString = NSLocalizedString("Your bill was about %@ less. You used less %@ because this bill period was %d days shorter.", comment: "")
                } else {
                    return NSLocalizedString("You spent about the same based on the number of days in your billing period.", comment: "")
                }
                return String(format: localizedString, abs(billComparison.billPeriodCostDifference).currencyString!, self.gasOrElectricityString, billPeriodDiff)
            } else if selectionStates[1].value { // Weather
                var localizedString: String!
                if billComparison.weatherCostDifference >= 1 {
                    localizedString = NSLocalizedString("Your bill was about %@ more. You used more %@ due to changes in weather.", comment: "")
                } else if billComparison.weatherCostDifference <= -1 {
                    localizedString = NSLocalizedString("Your bill was about %@ less. You used less %@ due to changes in weather.", comment: "")
                } else {
                    return NSLocalizedString("You spent about the same based on weather conditions.", comment: "")
                }
                return String(format: localizedString, abs(billComparison.weatherCostDifference).currencyString!, self.gasOrElectricityString)
            } else if selectionStates[2].value { // Other
                var localizedString: String!
                if billComparison.otherCostDifference >= 1 {
                    localizedString = NSLocalizedString("Your bill was about %@ more. Your charges increased based on how you used energy. Your bill may be different for " +
                        "a variety of reasons, including:\n• Number of people and amount of time spent in your home\n• New appliances or electronics\n• Differences in rate " +
                        "plans or cost of energy", comment: "")
                } else if billComparison.otherCostDifference <= -1 {
                    localizedString = NSLocalizedString("Your bill was about %@ less. Your charges decreased based on how you used energy. Your bill may be different for " +
                        "a variety of reasons, including:\n• Number of people and amount of time spent in your home\n• New appliances or electronics\n• Differences in rate " +
                        "plans or cost of energy", comment: "")
                } else {
                    return NSLocalizedString("You spent about the same based on a variety reasons, including:\n• Number of people and amount of time spent in your home\n" +
                        "• New appliances or electronics\n• Differences in rate plans or cost of energy", comment: "")
                }
                return String(format: localizedString, abs(billComparison.otherCostDifference).currencyString!, self.gasOrElectricityString)
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
    
    func setLikelyReasonSelected(tag: Int) {
        for i in stride(from: 0, to: likelyReasonsSelectionStates.value.count, by: 1) {
            let boolVar = likelyReasonsSelectionStates.value[i]
            boolVar.value = i == tag
        }
        likelyReasonsSelectionStates.value = likelyReasonsSelectionStates.value // Trigger Variable onNext
    }
    
    // MARK: Random helpers
    
    var shouldShowElectricGasToggle: Bool {
        if Environment.shared.opco != .comEd {
            guard let accountDetail = self.accountDetail else { return false }
            // We can force unwrap here because this view is unreachable if it's null
            return accountDetail.serviceType!.uppercased() == "GAS/ELECTRIC"
        }
        return false
    }
    
    // If a gas only account, return true, if an electric only account, returns false, if both gas/electric, returns selected segemented control
    private var isGas: Bool {
        guard let accountDetail = self.accountDetail else { return false }
        
        var gas = false // Default to electric
        if accountDetail.serviceType!.uppercased() == "GAS" { // If account is gas only
            gas = true
        } else if shouldShowElectricGasToggle { // Use value of segmented control
            gas = electricGasSelectedSegmentIndex.value == 1
        }
        return gas
    }
    
    private var gasOrElectricString: String {
        return isGas ? NSLocalizedString("gas", comment: "") : NSLocalizedString("electric", comment: "")
    }
    
    private var gasOrElectricityString: String {
        return isGas ? NSLocalizedString("gas", comment: "") : NSLocalizedString("electricity", comment: "")
    }
}
