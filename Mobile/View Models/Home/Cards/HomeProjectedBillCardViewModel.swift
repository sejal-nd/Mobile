//
//  HomeProjectedBillCardViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 7/6/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class HomeProjectedBillCardViewModel {
    
    let disposeBag = DisposeBag()
    
    private let maintenanceModeEvents: Observable<Event<Maintenance>>
    let accountDetailEvents: Observable<Event<AccountDetail>>
    private let usageService: UsageService
    
    private let fetchData: Observable<FetchingAccountState>
    
    let refreshFetchTracker: ActivityTracker
    let switchAccountFetchTracker: ActivityTracker
    let loadingTracker = ActivityTracker()
    
    let electricGasSelectedSegmentIndex = Variable(0)
    let electricForecast = Variable<BillForecast?>(nil)
    let gasForecast = Variable<BillForecast?>(nil)
    
    private func fetchTracker(forState state: FetchingAccountState) -> ActivityTracker {
        switch state {
        case .refresh: return refreshFetchTracker
        case .switchAccount: return switchAccountFetchTracker
        }
    }
    
    required init(fetchData: Observable<FetchingAccountState>,
                  maintenanceModeEvents: Observable<Event<Maintenance>>,
                  accountDetailEvents: Observable<Event<AccountDetail>>,
                  usageService: UsageService,
                  refreshFetchTracker: ActivityTracker,
                  switchAccountFetchTracker: ActivityTracker) {
        self.fetchData = fetchData
        self.maintenanceModeEvents = maintenanceModeEvents
        self.accountDetailEvents = accountDetailEvents
        self.usageService = usageService
        self.refreshFetchTracker = refreshFetchTracker
        self.switchAccountFetchTracker = switchAccountFetchTracker
    }
    
    // MARK: - Show States
    
    private(set) lazy var showLoadingState: Driver<Bool> = switchAccountFetchTracker.asDriver()
        .skip(1)
        .startWith(true)
        .distinctUntilChanged()
    
    private(set) lazy var showEmptyState: Driver<Void> = accountDetailEvents.elements()
        .withLatestFrom(maintenanceModeEvents)
        { ($0.isEligibleForUsageData, $1.element?.usageStatus ?? false)}
        .filter { !$0 && !$1 }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var accountDetailError: Observable<Void> = accountDetailEvents
        .filter { $0.error != nil }
        .withLatestFrom(maintenanceModeEvents.elements())
        .filter { !$0.usageStatus }
        .mapTo(())
    
    private lazy var billForecastError: Observable<Void> = billForecastEvents
        .filter { $0.error != nil || ($0.element?.gas == nil && $0.element?.electric == nil) }
        .mapTo(())
    
    private(set) lazy var showError: Driver<Void> = Observable
        .merge(accountDetailError, billForecastError)
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showMaintenanceModeState: Driver<Void> = maintenanceModeEvents.elements()
        .filter { $0.usageStatus }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showContent: Driver<Void> = billForecastEvents
        .filter {
            $0.element?.gas != nil || $0.element?.electric != nil
        }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var shouldShowElectricGasSegmentedControl: Driver<Bool> = accountDetailEvents.map {
        $0.element?.serviceType?.uppercased() == "GAS/ELECTRIC"
        }
        .asDriver(onErrorDriveWith: .empty())
    
    // MARK: - Web Service Calls
    
    private(set) lazy var billForecastEvents = self.accountDetailEvents.elements()
        .withLatestFrom(maintenanceModeEvents) { ($0, $1.element?.usageStatus ?? false)}
        .filter { $0.isEligibleForUsageData && !$1 }
        .withLatestFrom(fetchData) { ($0.0, $1) }
        .toAsyncRequest(activityTracker: { [weak self] pair -> ActivityTracker? in
            return self?.fetchTracker(forState: pair.1) },
                        requestSelector: { [weak self] pair -> Observable<BillForecastResult> in
                            guard let this = self else { return .empty() }
                            return this.usageService.fetchBillForecast(accountNumber: pair.0.accountNumber,
                                                                       premiseNumber: pair.0.premiseNumber!)
        })
    
    // MARK: - View Content
    
    private(set) lazy var accountDetailDriver: Driver<AccountDetail> = self.accountDetailEvents.elements().asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var billForecastDriver: Driver<BillForecastResult> = self.billForecastEvents.elements().asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var isGas: Driver<Bool> = Driver
        .combineLatest(accountDetailDriver, electricGasSelectedSegmentIndex.asDriver())
        .map { accountDetail, segmentIndex in
            if accountDetail.serviceType?.uppercased() == "GAS" { // If account is gas only
                return true
            } else if accountDetail.serviceType?.uppercased() == "GAS/ELECTRIC" { // Use value of segmented control
                return segmentIndex == 1
            }
            return false
        }
    
    private(set) lazy var projectionNotAvailable: Driver<Bool> = Driver
        .combineLatest(billForecastDriver, isGas)
        .map { billForecast, isGas in
            let today = Calendar.opCo.startOfDay(for: Date())
            if !isGas, let startDate = billForecast.electric?.billingStartDate {
                let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
                return daysSinceBillingStart < 7
            } else if isGas, let startDate = billForecast.gas?.billingStartDate  {
                let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
                return daysSinceBillingStart < 7
            }
            return false
        }
    
    private(set) lazy var projectionLabelString: Driver<String?> = Driver
        .combineLatest(billForecastDriver, isGas, accountDetailDriver)
        .map { billForecast, isGas, accountDetail in
            let today = Calendar.opCo.startOfDay(for: Date())
            let localizedString = NSLocalizedString("%@ days", comment: "")
            if !isGas,
                let elecCost = billForecast.electric?.projectedCost,
                let startDate = billForecast.electric?.billingStartDate {
                let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
                if daysSinceBillingStart < 7 {
                    let daysRemaining = 7 - daysSinceBillingStart
                    if daysRemaining == 1 {
                        return NSLocalizedString("1 day", comment: "")
                    } else {
                        return String(format: localizedString, "\(daysRemaining)")
                    }
                }
                if !accountDetail.isModeledForOpower,
                    let elecForecast = billForecast.electric,
                    let elecUsage = elecForecast.projectedUsage {
                    return String(format: "%d %@", Int(elecUsage), elecForecast.meterUnit)
                }
                return elecCost.currencyString
            } else if isGas, let gasCost = billForecast.gas?.projectedCost, let startDate = billForecast.gas?.billingStartDate {
                let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
                if daysSinceBillingStart < 7 {
                    let daysRemaining = 7 - daysSinceBillingStart
                    if daysRemaining == 1 {
                        return NSLocalizedString("1 day", comment: "")
                    } else {
                        return String(format: localizedString, "\(daysRemaining)")
                    }
                }
                if !accountDetail.isModeledForOpower,
                    let gasForecast = billForecast.gas,
                    let gasUsage = gasForecast.projectedUsage {
                    return String(format: "%d %@", Int(gasUsage), gasForecast.meterUnit)
                }
                return gasCost.currencyString
            }
            return nil
        }
    
    private(set) lazy var projectionSubLabelString: Driver<String?> = Driver.combineLatest(self.billForecastDriver,
                                                                                           self.isGas)
        .map { billForecast, isGas in
            let today = Calendar.opCo.startOfDay(for: Date())
            if !isGas,
                let startDate = billForecast.electric?.billingStartDate,
                let endDate = billForecast.electric?.billingEndDate {
                let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
                if daysSinceBillingStart < 7 {
                    return NSLocalizedString("until next forecast", comment: "")
                }
                
                return "\(startDate.shortMonthAndDayString) - \(endDate.shortMonthAndDayString)".uppercased()
            } else if isGas,
                let startDate = billForecast.gas?.billingStartDate,
                let endDate = billForecast.gas?.billingEndDate {
                let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
                if daysSinceBillingStart < 7 {
                    return NSLocalizedString("until next forecast", comment: "")
                }
                
                return "\(startDate.shortMonthAndDayString) - \(endDate.shortMonthAndDayString)".uppercased()
            }
            return nil
        }
    
    private(set) lazy var projectionFooterLabelString: Driver<String?> = Driver.combineLatest(self.billForecastDriver,
                                                                                              self.isGas,
                                                                                              self.accountDetailDriver)
        .map { billForecast, isGas, accountDetail in
            if !accountDetail.isModeledForOpower {
                var toDateString: String? = nil
                if !isGas,
                    let elecForecast = billForecast.electric,
                    let toDateUsage = elecForecast.toDateUsage {
                    toDateString = String(format: "%d %@", Int(toDateUsage), elecForecast.meterUnit)
                } else if isGas,
                    let gasForecast = billForecast.gas,
                    let toDateUsage = gasForecast.toDateUsage {
                    toDateString = String(format: "%d %@", Int(toDateUsage), gasForecast.meterUnit)
                }
                if let str = toDateString {
                    return String(format: NSLocalizedString("You've used about %@ so far this bill period.", comment: ""), str)
                }
            } else {
                var toDateString: String? = nil
                if !isGas, let toDateCost = billForecast.electric?.toDateCost {
                    toDateString = toDateCost.currencyString
                } else if isGas, let toDateCost = billForecast.gas?.toDateCost {
                    toDateString = toDateCost.currencyString
                }
                if let str = toDateString {
                    return String(format: NSLocalizedString("You've spent about %@ so far this bill period.", comment: ""), str)
                }
            }
            return nil
        }
}
