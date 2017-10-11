//
//  BillAnalysisViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 10/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class BillAnalysisViewModel {
    
    let disposeBag = DisposeBag()
    let usageService: UsageService
    
    var accountDetail: AccountDetail! // Passed from BillViewController
    
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
    let noPreviousData = Variable(false)
    
    let electricGasSelectedSegmentIndex = Variable(0)
    let lastYearPreviousBillSelectedSegmentIndex = Variable(1)
    let currentBillComparison = Variable<BillComparison?>(nil)
    
    required init(usageService: UsageService) {
        self.usageService = usageService
    }
    
    deinit {
        if let disposable = currentFetchDisposable {
            disposable.dispose()
        }
    }
    
    func fetchBillComparison(onSuccess: (() -> Void)?) {
        isFetching.value = true
        isError.value = false
        noPreviousData.value = false
        currentBillComparison.value = nil
        
        var gas = false // Default to electric
        if accountDetail.serviceType!.uppercased() == "GAS" { // If account is gas only
            gas = true
        } else if shouldShowElectricGasToggle { // Use value of segmented control
            gas = electricGasSelectedSegmentIndex.value == 1
        }
        
        // Unsubscribe before starting a new request to prevent race condition when quickly toggling segmented controls
        if let disposable = currentFetchDisposable {
            disposable.dispose()
        }
        
        // The premiseNumber/billDate force unwraps are safe because they are checked in BillViewModel: shouldShowNeedHelpUnderstanding
        currentFetchDisposable =
            usageService.fetchBillComparison(accountNumber: accountDetail.accountNumber,
                                             premiseNumber: accountDetail.premiseNumber!,
                                             billDate: accountDetail.billingInfo.billDate!,
                                             yearAgo: lastYearPreviousBillSelectedSegmentIndex.value == 0,
                                             gas: gas)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] billComparison in
                onSuccess?() // Fire this off first so we can update barGraphSelectionStates
                self?.isFetching.value = false
                self?.currentBillComparison.value = billComparison
                if billComparison.reference == nil {
                    self?.isError.value = true // Screen is useless without reference data
                } else if billComparison.compared == nil {
                    self?.noPreviousData.value = true
                }
            }, onError: { [weak self] err in
                self?.isFetching.value = false
                self?.isError.value = true
            })
    }
    
    var shouldShowElectricGasToggle: Bool {
        if Environment.sharedInstance.opco != .comEd {
            // We can force unwrap here because this view is unreachable if it's null
            return accountDetail.serviceType!.uppercased() == "GAS/ELECTRIC"
        }
        return false
    }
    
    var shouldShowCurrentChargesSection: Bool {
        if Environment.sharedInstance.opco == .comEd {
            let supplyCharges = accountDetail.billingInfo.supplyCharges ?? 0
            let taxesAndFees = accountDetail.billingInfo.taxesAndFees ?? 0
            let deliveryCharges = accountDetail.billingInfo.deliveryCharges ?? 0
            let totalCharges = supplyCharges + taxesAndFees + deliveryCharges
            return totalCharges > 0
        }
        return false
    }
    
    private(set) lazy var shouldShowBillComparisonContentView: Driver<Bool> =
        Driver.combineLatest(self.isFetching.asDriver(), self.isError.asDriver()).map {
            !$0 && !$1
        }
    
    // MARK: Previous Bar Drivers
    
    private(set) lazy var previousBarHeightConstraintValue: Driver<CGFloat> = self.currentBillComparison.asDriver().map {
        guard let reference = $0?.reference else { return 79 }
        guard let compared = $0?.compared else { return 0 }
        if compared.charges >= reference.charges {
            return 134
        } else {
            return CGFloat(134.0 * (compared.charges / reference.charges))
        }
    }
    
    private(set) lazy var previousBarDollarLabelText: Driver<String?> = self.currentBillComparison.asDriver().map {
        guard let compared = $0?.compared else { return nil }
        return compared.charges.currencyString
    }
    
    private(set) lazy var previousBarDateLabelText: Driver<String?> =
        Driver.combineLatest(self.currentBillComparison.asDriver(), self.lastYearPreviousBillSelectedSegmentIndex.asDriver()) {
            guard let compared = $0?.compared else { return nil }
            if $1 == 0 { // Last Year
                return "\(Calendar.opCoTime.component(.year, from: compared.endDate))"
            } else { // Previous Bill
                return compared.endDate.shortMonthAndDayString.uppercased()
            }
        }
    
    // MARK: Current Bar Drivers
    
    private(set) lazy var currentBarHeightConstraintValue: Driver<CGFloat> = self.currentBillComparison.asDriver().map {
        guard let reference = $0?.reference else { return 0 }
        guard let compared = $0?.compared else { return 79 }
        if reference.charges >= compared.charges {
            return 134
        } else {
            return CGFloat(134.0 * (reference.charges / compared.charges))
        }
    }
    
    private(set) lazy var currentBarDollarLabelText: Driver<String?> = self.currentBillComparison.asDriver().map {
        guard let reference = $0?.reference else { return nil }
        return reference.charges.currencyString
    }
    
    private(set) lazy var currentBarDateLabelText: Driver<String?> =
        Driver.combineLatest(self.currentBillComparison.asDriver(), self.lastYearPreviousBillSelectedSegmentIndex.asDriver()) {
            guard let reference = $0?.reference else { return nil }
            if $1 == 0 { // Last Year
                return "\(Calendar.opCoTime.component(.year, from: reference.endDate))"
            } else { // Previous Bill
                return reference.endDate.shortMonthAndDayString.uppercased()
            }
        }
    
    // MARK: Bar Description Box Drivers
    
    private(set) lazy var barDescriptionDateLabelText: Driver<String?> =
        Driver.combineLatest(self.currentBillComparison.asDriver(),
                             self.lastYearPreviousBillSelectedSegmentIndex.asDriver(),
                             self.barGraphSelectionStates.asDriver()) { currentBillComparison, segmentIndex, selectionStates in
            guard let billComparison = currentBillComparison else { return nil }
            if selectionStates[0].value { // No data
                if segmentIndex == 0 {
                    return NSLocalizedString("Last Year", comment: "")
                } else {
                    return NSLocalizedString("Previous Bill", comment: "")
                }
            } else if selectionStates[1].value { // Previous
                return "\(billComparison.compared!.startDate.shortMonthDayAndYearString) - \(billComparison.compared!.endDate.shortMonthDayAndYearString)"
            } else if selectionStates[2].value { // Current
                return "\(billComparison.reference!.startDate.shortMonthDayAndYearString) - \(billComparison.reference!.endDate.shortMonthDayAndYearString)"
            } else if selectionStates[3].value { // Projected
            
            } else if selectionStates[4].value { // Projection Not Available
                return NSLocalizedString("Projection Not Available", comment: "")
            }
            return nil
        }
    
    private(set) lazy var barDescriptionAvgTempLabelText: Driver<String?> =
        Driver.combineLatest(self.currentBillComparison.asDriver(), self.barGraphSelectionStates.asDriver()) { currentBillComparison, selectionStates in
            guard let billComparison = currentBillComparison else { return nil }
            let localizedString = NSLocalizedString("Avg. Temp %d° F", comment: "")
            if selectionStates[1].value { // Previous
                return String(format: localizedString, Int(billComparison.compared!.averageTemperature.rounded()))
            } else if selectionStates[2].value { // Current
                return String(format: localizedString, Int(billComparison.reference!.averageTemperature.rounded()))
            }
            return nil
        }
    
    private(set) lazy var barDescriptionDetailLabelText: Driver<String?> =
        Driver.combineLatest(self.currentBillComparison.asDriver(), self.barGraphSelectionStates.asDriver()) { currentBillComparison, selectionStates in
            guard let billComparison = currentBillComparison else { return nil }
            let localizedPrevCurrString = NSLocalizedString("Your bill was %@. You used an average of %@ %@ per day.", comment: "")
            if selectionStates[0].value { // No data
                return NSLocalizedString("Not enough data available.", comment: "")
            } else if selectionStates[1].value { // Previous
                let daysInBillPeriod = abs(billComparison.compared!.startDate.interval(ofComponent: .day, fromDate: billComparison.compared!.endDate))
                let avgUsagePerDay = billComparison.compared!.usage / Double(daysInBillPeriod)
                return String(format: localizedPrevCurrString, billComparison.compared!.charges.currencyString!, String(format: "%.1f", avgUsagePerDay), billComparison.meterUnit)
            } else if selectionStates[2].value { // Current
                let daysInBillPeriod = abs(billComparison.reference!.startDate.interval(ofComponent: .day, fromDate: billComparison.reference!.endDate))
                let avgUsagePerDay = billComparison.reference!.usage / Double(daysInBillPeriod)
                return String(format: localizedPrevCurrString, billComparison.reference!.charges.currencyString!, String(format: "%.1f", avgUsagePerDay), billComparison.meterUnit)
            } else if selectionStates[3].value { // Projected
                
            } else if selectionStates[4].value { // Projection Not Available
                return NSLocalizedString("Data becomes available once you are more than 7 days into the billing cycle.", comment: "")
            }
            return nil
        }
    
    // MARK: Likely Reasons Drivers
    
    private(set) lazy var likelyReasonsLabelText: Driver<String?> =
        Driver.combineLatest(self.currentBillComparison.asDriver(), self.lastYearPreviousBillSelectedSegmentIndex.asDriver()) { [weak self] currentBillComparison, segmentIndex in
            guard let `self` = self else { return nil }
            guard let reference = currentBillComparison?.reference, let compared = currentBillComparison?.compared else {
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
        Driver.combineLatest(self.currentBillComparison.asDriver(), self.likelyReasonsSelectionStates.asDriver()) { [weak self] currentBillComparison, selectionStates in
            guard let `self` = self else { return nil }
            guard let billComparison = currentBillComparison else { return nil }
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
    
    private var gasOrElectricString: String {
        var gas = false // Default to electric
        if accountDetail.serviceType!.uppercased() == "GAS" { // If account is gas only
            gas = true
        } else if shouldShowElectricGasToggle { // Use value of segmented control
            gas = electricGasSelectedSegmentIndex.value == 1
        }
        return gas ? NSLocalizedString("gas", comment: "") : NSLocalizedString("electric", comment: "")
    }
    
    private var gasOrElectricityString: String {
        var gas = false // Default to electric
        if accountDetail.serviceType!.uppercased() == "GAS" { // If account is gas only
            gas = true
        } else if shouldShowElectricGasToggle { // Use value of segmented control
            gas = electricGasSelectedSegmentIndex.value == 1
        }
        return gas ? NSLocalizedString("gas", comment: "") : NSLocalizedString("electricity", comment: "")
    }
}
