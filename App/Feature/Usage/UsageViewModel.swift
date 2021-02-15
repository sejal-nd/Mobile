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
import RxSwiftExt

fileprivate let firstfuelSessionTimeout = 900 // 15 minutes

class UsageViewModel {
    
    
    // MARK: - Init
    
    required init() {
    }
    
    // MARK: - Data Fetching
    
    private let fetchAllDataTrigger = PublishSubject<Void>()
    
    func fetchAllData() {
        fetchAllDataTrigger.onNext(())
    }
    
    private lazy var maintenanceModeEvents: Observable<Event<MaintenanceMode>> = fetchAllDataTrigger
        // Clear cache on refresh or account switch
        .do(onNext: { [weak self] in UsageService.clearCache() })
        .toAsyncRequest {
            AnonymousService.rx.getMaintenanceMode(shouldPostNotification: true)
        }
    
    private(set) lazy var accountDetailEvents: Observable<Event<AccountDetail>> = maintenanceModeEvents
        .filter {
            !($0.element?.all ?? false) &&
            !($0.element?.usage ?? false)
        }
        .toAsyncRequest { [weak self] _ in
            AccountService.rx.fetchAccountDetails()
        }
    
    private lazy var commercialDataEvents: Observable<Event<SSODataResponse>> = accountDetailEvents
        .elements()
        .toAsyncRequest { [weak self] accountDetail -> Observable<SSODataResponse> in
            // Start the timer. The FirstFuel session is only valid for [firstfuelSessionTimeout] seconds -
            // so we automatically reload after that amount of time.
            // Replace timer with .empty() for residential accounts
            guard !accountDetail.isResidential, let premiseNumber = accountDetail.premiseNumber else { return .empty() }
            return Observable<Int>
                .timer(.seconds(0), period: .seconds(firstfuelSessionTimeout), scheduler: MainScheduler.instance)
                .flatMapLatest { [weak self] _ -> Observable<SSODataResponse> in
                    guard let self = self else { return .empty() }
                    return AccountService.rx.fetchFirstFuelSSOData(accountNumber: accountDetail.accountNumber,
                                               premiseNumber: premiseNumber)
                }
        }
        .share(replay: 1)
    
    private let commercialErrorTrigger = PublishSubject<Error>()
    
    private(set) lazy var commercialViewModel = CommercialUsageViewModel(accountDetail: accountDetailEvents.elements(),
                                                                         ssoData: commercialDataEvents.elements(),
                                                                         errorTrigger: commercialErrorTrigger)
    
    private lazy var billAnalysisEvents: Observable<Event<(CompareBillResult, BillForecastResult?)>> = Observable
        .combineLatest(accountDetailEvents.elements().filter { $0.isEligibleForUsageData },
                       lastYearPreviousBillSelectedSegmentIndex.asObservable(),
                       electricGasSelectedSegmentIndex.asObservable())
        .toAsyncRequest { [weak self] (accountDetail, yearsIndex, electricGasIndex) in
            guard let self = self else { return .empty() }
            
            let isGas = self.isGas(accountDetail: accountDetail,
                                   electricGasSelectedIndex: electricGasIndex)
            
            let billComparison = UsageService.rx
                .compareBill(accountNumber: accountDetail.accountNumber,
                                     premiseNumber: accountDetail.premiseNumber!,
                                     yearAgo: yearsIndex == 0,
                                     gas: isGas,
                                     useCache: false)
            
            let billForecast: Observable<BillForecastResult?>
            if accountDetail.isAMIAccount {
                billForecast = UsageService.rx.fetchBillForecast(accountNumber: accountDetail.accountNumber,
                                                                   premiseNumber: accountDetail.premiseNumber!)
                    .map { $0 }
                    .catchErrorJustReturn(nil)
            } else {
                billForecast = .just(nil)
            }
            
            return Observable.zip(billComparison, billForecast)
        }
    
    // MARK: - Convenience Properties
    
    private(set) lazy var accountDetail: Driver<AccountDetail> = accountDetailEvents.elements()
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var billComparison: Driver<CompareBillResult> = billAnalysisEvents.elements()
        .map { $0.0 }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var billForecast: Driver<BillForecastResult?> = billAnalysisEvents.elements()
        .map { $1 }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var noPreviousData: Driver<Bool> = billComparison.map { $0.comparedBill == nil }

    
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
    
    let barGraphSelection = BehaviorRelay(value: BarGraphSelection.current)
    
    let electricGasSelectedSegmentIndex = BehaviorRelay(value: 0)
    let lastYearPreviousBillSelectedSegmentIndex = BehaviorRelay(value: 1)
    
    // MARK: - Main States
    
    private(set) lazy var endRefreshIng: Driver<Void> = Driver
        .merge(showMainErrorState,
               showAccountDisallowState,
               showNoNetworkState,
               showMaintenanceModeState,
               showBillComparisonContents,
               showBillComparisonErrorState,
               showNoUsageDataState,
               showCommercialState)
    
    private(set) lazy var showMainErrorState: Driver<Void> = Observable
        .merge(accountDetailEvents.errors(), commercialDataEvents.errors(), commercialErrorTrigger.asObservable())
        .filter {
            ($0 as? NetworkingError) != .noNetwork &&
            ($0 as? NetworkingError) != .blockAccount
        }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    
    private(set) lazy var showAccountDisallowState: Driver<Void> = accountDetailEvents
        .filter { $0.error != nil }
        .filter { ($0.error as? NetworkingError) == .blockAccount }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showNoNetworkState: Driver<Void> = Observable
        .merge(accountDetailEvents.errors(), billAnalysisEvents.errors())
        .filter { ($0 as? NetworkingError) == .noNetwork }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showMaintenanceModeState: Driver<Void> = maintenanceModeEvents
        .elements()
        .filter { $0.usage }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showNoUsageDataState: Driver<Void> = accountDetailEvents
        .filter { accountDetailEvent in
            guard let accountDetail = accountDetailEvent.element, accountDetail.isResidential else { return false }
            return !accountDetail.isEligibleForUsageData
        }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showCommercialState: Driver<Void> = commercialDataEvents
        .elements()
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showPrepaidState: Driver<Void> = accountDetailEvents
        .filter { $0.element?.prepaidStatus == .active }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showMainContents: Driver<Void> = accountDetail
        .filter { $0.isEligibleForUsageData }
        .mapTo(())
    
    // MARK: - Bill Analysis States
    
    private(set) lazy var showBillComparisonContents: Driver<Void> = billAnalysisEvents
        .filter { $0.element?.0.referenceBill != nil }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showBillComparisonErrorState: Driver<Void> = billAnalysisEvents
        .filter { $0.error != nil || $0.element?.0.referenceBill == nil }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showElectricGasSegmentedControl: Driver<Bool> = accountDetailEvents.elements()
        .map { accountDetail in
            switch Configuration.shared.opco {
            case .comEd:
                return false
            case .ace, .bge, .delmarva, .pepco, .peco:
                return accountDetail.serviceType?.uppercased() == "GAS/ELECTRIC"
            }
        }
        .asDriver(onErrorDriveWith: .empty())

    // MARK: - Bill Analysis Content
    
    private(set) lazy var compareBillTitle: Driver<String> = lastYearPreviousBillSelectedSegmentIndex
        .asDriver().map {
            if $0 == 0 {
                return NSLocalizedString("Compared to Last Year", comment: "")
            } else {
                return NSLocalizedString("Compared to Previous Bill", comment: "")
            }
        }
    
    private(set) lazy var billComparisonEmptyStateText: Driver<String> = Driver
        .combineLatest(electricGasSelectedSegmentIndex.asDriver(),
                       showElectricGasSegmentedControl)
        .map { segmentIndex, showSegmentedControl in
            if showSegmentedControl {
                let gasElectricString = NSLocalizedString(segmentIndex == 0 ? "electric" : "gas", comment: "")
                return String.localizedStringWithFormat("Your %@ usage overview will be available here once we have two full months of data.", gasElectricString)
            } else {
                return NSLocalizedString("Your usage overview will be available here once we have two full months of data.", comment: "")
            }
        }
    
    // MARK: No Data Bar Drivers
    
    private(set) lazy var noDataBarDateLabelText: Driver<String?> =
        Driver.combineLatest(billComparison, lastYearPreviousBillSelectedSegmentIndex.asDriver()) {
            guard let reference = $0.referenceBill else { return nil }
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
            guard let reference = billComparison.referenceBill else { return 134 }
            guard let compared = billComparison.comparedBill else { return 0 }
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
        .map { $0.comparedBill?.charges.currencyString }
    
    private(set) lazy var previousBarDateLabelText: Driver<String?> =
        Driver.combineLatest(billComparison, lastYearPreviousBillSelectedSegmentIndex.asDriver()) {
            guard let compared = $0.comparedBill else { return nil }
            if $1 == 0 { // Last Year
                return "\(Calendar.opCo.component(.year, from: compared.endDate))"
            } else { // Previous Bill
                return compared.endDate.shortMonthAndDayString.uppercased()
            }
        }
    
    // MARK: Current Bar Drivers
    
    private(set) lazy var currentBarHeightConstraintValue: Driver<CGFloat> =
        Driver.combineLatest(billComparison, projectedCost) { billComparison, projectedCost in
            guard let reference = billComparison.referenceBill else { return 0 }
            guard let compared = billComparison.comparedBill else { return 134 }
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
        guard let reference = $0.referenceBill else { return nil }
        return reference.charges.currencyString
    }
    
    private(set) lazy var currentBarDateLabelText: Driver<String?> =
        Driver.combineLatest(billComparison, lastYearPreviousBillSelectedSegmentIndex.asDriver()) {
            guard let reference = $0.referenceBill else { return nil }
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
                return billForecast?.gas?.projectedCost
            } else {
                return billForecast?.electric?.projectedCost
            }
        }
    
    private(set) lazy var toDateCost: Driver<Double?> =
           Driver.combineLatest(accountDetail,
                                billForecast,
                                electricGasSelectedSegmentIndex.asDriver())
           { [weak self] accountDetail, billForecast, electricGasSelectedIndex in
               guard let this = self else { return nil }
               if this.isGas(accountDetail: accountDetail, electricGasSelectedIndex: electricGasSelectedIndex) {
                   return billForecast?.gas?.toDateCost
               } else {
                   return billForecast?.electric?.toDateCost
               }
           }
    
    private(set) lazy var projectedCostSoFar: Driver<Double?> =
        Driver.combineLatest(accountDetail,
                             billForecast,
                             electricGasSelectedSegmentIndex.asDriver())
        { [weak self] accountDetail, billForecast, electricGasSelectedIndex in
            guard let this = self else { return nil }
            if this.isGas(accountDetail: accountDetail, electricGasSelectedIndex: electricGasSelectedIndex) {
                return billForecast?.gas?.toDateCost
            } else {
                return billForecast?.electric?.toDateCost
            }
        }
    
    private(set) lazy var projectedUsage: Driver<Double?> =
        Driver.combineLatest(accountDetail,
                             billForecast,
                             electricGasSelectedSegmentIndex.asDriver())
        { [weak self] accountDetail, billForecast, electricGasSelectedIndex in
            guard let this = self else { return nil }
            if this.isGas(accountDetail: accountDetail, electricGasSelectedIndex: electricGasSelectedIndex) {
                return billForecast?.gas?.projectedUsage
            } else {
                return billForecast?.electric?.projectedUsage
            }
        }
    
    private(set) lazy var showProjectedBar: Driver<Bool> =
        Driver.combineLatest(lastYearPreviousBillSelectedSegmentIndex.asDriver(), projectedCost, projectedUsage, showProjectionNotAvailableBar) {
            // Projections are only for "Previous Bill" selection
            $0 == 1 && ($1 != nil || $2 != nil) && !$3
        }
    
    private(set) lazy var projectedBarHeightConstraintValue: Driver<CGFloat> =
        Driver.combineLatest(billComparison, projectedCost) { billComparison, projectedCost in
            guard let projectedCost = projectedCost else { return 3 }
            let reference = billComparison.referenceBill?.charges ?? 0
            let compared = billComparison.comparedBill?.charges ?? 0
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
    
    private(set) lazy var projectedBarSoFarHeightConstraintValue: Driver<CGFloat> =
        Driver.combineLatest(projectedBarHeightConstraintValue, projectedCost, projectedCostSoFar) { heightConstraint, projectedCost, projectedCostSoFar in
            guard let projectedCost = projectedCost, projectedCost > 0, let projectedCostSoFar = projectedCostSoFar else { return 0 }  // 340398 fix for crash with constraint being set to infinite number when dividing by 0
            let fraction = heightConstraint * CGFloat(projectedCostSoFar / projectedCost)
            return fraction > 3 ? fraction : 0
        }
    
    private(set) lazy var projectedBarDollarLabelText: Driver<String?> =
        Driver.combineLatest(accountDetail,
                             projectedCost,
                             projectedUsage,
                             billComparison,
                             toDateCost)
        { [weak self] accountDetail, cost, usage, billComparison, toDateCost in
            if accountDetail.isModeledForOpower || (Configuration.shared.opco.isPHI && cost > 0 && toDateCost > 0) {
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
                if let endDate = billForecast?.gas?.billingEndDate {
                    return endDate.shortMonthAndDayString.uppercased()
                }
            } else if let endDate = billForecast?.electric?.billingEndDate {
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
            let today = Calendar.opCo.startOfDay(for: .now)
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
            let today = Calendar.opCo.startOfDay(for: .now)
            
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
        guard let compared = $0.comparedBill else { return nil }
        
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
            detailString = String(format: billCreditString, abs(compared.charges).currencyString, avgUsagePerDay.twoDecimalString, $0.meterUnit)
        } else {
            let localizedString = NSLocalizedString("Your bill was %@. You used an average of %@ %@ per day.", comment: "")
            detailString = String(format: localizedString, compared.charges.currencyString, avgUsagePerDay.twoDecimalString, $0.meterUnit)
        }
        
        return "\(dateString). \(tempString). \(detailString)"
    }
    
    private(set) lazy var currentBarA11yLabel: Driver<String?> = billComparison.map {
        guard let reference = $0.referenceBill else { return nil }
        
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
            detailString = String(format: billCreditString, abs(reference.charges).currencyString, avgUsagePerDay.twoDecimalString, $0.meterUnit)
        } else {
            let localizedString = NSLocalizedString("Your bill was %@. You used an average of %@ %@ per day.", comment: "")
            detailString = String(format: localizedString, reference.charges.currencyString, avgUsagePerDay.twoDecimalString, $0.meterUnit)
        }
        
        return "\(dateString). \(tempString). \(detailString)"
    }
    
    private(set) lazy var projectedBarA11yLabel: Driver<String?> =
        Driver.combineLatest(accountDetail,
                             billComparison,
                             billForecast,
                             projectedCost,
                             toDateCost,
                             electricGasSelectedSegmentIndex.asDriver())
        { [weak self] accountDetail, billComparison, billForecast, projectedCost, toDateCost, electricGasSelectedIndex in
            guard let this = self else { return nil }
            guard let billForecast = billForecast else { return nil }
            let isGas = this.isGas(accountDetail: accountDetail, electricGasSelectedIndex: electricGasSelectedIndex)
            
            var dateString = ""
            if isGas {
                if let startDate = billForecast.gas?.billingStartDate,
                    let endDate = billForecast.gas?.billingEndDate {
                    dateString = "\(startDate.shortMonthDayAndYearString) to \(endDate.shortMonthDayAndYearString)"
                }
            } else if let startDate = billForecast.electric?.billingStartDate,
                let endDate = billForecast.electric?.billingEndDate {
                dateString = "\(startDate.shortMonthDayAndYearString) to \(endDate.shortMonthDayAndYearString)"
            }
            
            
            var detailString = ""
            if accountDetail.isModeledForOpower || (Configuration.shared.opco.isPHI && projectedCost > 0 && toDateCost > 0) {
                let localizedString = NSLocalizedString("Your bill is projected to be around %@. You've spent about %@ so far this bill period. " +
                    "This is an estimate and the actual amount may vary based on your energy use, taxes, and fees.", comment: "")
                if isGas {
                    if let projectedCost = billForecast.gas?.projectedCost,
                        let toDateCost = billForecast.gas?.toDateCost {
                        detailString = String(format: localizedString, projectedCost.currencyString, toDateCost.currencyString)
                    }
                } else if let projectedCost = billForecast.electric?.projectedCost,
                    let toDateCost = billForecast.electric?.toDateCost {
                    detailString = String(format: localizedString, projectedCost.currencyString, toDateCost.currencyString)
                }
            } else {
                let localizedString = NSLocalizedString("You are projected to use around %d %@. You've used about %d %@ so far this bill period. " +
                    "This is an estimate and the actual amount may vary based on your energy use, taxes, and fees.", comment: "")
                let meterUnit = billComparison.meterUnit
                if isGas {
                    if let projectedUsage = billForecast.gas?.projectedUsage,
                        let toDateUsage = billForecast.gas?.toDateUsage {
                        detailString = String(format: localizedString, Int(projectedUsage), meterUnit, Int(toDateUsage), meterUnit)
                    }
                } else if let projectedUsage = billForecast.electric?.projectedUsage,
                    let toDateUsage = billForecast.electric?.toDateUsage {
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
            
            let today = Calendar.opCo.startOfDay(for: .now)
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
                if let compared = billComparison.comparedBill {
                    return "\(compared.startDate.shortMonthDayAndYearString) - \(compared.endDate.shortMonthDayAndYearString)"
                }
            case .current:
                if let reference = billComparison.referenceBill {
                    return "\(reference.startDate.shortMonthDayAndYearString) - \(reference.endDate.shortMonthDayAndYearString)"
                }
            case .projected:
                if let gasForecast = billForecast?.gas, isGas {
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
                if let compared = billComparison.comparedBill, let temp = compared.averageTemperature {
                    return String(format: localizedString, Int(temp.rounded()))
                }
            case .current:
                if let reference = billComparison.referenceBill, let temp = reference.averageTemperature {
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
                             electricGasSelectedSegmentIndex.asDriver(),
                             projectedCost,
                             toDateCost)
        { [weak self] accountDetail, billComparison, barGraphSelection, billForecast, electricGasSelectedIndex, projectedCost, toDateCost in
            guard let this = self else { return nil }
            let isGas = this.isGas(accountDetail: accountDetail, electricGasSelectedIndex: electricGasSelectedIndex)
            
            let localizedPrevCurrString = NSLocalizedString("Your bill was %@. You used an average of %@ %@ per day.", comment: "")
            switch barGraphSelection {
            case .noData:
                return NSLocalizedString("Not enough data available.", comment: "")
            case .previous:
                if let compared = billComparison.comparedBill {
                    let daysInBillPeriod = abs(compared.startDate.interval(ofComponent: .day, fromDate: compared.endDate))
                    let avgUsagePerDay = compared.usage / Double(daysInBillPeriod)
                    if compared.charges < 0 {
                        let billCreditString = NSLocalizedString("You had a bill credit of %@. You used an average of %@ %@ per day.", comment: "")
                        return String(format: billCreditString, abs(compared.charges).currencyString, avgUsagePerDay.twoDecimalString, billComparison.meterUnit)
                    } else {
                        return String(format: localizedPrevCurrString, compared.charges.currencyString, avgUsagePerDay.twoDecimalString, billComparison.meterUnit)
                    }
                }
            case .current:
                if let reference = billComparison.referenceBill {
                    let daysInBillPeriod = abs(reference.startDate.interval(ofComponent: .day, fromDate: reference.endDate))
                    let avgUsagePerDay = reference.usage / Double(daysInBillPeriod)
                    if reference.charges < 0 {
                        let billCreditString = NSLocalizedString("You had a bill credit of %@. You used an average of %@ %@ per day.", comment: "")
                        return String(format: billCreditString, abs(reference.charges).currencyString, avgUsagePerDay.twoDecimalString, billComparison.meterUnit)
                    } else {
                        return String(format: localizedPrevCurrString, reference.charges.currencyString, avgUsagePerDay.twoDecimalString, billComparison.meterUnit)
                    }
                }
            case .projected:
                if accountDetail.isModeledForOpower || (Configuration.shared.opco.isPHI && projectedCost > 0 && toDateCost > 0) {
                    let localizedString = NSLocalizedString("Your bill is projected to be around %@. You've spent about %@ so far this bill period. " +
                        "This is an estimate and the actual amount may vary based on your energy use, taxes, and fees.", comment: "")
                    if let gasForecast = billForecast?.gas, isGas {
                        if let projectedCost = gasForecast.projectedCost, let toDateCost = gasForecast.toDateCost {
                            return String(format: localizedString, projectedCost.currencyString, toDateCost.currencyString)
                        }
                    }
                    if let elecForecast = billForecast?.electric, !isGas {
                        if let projectedCost = elecForecast.projectedCost, let toDateCost = elecForecast.toDateCost {
                            return String(format: localizedString, projectedCost.currencyString, toDateCost.currencyString)
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
    
    // MARK: Selection States
    
    func setBarSelected(tag: Int) {
        barGraphSelection.accept(BarGraphSelection(rawValue: tag) ?? .current)
    }
    
    // MARK: - Text Styling
    
    private(set) lazy var noDataLabelFont: Driver<UIFont> = barGraphSelection.asDriver()
        .map { $0 == .noData }
        .distinctUntilChanged()
        .map { $0 ? SystemFont.bold.of(textStyle: .footnote) : SystemFont.semibold.of(textStyle: .footnote) }
    
    private(set) lazy var previousLabelFont: Driver<UIFont> = barGraphSelection.asDriver()
        .map { $0 == .previous }
        .distinctUntilChanged()
        .map { $0 ? SystemFont.bold.of(textStyle: .footnote) : SystemFont.semibold.of(textStyle: .footnote) }
    
    private(set) lazy var previousDollarLabelTextColor: Driver<UIColor> = billComparison.map {
        guard let compared = $0.comparedBill else { return .deepGray }
        return compared.charges < 0 ? .successGreenText : .deepGray
    }
    
    private(set) lazy var currentLabelFont: Driver<UIFont> = barGraphSelection.asDriver()
        .map { $0 == .current }
        .distinctUntilChanged()
        .map { $0 ? SystemFont.bold.of(textStyle: .footnote) : SystemFont.semibold.of(textStyle: .footnote) }
    
    private(set) lazy var currentDollarLabelTextColor: Driver<UIColor> = billComparison.map {
        guard let reference = $0.referenceBill else { return .deepGray }
        return reference.charges < 0 ? .successGreenText : .deepGray
    }
    
    private(set) lazy var projectedLabelFont: Driver<UIFont> = barGraphSelection.asDriver()
        .map { $0 == .projected }
        .distinctUntilChanged()
        .map { $0 ? OpenSans.bold.of(textStyle: .footnote) : OpenSans.semibold.of(textStyle: .footnote) }
    
    private(set) lazy var projectionNotAvailableLabelFont: Driver<UIFont> = barGraphSelection.asDriver()
        .map { $0 == .projectionNotAvailable }
        .distinctUntilChanged()
        .map { $0 ? OpenSans.bold.of(textStyle: .footnote) : OpenSans.semibold.of(textStyle: .footnote) }
    
    // MARK: - Usage Tools
    
    private(set) lazy var usageTools: Driver<[UsageTool]> = accountDetail
        .filter { $0.isEligibleForUsageData }
        .map { accountDetail in
            var usageTools: [UsageTool] = [.usageData, .energyTips, .homeProfile]
            
            switch Configuration.shared.opco {
            case .bge:
                if accountDetail.peakRewards == "ACTIVE" {
                    usageTools.insert(.peakRewards, at: 1)
                }
                
                if accountDetail.isSERAccount {
                    usageTools.append(.smartEnergyRewards)
                }
            case .comEd:
                usageTools.insert(.hourlyPricing, at: 1)
                
                if accountDetail.isPTSAccount || accountDetail.isAMIAccount {
                    usageTools.append(.peakTimeSavings)
                }
            case .peco:
                break
            case .ace, .delmarva, .pepco:
                if accountDetail.opcoType == .ace {
                    usageTools.insert(.energyWiseRewards, at: 1)
                } else if accountDetail.opcoType == .delmarva {
                    if accountDetail.isEnergyWiseRewardsEligible || accountDetail.isEnergyWiseRewardsEnrolled {
                        usageTools.insert(.energyWiseRewards, at: 1)
                    }
                    if (accountDetail.isPeakEnergySavingsCreditEligible || accountDetail.isPeakEnergySavingsCreditEnrolled) && (accountDetail.subOpco == .delmarvaMaryland || accountDetail.subOpco == .delmarvaDelaware) {
                        usageTools.append(.peakEnergySavings)
                    }
                } else if accountDetail.opcoType == .pepco {
                    usageTools.insert(.energyWiseRewards, at: 1)
                    if (accountDetail.isPeakEnergySavingsCreditEligible || accountDetail.isPeakEnergySavingsCreditEnrolled) && accountDetail.subOpco == .pepcoMaryland {
                        usageTools.append(.peakEnergySavings)
                    }
                }
            }
            return usageTools
        }
    
    // MARK: - Helpers
    
    // If a gas only account, return true, if an electric only account, returns false, if both gas/electric, returns selected segemented control
    private func isGas(accountDetail: AccountDetail, electricGasSelectedIndex: Int) -> Bool {
        if accountDetail.serviceType?.uppercased() == "GAS" { // If account is gas only
            return true
        } else if Configuration.shared.opco != .comEd && accountDetail.serviceType?.uppercased() == "GAS/ELECTRIC" {
            return electricGasSelectedIndex == 1
        }
        // Default to electric
        return false
    }
}

