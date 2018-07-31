//
//  UsageViewModel.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/20/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class UsageViewModel {
    
    private let accountService: AccountService
    private let usageService: UsageService
    
    private var billAnalysisCache = BillAnalysisCache()
    
    // MARK: - Init
    
    required init(accountService: AccountService, usageService: UsageService) {
        self.accountService = accountService
        self.usageService = usageService
    }
    
    // MARK: - Data Fetching
    
    private let fetchAllDataTrigger = PublishSubject<Void>()
    
    func fetchAllData() {
        fetchAllDataTrigger.onNext(())
    }
    
    private(set) lazy var accountDetailEvents: Observable<Event<AccountDetail>> = fetchAllDataTrigger
        // Clear cache on refresh or account switch
        .do(onNext: { [weak self] in self?.billAnalysisCache.clear() })
        .toAsyncRequest { [unowned self] in
            self.accountService.fetchAccountDetail(account: AccountsStore.shared.currentAccount)
    }
    
    private lazy var billAnalysisEvents: Observable<Event<(BillComparison, BillForecastResult?)>> = Observable
        .combineLatest(accountDetailEvents.elements().filter { $0.hasUsageData },
                       lastYearPreviousBillSelectedSegmentIndex.asObservable(),
                       electricGasSelectedSegmentIndex.asObservable())
        .toAsyncRequest { [unowned self] (accountDetail, yearsIndex, electricGasIndex) in
            let isGas = self.isGas(accountDetail: accountDetail,
                                   electricGasSelectedIndex: electricGasIndex)
            
            // Pull from cache if possible
            if let cachedData = self.billAnalysisCache[accountDetail.accountNumber,
                                                       accountDetail.premiseNumber!,
                                                       yearsIndex == 0,
                                                       isGas] {
                return Observable.just(cachedData)
            }
            
            let billComparison = self.usageService
                .fetchBillComparison(accountNumber: accountDetail.accountNumber,
                                     premiseNumber: accountDetail.premiseNumber!,
                                     yearAgo: yearsIndex == 0,
                                     gas: isGas)
            
            let billForecast: Observable<BillForecastResult?>
            if accountDetail.isAMIAccount {
                billForecast = self.usageService.fetchBillForecast(accountNumber: accountDetail.accountNumber,
                                                                   premiseNumber: accountDetail.premiseNumber!)
                    .map { $0 }
            } else {
                billForecast = .just(nil)
            }
            
            return Observable.zip(billComparison, billForecast)
                .do(onNext: { [weak self] in
                    self?.billAnalysisCache[accountDetail.accountNumber,
                                            accountDetail.premiseNumber!,
                                            yearsIndex == 0,
                                            isGas] = $0
                })
    }
    
    // MARK: - Convenience Properties
    
    private(set) lazy var accountDetail: Driver<AccountDetail> = accountDetailEvents.elements()
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var billComparison: Driver<BillComparison> = billAnalysisEvents.elements()
        .map { $0.0 }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var billForecast: Driver<BillForecastResult?> = billAnalysisEvents.elements()
        .map { $1 }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var noPreviousData: Driver<Bool> = billComparison.map { $0.compared == nil }

    
    // RX CODE C / P Bill ANalysis
    
    
    
    /*
     * 0 = No Data
     * 1 = Previous
     * 2 = Current
     * 3 = Projected
     * 4 = Projection Not Available
     */
    enum BarGraphSelection: Int {
        case noData, previous, current, projected, projectionNotAvailable
    }
    
    let barGraphSelection = Variable(BarGraphSelection.current)
    
    /*
     * 0 = Bill Period
     * 1 = Weather
     * 2 = Other
     */
    enum LikelyReasonsSelection: Int {
        case billPeriod, weather, other
    }
    
    let likelyReasonsSelection = Variable(LikelyReasonsSelection.billPeriod)
    
    let electricGasSelectedSegmentIndex = Variable(0)
    let lastYearPreviousBillSelectedSegmentIndex = Variable(1)
    
    // MARK: - Main States
    
    private(set) lazy var endRefreshIng: Driver<Void> = Driver.merge(showMainErrorState,
                                                                     showNoNetworkState,
                                                                     showBillComparisonContents,
                                                                     showBillComparisonErrorState,
                                                                     showNoUsageDataState)
    
    private(set) lazy var showMainErrorState: Driver<Void> = accountDetailEvents
        .filter { $0.error != nil }
        .filter { ($0.error as? ServiceError)?.serviceCode != ServiceErrorCode.noNetworkConnection.rawValue }
        .map(to: ())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showNoNetworkState: Driver<Void> = Observable
        .merge(accountDetailEvents.errors(), billAnalysisEvents.errors())
        .filter { ($0 as? ServiceError)?.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue }
        .map(to: ())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showNoUsageDataState: Driver<Void> = accountDetailEvents
        .filter { !($0.element?.hasUsageData ?? true) }
        .map(to: ())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showMainContents: Driver<Void> = accountDetailEvents
        .filter { $0.element?.hasUsageData ?? false }
        .map(to: ())
        .asDriver(onErrorDriveWith: .empty())
    
    
    // MARK: - Bill Analysis States
    
    private(set) lazy var showBillComparisonContents: Driver<Void> = billAnalysisEvents
        .filter { $0.element?.0.reference != nil }
        .map(to: ())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showBillComparisonErrorState: Driver<Void> = billAnalysisEvents
        .filter { $0.error != nil || $0.element?.0.reference == nil }
        .map(to: ())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showElectricGasSegmentedControl: Driver<Bool> = accountDetailEvents.elements()
        .map { accountDetail in
            switch Environment.shared.opco {
            case .comEd:
                return false
            case .bge, .peco:
                return accountDetail.serviceType?.uppercased() == "GAS/ELECTRIC"
            }
        }
        .asDriver(onErrorDriveWith: .empty())

    
    // MARK: - Bill Analysis Content
    
    private(set) lazy var compareBillTitle: Driver<String> = lastYearPreviousBillSelectedSegmentIndex.asDriver()
        .map {
            if $0 == 0 {
                return NSLocalizedString("Compared to Last Year", comment: "")
            } else {
                return NSLocalizedString("Compared to Previous Bill", comment: "")
            }
    }
    
    // MARK: No Data Bar Drivers
    
    private(set) lazy var noDataBarDateLabelText: Driver<String?> =
        Driver.combineLatest(billComparison, lastYearPreviousBillSelectedSegmentIndex.asDriver()) {
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
        Driver.combineLatest(billComparison, projectedCost) { billComparison, projectedCost in
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
    
    private(set) lazy var previousBarDollarLabelText: Driver<String?> = billComparison
        .map { $0.compared?.charges.currencyString }
    
    private(set) lazy var previousBarDateLabelText: Driver<String?> =
        Driver.combineLatest(billComparison, lastYearPreviousBillSelectedSegmentIndex.asDriver()) {
            guard let compared = $0.compared else { return nil }
            if $1 == 0 { // Last Year
                return "\(Calendar.opCo.component(.year, from: compared.endDate))"
            } else { // Previous Bill
                return compared.endDate.shortMonthAndDayString.uppercased()
            }
    }
    
    // MARK: Current Bar Drivers
    
    private(set) lazy var currentBarHeightConstraintValue: Driver<CGFloat> =
        Driver.combineLatest(billComparison, projectedCost) { billComparison, projectedCost in
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
    
    private(set) lazy var currentBarDollarLabelText: Driver<String?> = billComparison.map {
        guard let reference = $0.reference else { return nil }
        return reference.charges.currencyString
    }
    
    private(set) lazy var currentBarDateLabelText: Driver<String?> =
        Driver.combineLatest(billComparison, lastYearPreviousBillSelectedSegmentIndex.asDriver()) {
            guard let reference = $0.reference else { return nil }
            if $1 == 0 { // Last Year
                return "\(Calendar.opCo.component(.year, from: reference.endDate))"
            } else { // Previous Bill
                return reference.endDate.shortMonthAndDayString.uppercased()
            }
    }
    
    // MARK: Projection Bar Drivers
    
    private(set) lazy var projectedCost: Driver<Double?> =
        Driver.combineLatest(accountDetail,
                             billForecast,
                             electricGasSelectedSegmentIndex.asDriver())
        { [weak self] accountDetail, billForecast, electricGasSelectedIndex in
            guard let this = self else { return nil }
            if this.isGas(accountDetail: accountDetail, electricGasSelectedIndex: electricGasSelectedIndex) {
                return billForecast?.gas.projectedCost
            } else {
                return billForecast?.electric.projectedCost
            }
    }
    
    private(set) lazy var projectedUsage: Driver<Double?> =
        Driver.combineLatest(accountDetail,
                             billForecast,
                             electricGasSelectedSegmentIndex.asDriver())
        { [weak self] accountDetail, billForecast, electricGasSelectedIndex in
            guard let this = self else { return nil }
            if this.isGas(accountDetail: accountDetail, electricGasSelectedIndex: electricGasSelectedIndex) {
                return billForecast?.gas.projectedUsage
            } else {
                return billForecast?.electric.projectedUsage
            }
    }
    
    private(set) lazy var showProjectedBar: Driver<Bool> =
        Driver.combineLatest(lastYearPreviousBillSelectedSegmentIndex.asDriver(), projectedCost, showProjectionNotAvailableBar) {
            // Projections are only for "Previous Bill" selection
            $0 == 1 && $1 != nil && !$2
    }
    
    private(set) lazy var projectedBarHeightConstraintValue: Driver<CGFloat> =
        Driver.combineLatest(billComparison, projectedCost) { billComparison, projectedCost in
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
        Driver.combineLatest(accountDetail,
                             projectedCost,
                             projectedUsage,
                             billComparison)
        { [weak self] accountDetail, cost, usage, billComparison in
            if accountDetail.isModeledForOpower {
                return cost?.currencyString
            } else {
                guard let usage = usage else { return nil }
                return String(format: "%d %@", Int(usage), billComparison.meterUnit)
            }
    }
    
    
    private(set) lazy var projectedBarDateLabelText: Driver<String?> =
        Driver.combineLatest(accountDetail,
                             billForecast,
                             electricGasSelectedSegmentIndex.asDriver())
        { [weak self] accountDetail, billForecast, electricGasSelectedIndex in
            guard let this = self else { return nil }
            let isGas = this.isGas(accountDetail: accountDetail,
                                   electricGasSelectedIndex: electricGasSelectedIndex)
            if isGas {
                if let endDate = billForecast?.gas.billingEndDate {
                    return endDate.shortMonthAndDayString.uppercased()
                }
            } else if let endDate = billForecast?.electric.billingEndDate {
                return endDate.shortMonthAndDayString.uppercased()
            }
            return nil
    }
    
    // MARK: Projection Not Available Bar Drivers
    private(set) lazy var showProjectionNotAvailableBar: Driver<Bool> =
        Driver.combineLatest(accountDetail,
                             lastYearPreviousBillSelectedSegmentIndex.asDriver(),
                             billForecast,
                             electricGasSelectedSegmentIndex.asDriver())
        { [weak self] accountDetail, lastYearPrevBillSegmentIndex, billForecast, electricGasSelectedIndex in
            guard let this = self else { return false }
            let isGas = this.isGas(accountDetail: accountDetail,
                                   electricGasSelectedIndex: electricGasSelectedIndex)
            if lastYearPrevBillSegmentIndex == 0 { return false } // Projections are only for "Previous Bill" selection
            let today = Calendar.opCo.startOfDay(for: Date())
            if let gasForecast = billForecast?.gas, isGas {
                if let startDate = gasForecast.billingStartDate {
                    let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
                    return daysSinceBillingStart < 7
                }
            }
            if let elecForecast = billForecast?.electric, !isGas {
                if let startDate = elecForecast.billingStartDate {
                    let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
                    return daysSinceBillingStart < 7
                }
            }
            return false
    }
    
    private(set) lazy var projectionNotAvailableDaysRemainingText: Driver<String?> =
        Driver.combineLatest(accountDetail,
                             billForecast,
                             electricGasSelectedSegmentIndex.asDriver())
        { [weak self] accountDetail, billForecast, electricGasSelectedIndex in
            guard let this = self else { return nil }
            let isGas = this.isGas(accountDetail: accountDetail,
                                   electricGasSelectedIndex: electricGasSelectedIndex)
            let today = Calendar.opCo.startOfDay(for: Date())
            
            let localizedString = NSLocalizedString("%@ days", comment: "")
            if let gasForecast = billForecast?.gas, isGas {
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
            
            if let elecForecast = billForecast?.electric, !isGas {
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
    
    private(set) lazy var noDataBarA11yLabel: Driver<String?> = lastYearPreviousBillSelectedSegmentIndex.asDriver().map {
        if $0 == 0 {
            return NSLocalizedString("Last year. Not enough data available.", comment: "")
        }
        return NSLocalizedString("Previous bill. Not enough data available.", comment: "")
    }
    
    private(set) lazy var previousBarA11yLabel: Driver<String?> = billComparison.map {
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
    
    private(set) lazy var currentBarA11yLabel: Driver<String?> = billComparison.map {
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
        Driver.combineLatest(accountDetail,
                             billComparison,
                             billForecast,
                             electricGasSelectedSegmentIndex.asDriver())
        { [weak self] accountDetail, billComparison, billForecast, electricGasSelectedIndex in
            guard let this = self else { return nil }
            guard let billForecast = billForecast else { return nil }
            let isGas = this.isGas(accountDetail: accountDetail, electricGasSelectedIndex: electricGasSelectedIndex)
            
            var dateString = ""
            if isGas {
                if let startDate = billForecast.gas.billingStartDate, let endDate = billForecast.gas.billingEndDate {
                    dateString = "\(startDate.shortMonthDayAndYearString) to \(endDate.shortMonthDayAndYearString)"
                }
            } else if let startDate = billForecast.electric.billingStartDate,
                let endDate = billForecast.electric.billingEndDate {
                dateString = "\(startDate.shortMonthDayAndYearString) to \(endDate.shortMonthDayAndYearString)"
            }
            
            
            var detailString = ""
            if accountDetail.isModeledForOpower {
                let localizedString = NSLocalizedString("Your bill is projected to be around %@. You've spent about %@ so far this bill period. " +
                    "This is an estimate and the actual amount may vary based on your energy use, taxes, and fees.", comment: "")
                if isGas {
                    if let projectedCost = billForecast.gas.projectedCost,
                        let toDateCost = billForecast.gas.toDateCost {
                        detailString = String(format: localizedString, projectedCost.currencyString!, toDateCost.currencyString!)
                    }
                } else if let projectedCost = billForecast.electric.projectedCost,
                    let toDateCost = billForecast.electric.toDateCost {
                    detailString = String(format: localizedString, projectedCost.currencyString!, toDateCost.currencyString!)
                }
            } else {
                let localizedString = NSLocalizedString("You are projected to use around %d %@. You've used about %d %@ so far this bill period. " +
                    "This is an estimate and the actual amount may vary based on your energy use, taxes, and fees.", comment: "")
                let meterUnit = billComparison.meterUnit
                if isGas {
                    if let projectedUsage = billForecast.gas.projectedUsage,
                        let toDateUsage = billForecast.gas.toDateUsage {
                        detailString = String(format: localizedString, Int(projectedUsage), meterUnit, Int(toDateUsage), meterUnit)
                    }
                } else if let projectedUsage = billForecast.electric.projectedUsage,
                    let toDateUsage = billForecast.electric.toDateUsage {
                    detailString = String(format: localizedString, Int(projectedUsage), meterUnit, Int(toDateUsage), meterUnit)
                }
            }
            
            return "\(dateString). \(detailString)"
    }
    
    private(set) lazy var projectionNotAvailableA11yLabel: Driver<String?> =
        Driver.combineLatest(accountDetail,
                             billForecast,
                             electricGasSelectedSegmentIndex.asDriver())
        { [weak self] accountDetail, billForecast, electricGasSelectedIndex in
            guard let this = self else { return nil }
            let isGas = this.isGas(accountDetail: accountDetail, electricGasSelectedIndex: electricGasSelectedIndex)
            
            let today = Calendar.opCo.startOfDay(for: Date())
            var daysRemainingString = ""
            let localizedDaysRemaining = NSLocalizedString("%@ days until next forecast.", comment: "")
            if let gasForecast = billForecast?.gas, isGas {
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
            if let elecForecast = billForecast?.electric, !isGas {
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
        Driver.combineLatest(accountDetail,
                             billComparison,
                             lastYearPreviousBillSelectedSegmentIndex.asDriver(),
                             barGraphSelection.asDriver(),
                             billForecast,
                             electricGasSelectedSegmentIndex.asDriver())
        { [weak self] accountDetail, billComparison, segmentIndex, barGraphSelection, billForecast, electricGasSelectedIndex in
            guard let this = self else { return nil }
            let isGas = this.isGas(accountDetail: accountDetail, electricGasSelectedIndex: electricGasSelectedIndex)
            
            switch barGraphSelection {
            case .noData:
                if segmentIndex == 0 {
                    return NSLocalizedString("Last Year", comment: "")
                } else {
                    return NSLocalizedString("Previous Bill", comment: "")
                }
            case .previous:
                if let compared = billComparison.compared {
                    return "\(compared.startDate.shortMonthDayAndYearString) - \(compared.endDate.shortMonthDayAndYearString)"
                }
            case .current:
                if let reference = billComparison.reference {
                    return "\(reference.startDate.shortMonthDayAndYearString) - \(reference.endDate.shortMonthDayAndYearString)"
                }
            case .projected:
                if let gasForecast = billForecast?.electric, isGas {
                    if let startDate = gasForecast.billingStartDate, let endDate = gasForecast.billingEndDate {
                        return "\(startDate.shortMonthDayAndYearString) - \(endDate.shortMonthDayAndYearString)"
                    }
                }
                if let elecForecast = billForecast?.electric, !isGas {
                    if let startDate = elecForecast.billingStartDate, let endDate = elecForecast.billingEndDate {
                        return "\(startDate.shortMonthDayAndYearString) - \(endDate.shortMonthDayAndYearString)"
                    }
                }
            case .projectionNotAvailable:
                return NSLocalizedString("Projection Not Available", comment: "")
            }
            
            return nil
    }
    
    private(set) lazy var barDescriptionAvgTempLabelText: Driver<String?> =
        Driver.combineLatest(billComparison,
                             barGraphSelection.asDriver())
        { billComparison, barGraphSelection in
            let localizedString = NSLocalizedString("Avg. Temp %d° F", comment: "")
            switch barGraphSelection {
            case .previous:
                if let compared = billComparison.compared, let temp = compared.averageTemperature {
                    return String(format: localizedString, Int(temp.rounded()))
                }
            case .current:
                if let reference = billComparison.reference, let temp = reference.averageTemperature {
                    return String(format: localizedString, Int(temp.rounded()))
                }
            case .noData, .projected, .projectionNotAvailable:
                return nil
            }
            
            return nil
    }
    
    private(set) lazy var barDescriptionDetailLabelText: Driver<String?> =
        Driver.combineLatest(accountDetail,
                             billComparison,
                             barGraphSelection.asDriver(),
                             billForecast,
                             electricGasSelectedSegmentIndex.asDriver())
        { [weak self] accountDetail, billComparison, barGraphSelection, billForecast, electricGasSelectedIndex in
            guard let this = self else { return nil }
            let isGas = this.isGas(accountDetail: accountDetail, electricGasSelectedIndex: electricGasSelectedIndex)
            
            let localizedPrevCurrString = NSLocalizedString("Your bill was %@. You used an average of %@ %@ per day.", comment: "")
            switch barGraphSelection {
            case .noData:
                return NSLocalizedString("Not enough data available.", comment: "")
            case .previous:
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
            case .current:
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
            case .projected:
                if accountDetail.isModeledForOpower {
                    let localizedString = NSLocalizedString("Your bill is projected to be around %@. You've spent about %@ so far this bill period. " +
                        "This is an estimate and the actual amount may vary based on your energy use, taxes, and fees.", comment: "")
                    if let gasForecast = billForecast?.gas, isGas {
                        if let projectedCost = gasForecast.projectedCost, let toDateCost = gasForecast.toDateCost {
                            return String(format: localizedString, projectedCost.currencyString!, toDateCost.currencyString!)
                        }
                    }
                    if let elecForecast = billForecast?.electric, isGas {
                        if let projectedCost = elecForecast.projectedCost, let toDateCost = elecForecast.toDateCost {
                            return String(format: localizedString, projectedCost.currencyString!, toDateCost.currencyString!)
                        }
                    }
                } else {
                    let localizedString = NSLocalizedString("You are projected to use around %d %@. You've used about %d %@ so far this bill period. " +
                        "This is an estimate and the actual amount may vary based on your energy use, taxes, and fees.", comment: "")
                    let meterUnit = billComparison.meterUnit
                    if let gasForecast = billForecast?.gas, isGas {
                        if let projectedUsage = gasForecast.projectedUsage, let toDateUsage = gasForecast.toDateUsage {
                            return String(format: localizedString, Int(projectedUsage), meterUnit, Int(toDateUsage), meterUnit)
                        }
                    }
                    if let elecForecast = billForecast?.electric, !isGas {
                        if let projectedUsage = elecForecast.projectedUsage, let toDateUsage = elecForecast.toDateUsage {
                            return String(format: localizedString, Int(projectedUsage), meterUnit, Int(toDateUsage), meterUnit)
                        }
                    }
                }
            case .projectionNotAvailable:
                return NSLocalizedString("Data becomes available once you are more than 7 days into the billing cycle.", comment: "")
            }
            
            return nil
    }
    
    // MARK: Up/Down Arrow Image Drivers
    
    private(set) lazy var billPeriodArrowImage: Driver<UIImage?> = billComparison.map {
        if $0.billPeriodCostDifference >= 1 {
            return #imageLiteral(resourceName: "ic_billanalysis_positive")
        } else if $0.billPeriodCostDifference <= -1 {
            return #imageLiteral(resourceName: "ic_billanalysis_negative")
        } else {
            return #imageLiteral(resourceName: "no_change_icon")
        }
    }
    
    private(set) lazy var weatherArrowImage: Driver<UIImage?> = billComparison.map {
        if $0.weatherCostDifference >= 1 {
            return #imageLiteral(resourceName: "ic_billanalysis_positive")
        } else if $0.weatherCostDifference <= -1 {
            return #imageLiteral(resourceName: "ic_billanalysis_negative")
        } else {
            return #imageLiteral(resourceName: "no_change_icon")
        }
    }
    
    private(set) lazy var otherArrowImage: Driver<UIImage?> = billComparison.map {
        if $0.otherCostDifference >= 1 {
            return #imageLiteral(resourceName: "ic_billanalysis_positive")
        } else if $0.otherCostDifference <= -1 {
            return #imageLiteral(resourceName: "ic_billanalysis_negative")
        } else {
            return #imageLiteral(resourceName: "no_change_icon")
        }
    }
    
    // MARK: Likely Reasons Button Accessibility Drivers
    
    private(set) lazy var billPeriodA11yLabel: Driver<String?> = Driver.combineLatest(accountDetail,
                                                                                      billComparison,
                                                                                      electricGasSelectedSegmentIndex.asDriver())
    { [weak self] accountDetail, billComparison, electricGasSelectedIndex in
        if billComparison.compared == nil {
            return NSLocalizedString("Bill period. No data.", comment: "")
        }
        
        guard let this = self else { return nil }
        let isGas = this.isGas(accountDetail: accountDetail,
                               electricGasSelectedIndex: electricGasSelectedIndex)
        let gasOrElectricityString = isGas ? NSLocalizedString("gas", comment: "") : NSLocalizedString("electricity", comment: "")
        
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
        return String(format: localizedString, abs(billComparison.billPeriodCostDifference).currencyString!, gasOrElectricityString, billPeriodDiff)
    }
    
    private(set) lazy var weatherA11yLabel: Driver<String?> = Driver.combineLatest(accountDetail,
                                                                                   billComparison,
                                                                                   electricGasSelectedSegmentIndex.asDriver())
    { [weak self] accountDetail, billComparison, electricGasSelectedIndex in
        if billComparison.compared == nil {
            return NSLocalizedString("Weather. No data.", comment: "")
        }
        
        guard let this = self else { return nil }
        let isGas = this.isGas(accountDetail: accountDetail,
                               electricGasSelectedIndex: electricGasSelectedIndex)
        let gasOrElectricityString = isGas ? NSLocalizedString("gas", comment: "") : NSLocalizedString("electricity", comment: "")
        
        guard let reference = billComparison.reference, let compared = billComparison.compared else { return nil }
        
        var localizedString: String!
        if billComparison.weatherCostDifference >= 1 {
            localizedString = NSLocalizedString("Weather. Your bill was about %@ more. You used more %@ due to changes in weather.", comment: "")
        } else if billComparison.weatherCostDifference <= -1 {
            localizedString = NSLocalizedString("Weather. Your bill was about %@ less. You used less %@ due to changes in weather.", comment: "")
        } else {
            return NSLocalizedString("Weather. You spent about the same based on weather conditions.", comment: "")
        }
        return String(format: localizedString, abs(billComparison.weatherCostDifference).currencyString!, gasOrElectricityString)
    }
    
    private(set) lazy var otherA11yLabel: Driver<String?> = Driver.combineLatest(accountDetail,
                                                                                 billComparison,
                                                                                 electricGasSelectedSegmentIndex.asDriver())
    { [weak self] accountDetail, billComparison, electricGasSelectedIndex in
        if billComparison.compared == nil {
            return NSLocalizedString("Other. No data.", comment: "")
        }
        
        guard let this = self else { return nil }
        let isGas = this.isGas(accountDetail: accountDetail,
                               electricGasSelectedIndex: electricGasSelectedIndex)
        let gasOrElectricityString = isGas ? NSLocalizedString("gas", comment: "") : NSLocalizedString("electricity", comment: "")
        
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
        return String(format: localizedString, abs(billComparison.otherCostDifference).currencyString!, gasOrElectricityString)
    }
    
    // MARK: Likely Reasons Drivers
    
    private(set) lazy var likelyReasonsLabelText: Driver<String?> =
        Driver.combineLatest(accountDetail,
                             billComparison,
                             lastYearPreviousBillSelectedSegmentIndex.asDriver())
        { [weak self] accountDetail, billComparison, electricGasSelectedIndex in
            guard let this = self else { return nil }
            let isGas = this.isGas(accountDetail: accountDetail,
                                   electricGasSelectedIndex: electricGasSelectedIndex)
            let gasOrElectricString = isGas ? NSLocalizedString("gas", comment: "") :
                NSLocalizedString("electric", comment: "")
            
            guard let reference = billComparison.reference, let compared = billComparison.compared else {
                return String(format: NSLocalizedString("Data not available to explain likely reasons for changes in your %@ charges.", comment: ""), gasOrElectricString)
            }
            
            let currentCharges = reference.charges
            let prevCharges = compared.charges
            let difference = abs(currentCharges - prevCharges)
            if difference < 1 { // About the same
                if electricGasSelectedIndex == 0 { // Last Year
                    let localizedString = NSLocalizedString("Likely reasons your %@ charges are about the same as last year.", comment: "")
                    return String(format: localizedString, gasOrElectricString)
                } else { // Previous Bill
                    let localizedString = NSLocalizedString("Likely reasons your %@ charges are about the same as your previous bill.", comment: "")
                    return String(format: localizedString, gasOrElectricString)
                }
            } else {
                if currentCharges > prevCharges {
                    if electricGasSelectedIndex == 0 { // Last Year
                        let localizedString = NSLocalizedString("Likely reasons your %@ charges are about %@ more than last year.", comment: "")
                        return String(format: localizedString, gasOrElectricString, difference.currencyString!)
                    } else { // Previous Bill
                        let localizedString = NSLocalizedString("Likely reasons your %@ charges are about %@ more than your previous bill.", comment: "")
                        return String(format: localizedString, gasOrElectricString, difference.currencyString!)
                    }
                } else {
                    if electricGasSelectedIndex == 0 { // Last Year
                        let localizedString = NSLocalizedString("Likely reasons your %@ charges are about %@ less than last year.", comment: "")
                        return String(format: localizedString, gasOrElectricString, difference.currencyString!)
                    } else { // Previous Bill
                        let localizedString = NSLocalizedString("Likely reasons your %@ charges are about %@ less than your previous bill.", comment: "")
                        return String(format: localizedString, gasOrElectricString, difference.currencyString!)
                    }
                }
            }
    }
    
    private(set) lazy var likelyReasonsDescriptionTitleText: Driver<String> = likelyReasonsSelection.asDriver().map {
        switch $0 {
        case .billPeriod:
            return NSLocalizedString("Bill Period", comment: "")
        case .weather:
            return NSLocalizedString("Weather", comment: "")
        case .other:
            return NSLocalizedString("Other", comment: "")
        }
    }
    
    private(set) lazy var likelyReasonsDescriptionDetailText: Driver<String?> =
        Driver.combineLatest(accountDetail,
                             billComparison,
                             likelyReasonsSelection.asDriver(),
                             electricGasSelectedSegmentIndex.asDriver())
        { [weak self] accountDetail, billComparison, likelyReasonsSelection, electricGasSelectedIndex in
            guard let this = self else { return nil }
            let isGas = this.isGas(accountDetail: accountDetail,
                                   electricGasSelectedIndex: electricGasSelectedIndex)
            let gasOrElectricityString = isGas ? NSLocalizedString("gas", comment: "") : NSLocalizedString("electricity", comment: "")
            guard let reference = billComparison.reference, let compared = billComparison.compared else { return nil }
            
            switch likelyReasonsSelection {
            case .billPeriod:
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
                return String(format: localizedString, abs(billComparison.billPeriodCostDifference).currencyString!, gasOrElectricityString, billPeriodDiff)
            case .weather:
                var localizedString: String!
                if billComparison.weatherCostDifference >= 1 {
                    localizedString = NSLocalizedString("Your bill was about %@ more. You used more %@ due to changes in weather.", comment: "")
                } else if billComparison.weatherCostDifference <= -1 {
                    localizedString = NSLocalizedString("Your bill was about %@ less. You used less %@ due to changes in weather.", comment: "")
                } else {
                    return NSLocalizedString("You spent about the same based on weather conditions.", comment: "")
                }
                return String(format: localizedString, abs(billComparison.weatherCostDifference).currencyString!, gasOrElectricityString)
            case .other:
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
                return String(format: localizedString, abs(billComparison.otherCostDifference).currencyString!, gasOrElectricityString)
            }
    }
    
    // MARK: Selection States
    
    func setBarSelected(tag: Int) {
        barGraphSelection.value = BarGraphSelection(rawValue: tag) ?? .current
    }
    
    func setLikelyReasonSelected(tag: Int) {
        likelyReasonsSelection.value = LikelyReasonsSelection(rawValue: tag) ?? .billPeriod
    }
    
    // MARK: - Text Styling
    
    private(set) lazy var noDataLabelFont: Driver<UIFont> = barGraphSelection.asDriver()
        .map { $0 == .noData }
        .distinctUntilChanged()
        .map { $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline) }
    
    private(set) lazy var previousLabelFont: Driver<UIFont> = barGraphSelection.asDriver()
        .map { $0 == .previous }
        .distinctUntilChanged()
        .map { $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline) }
    
    private(set) lazy var previousDollarLabelTextColor: Driver<UIColor> = billComparison.map {
        guard let compared = $0.compared else { return .deepGray }
        return compared.charges < 0 ? .successGreenText : .deepGray
    }
    
    private(set) lazy var currentLabelFont: Driver<UIFont> = barGraphSelection.asDriver()
        .map { $0 == .current }
        .distinctUntilChanged()
        .map { $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline) }
    
    private(set) lazy var currentDollarLabelTextColor: Driver<UIColor> = billComparison.map {
        guard let reference = $0.reference else { return .deepGray }
        return reference.charges < 0 ? .successGreenText : .deepGray
    }
    
    private(set) lazy var projectedLabelFont: Driver<UIFont> = barGraphSelection.asDriver()
        .map { $0 == .projected }
        .distinctUntilChanged()
        .map { $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline) }
    
    private(set) lazy var projectionNotAvailableLabelFont: Driver<UIFont> = barGraphSelection.asDriver()
        .map { $0 == .projectionNotAvailable }
        .distinctUntilChanged()
        .map { $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline) }
    
    // MARK: Likely Reasons Border Color Drivers
    private(set) lazy var billPeriodBorderColor: Driver<CGColor> =
        Driver.combineLatest(likelyReasonsSelection.asDriver(), noPreviousData) {
            $0 == .billPeriod && !$1 ? UIColor.primaryColor.cgColor : UIColor.clear.cgColor
    }
    
    private(set) lazy var weatherBorderColor: Driver<CGColor> =
        Driver.combineLatest(likelyReasonsSelection.asDriver(), noPreviousData) {
            $0 == .weather && !$1 ? UIColor.primaryColor.cgColor : UIColor.clear.cgColor
    }
    
    private(set) lazy var otherBorderColor: Driver<CGColor> =
        Driver.combineLatest(likelyReasonsSelection.asDriver(), noPreviousData) {
            $0 == .other && !$1 ? UIColor.primaryColor.cgColor : UIColor.clear.cgColor
    }
    
    // MARK: - Usage Tools
    
    private(set) lazy var usageTools: Driver<[UsageTool]> = accountDetail
        .filter { $0.hasUsageData }
        .map { accountDetail in
            var usageTools: [UsageTool] = [.usageData, .energyTips, .homeProfile]
            
            switch Environment.shared.opco {
            case .bge:
                if accountDetail.peakRewards == "ACTIVE" {
                    usageTools.insert(.peakRewards, at: 1)
                }
                
                if accountDetail.isSERAccount {
                    usageTools.append(.smartEnergyRewards)
                }
            case .comEd:
                usageTools.insert(.hourlyPricing, at: 1)
                
                if accountDetail.isPTSAccount {
                    usageTools.append(.peakTimeSavings)
                }
            case .peco:
                break
            }
            
            return usageTools
        }
        .asDriver(onErrorDriveWith: .empty())
    
    // MARK: - Helpers
    
    // If a gas only account, return true, if an electric only account, returns false, if both gas/electric, returns selected segemented control
    private func isGas(accountDetail: AccountDetail, electricGasSelectedIndex: Int) -> Bool {
        if accountDetail.serviceType?.uppercased() == "GAS" { // If account is gas only
            return true
        } else if Environment.shared.opco != .comEd && accountDetail.serviceType?.uppercased() == "GAS/ELECTRIC" {
            return electricGasSelectedIndex == 1
        }
        // Default to electric
        return false
    }
    
    private struct BillAnalysisCache {
        private var cache = [String: [String: [Bool: [Bool: (BillComparison, BillForecastResult?)]]]]()
        
        mutating func clear() {
            cache.removeAll()
        }
        
        subscript(accountNumber: String, premiseNumber: String, yearAgo: Bool, gas: Bool) -> (BillComparison, BillForecastResult?)? {
            get {
                return cache[accountNumber]?[premiseNumber]?[yearAgo]?[gas]
            } set {
                if cache[accountNumber] == nil {
                    cache[accountNumber] = [String: [Bool: [Bool: (BillComparison, BillForecastResult?)]]]()
                }
                
                if cache[accountNumber]?[premiseNumber] == nil {
                    cache[accountNumber]?[premiseNumber] = [Bool: [Bool: (BillComparison, BillForecastResult?)]]()
                }
                
                if cache[accountNumber]?[premiseNumber]?[yearAgo] == nil {
                    cache[accountNumber]?[premiseNumber]?[yearAgo] = [Bool: (BillComparison, BillForecastResult?)]()
                }
                
                cache[accountNumber]?[premiseNumber]?[yearAgo]?[gas] = newValue
            }
        }
    }
}

fileprivate extension AccountDetail {
    var hasUsageData: Bool {
        switch serviceType {
        case "GAS", "ELECTRIC", "GAS/ELECTRIC":
            return premiseNumber != nil && isResidential && !isBGEControlGroup && !isFinaled
        default:
            return false
        }
    }
}

