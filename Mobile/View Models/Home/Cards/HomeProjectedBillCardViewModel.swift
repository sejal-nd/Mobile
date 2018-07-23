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
                  accountDetailEvents: Observable<Event<AccountDetail>>,
                  usageService: UsageService,
                  refreshFetchTracker: ActivityTracker,
                  switchAccountFetchTracker: ActivityTracker) {
        self.fetchData = fetchData
        self.accountDetailEvents = accountDetailEvents
        self.usageService = usageService
        self.refreshFetchTracker = refreshFetchTracker
        self.switchAccountFetchTracker = switchAccountFetchTracker
    }
    
    private(set) lazy var billForecastEvents: Observable<Event<[BillForecast?]>> = self.accountDetailChanged.share(replay: 1)
    
    // Used by HomeViewModel
    private(set) lazy var cardShouldBeHidden: Observable<Bool> = self.billForecastEvents.map { billForecastEvent in
        if billForecastEvent.error != nil {
            return true
        }
        if billForecastEvent.element != nil {
            let elecForecast = billForecastEvent.element![0]
            let gasForecast = billForecastEvent.element![1]
            return elecForecast == nil && gasForecast == nil
        }
        return true
    }
    
    private(set) lazy var accountDetailChanged = self.accountDetailEvents
        .withLatestFrom(Observable.combineLatest(self.fetchData, self.accountDetailEvents))
        .flatMapLatest { [unowned self] fetchState, accountDetailEvent -> Observable<Event<[BillForecast?]>> in
            guard let accountDetail = accountDetailEvent.element else {
                if let error = accountDetailEvent.error {
                    return Observable.error(error).materialize()
                }
                return Observable.error(ServiceError(serviceCode: ServiceErrorCode.tcUnknown.rawValue)).materialize()
            }
            
            guard let premiseNumber = accountDetail.premiseNumber, let serviceType = accountDetail.serviceType else {
                //return .empty()
                return Observable.error(ServiceError(serviceCode: ServiceErrorCode.tcUnknown.rawValue)).materialize()
            }
            
            // Throw these Observable.errors to trigger a billComparisonDriver event even when we don't make the API call
            if !accountDetail.isResidential || accountDetail.isBGEControlGroup || accountDetail.isFinaled {
                return Observable.error(ServiceError(serviceCode: ServiceErrorCode.tcUnknown.rawValue)).materialize()
            }
            if serviceType.uppercased() != "GAS" && serviceType.uppercased() != "ELECTRIC" && serviceType.uppercased() != "GAS/ELECTRIC" {
                return Observable.error(ServiceError(serviceCode: ServiceErrorCode.tcUnknown.rawValue)).materialize()
            }
            
            return self.usageService.fetchBillForecast(accountNumber: accountDetail.accountNumber, premiseNumber: premiseNumber)
                .trackActivity(self.fetchTracker(forState: fetchState))
                .materialize()
                .filter { !$0.isCompleted }
        }
        .share()
    
    private(set) lazy var accountDetailDriver: Driver<AccountDetail> = self.accountDetailEvents.elements().asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var billForecastDriver: Driver<[BillForecast?]> = self.billForecastEvents.elements().asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var shouldShowElectricGasSegmentedControl: Driver<Bool> = self.accountDetailEvents.map {
        $0.element?.serviceType?.uppercased() == "GAS/ELECTRIC"
    }
    .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var isGas: Driver<Bool> = Driver.combineLatest(self.accountDetailDriver, self.electricGasSelectedSegmentIndex.asDriver())
        .map { accountDetail, segmentIndex in
            if accountDetail.serviceType!.uppercased() == "GAS" { // If account is gas only
                return true
            } else if accountDetail.serviceType!.uppercased() == "GAS/ELECTRIC" { // Use value of segmented control
                return segmentIndex == 1
            }
            return false
        }
    
    private(set) lazy var projectionNotAvailable: Driver<Bool> = Driver.combineLatest(self.billForecastDriver,
                                                                                      self.isGas)
        .map { billForecast, isGas in
            let today = Calendar.opCo.startOfDay(for: Date())
            if !isGas, let elecForecast = billForecast[0], let startDate = elecForecast.billingStartDate {
                let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
                return daysSinceBillingStart < 7
            } else if isGas, let gasForecast = billForecast[1], let startDate = gasForecast.billingStartDate  {
                let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
                return daysSinceBillingStart < 7
            }
            return false
        }
    
    private(set) lazy var projectionLabelString: Driver<String?> = Driver.combineLatest(self.billForecastDriver,
                                                                                        self.isGas,
                                                                                        self.accountDetailDriver)
        .map { billForecast, isGas, accountDetail in
            let today = Calendar.opCo.startOfDay(for: Date())
            let localizedString = NSLocalizedString("%@ days", comment: "")
            if !isGas, let elecForecast = billForecast[0], let elecCost = elecForecast.projectedCost, let startDate = elecForecast.billingStartDate {
                let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
                if daysSinceBillingStart < 7 {
                    let daysRemaining = 7 - daysSinceBillingStart
                    if daysRemaining == 1 {
                        return NSLocalizedString("1 day", comment: "")
                    } else {
                        return String(format: localizedString, "\(daysRemaining)")
                    }
                }
                if !accountDetail.isModeledForOpower, let elecUsage = elecForecast.projectedUsage {
                    return String(format: "%d %@", Int(elecUsage), elecForecast.meterUnit)
                }
                return elecCost.currencyString
            } else if isGas, let gasForecast = billForecast[1], let gasCost = gasForecast.projectedCost, let startDate = gasForecast.billingStartDate {
                let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
                if daysSinceBillingStart < 7 {
                    let daysRemaining = 7 - daysSinceBillingStart
                    if daysRemaining == 1 {
                        return NSLocalizedString("1 day", comment: "")
                    } else {
                        return String(format: localizedString, "\(daysRemaining)")
                    }
                }
                if !accountDetail.isModeledForOpower, let gasUsage = gasForecast.projectedUsage {
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
            if !isGas, let elecForecast = billForecast[0], let startDate = elecForecast.billingStartDate, let endDate = elecForecast.billingEndDate {
                let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
                if daysSinceBillingStart < 7 {
                    return NSLocalizedString("until next forecast", comment: "")
                }
                return "\(startDate.shortMonthAndDayString) - \(endDate.shortMonthAndDayString)".uppercased()
            } else if isGas, let gasForecast = billForecast[1], let startDate = gasForecast.billingStartDate, let endDate = gasForecast.billingEndDate {
                let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
                if daysSinceBillingStart < 7 {
                    return NSLocalizedString("until next forecast", comment: "")
                }
                return "\(startDate.shortMonthAndDayString) - \(endDate.shortMonthAndDayString)".uppercased();
            }
            return nil
        }
    
    private(set) lazy var projectionFooterLabelString: Driver<String?> = Driver.combineLatest(self.billForecastDriver,
                                                                                              self.isGas,
                                                                                              self.accountDetailDriver)
        .map { billForecast, isGas, accountDetail in
            if !accountDetail.isModeledForOpower {
                var toDateString: String? = nil
                if !isGas, let elecForecast = billForecast[0], let toDateUsage = elecForecast.toDateUsage {
                    toDateString = String(format: "%d %@", Int(toDateUsage), elecForecast.meterUnit)
                } else if isGas, let gasForecast = billForecast[1], let toDateUsage = gasForecast.toDateUsage {
                    toDateString = String(format: "%d %@", Int(toDateUsage), gasForecast.meterUnit)
                }
                if let str = toDateString {
                    return String(format: NSLocalizedString("You've used about %@ so far this bill period.", comment: ""), str)
                }
            } else {
                var toDateString: String? = nil
                if !isGas, let elecForecast = billForecast[0], let toDateCost = elecForecast.toDateCost {
                    toDateString = toDateCost.currencyString
                } else if isGas, let gasForecast = billForecast[1], let toDateCost = gasForecast.toDateCost {
                    toDateString = toDateCost.currencyString
                }
                if let str = toDateString {
                    return String(format: NSLocalizedString("You've spent about %@ so far this bill period.", comment: ""), str)
                }
            }
            return nil
        }
}