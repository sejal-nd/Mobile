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
    
    func fetchBillComparison() {
        isFetching.value = true
        isError.value = false
        
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
        
        currentFetchDisposable =
            usageService.fetchBillComparison(accountNumber: accountDetail.accountNumber,
                                             premiseNumber: accountDetail.premiseNumber!,
                                             billDate: accountDetail.billingInfo.billDate!,
                                             yearAgo: lastYearPreviousBillSelectedSegmentIndex.value == 0,
                                             gas: gas)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] billComparison in
                self?.isFetching.value = false
                self?.currentBillComparison.value = billComparison
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
        guard let billComparison = $0 else { return 0 }
        let currentCharges = billComparison.reference.charges
        let prevCharges = billComparison.compared.charges
        if prevCharges >= currentCharges {
            return 134
        } else {
            return CGFloat(134.0 * (prevCharges / currentCharges))
        }
    }
    
    private(set) lazy var previousBarDollarLabelText: Driver<String?> = self.currentBillComparison.asDriver().map {
        guard let billComparison = $0 else { return nil }
        return billComparison.compared.charges.currencyString
    }
    
    private(set) lazy var previousBarDateLabelText: Driver<String?> =
        Driver.combineLatest(self.currentBillComparison.asDriver(), self.lastYearPreviousBillSelectedSegmentIndex.asDriver()) {
            guard let billComparison = $0 else { return nil }
            if $1 == 0 { // Last Year
                return "\(Calendar.opCoTime.component(.year, from: billComparison.compared.endDate))"
            } else { // Previous Bill
                return billComparison.compared.endDate.shortMonthAndDayString.uppercased()
            }
        }
    
    // MARK: Current Bar Drivers
    
    private(set) lazy var currentBarHeightConstraintValue: Driver<CGFloat> = self.currentBillComparison.asDriver().map {
        guard let billComparison = $0 else { return 0 }
        let currentCharges = billComparison.reference.charges
        let prevCharges = billComparison.compared.charges
        if currentCharges >= prevCharges {
            return 134
        } else {
            return CGFloat(134.0 * (currentCharges / prevCharges))
        }
    }
    
    private(set) lazy var currentBarDollarLabelText: Driver<String?> = self.currentBillComparison.asDriver().map {
        guard let billComparison = $0 else { return nil }
        return billComparison.reference.charges.currencyString
    }
    
    private(set) lazy var currentBarDateLabelText: Driver<String?> =
        Driver.combineLatest(self.currentBillComparison.asDriver(), self.lastYearPreviousBillSelectedSegmentIndex.asDriver()) {
            guard let billComparison = $0 else { return nil }
            if $1 == 0 { // Last Year
                return "\(Calendar.opCoTime.component(.year, from: billComparison.reference.endDate))"
            } else { // Previous Bill
                return billComparison.reference.endDate.shortMonthAndDayString.uppercased()
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
                return "\(billComparison.compared.startDate.shortMonthDayAndYearString) - \(billComparison.compared.endDate.shortMonthDayAndYearString)"
            } else if selectionStates[2].value { // Current
                return "\(billComparison.reference.startDate.shortMonthDayAndYearString) - \(billComparison.reference.endDate.shortMonthDayAndYearString)"
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
                return String(format: localizedString, Int(billComparison.compared.averageTemperature.rounded()))
            } else if selectionStates[2].value { // Current
                return String(format: localizedString, Int(billComparison.reference.averageTemperature.rounded()))
            }
            return nil
        }
    
    private(set) lazy var barDescriptionDetailLabelText: Driver<String?> =
        Driver.combineLatest(self.currentBillComparison.asDriver(), self.barGraphSelectionStates.asDriver()) { currentBillComparison, selectionStates in
            guard let billComparison = currentBillComparison else { return nil }
            let localizedPrevCurrString = NSLocalizedString("Your bill was %@. You used an average of %d %@ per day.", comment: "")
            if selectionStates[0].value { // No data
                return NSLocalizedString("Not enough data available.", comment: "")
            } else if selectionStates[1].value { // Previous
                let daysInBillPeriod = abs(billComparison.compared.startDate.interval(ofComponent: .day, fromDate: billComparison.compared.endDate))
                let avgUsagePerDay = billComparison.compared.usage / Double(daysInBillPeriod)
                return String(format: localizedPrevCurrString, billComparison.compared.charges.currencyString!, Int(avgUsagePerDay), billComparison.meterUnit)
            } else if selectionStates[2].value { // Current
                let daysInBillPeriod = abs(billComparison.reference.startDate.interval(ofComponent: .day, fromDate: billComparison.reference.endDate))
                let avgUsagePerDay = billComparison.reference.usage / Double(daysInBillPeriod)
                return String(format: localizedPrevCurrString, billComparison.reference.charges.currencyString!, Int(avgUsagePerDay), billComparison.meterUnit)
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
            guard let billComparison = currentBillComparison else { return nil }
            let currentCharges = billComparison.reference.charges
            let prevCharges = billComparison.compared.charges
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
    
    private(set) lazy var billPeriodDollarLabelText: Driver<String?> = self.currentBillComparison.asDriver().map {
        guard let billComparison = $0 else { return nil }
        return billComparison.billPeriodCostDifference.currencyString
    }
    
    private(set) lazy var weatherDollarLabelText: Driver<String?> = self.currentBillComparison.asDriver().map {
        guard let billComparison = $0 else { return nil }
        return billComparison.weatherCostDifference.currencyString
    }
    
    private(set) lazy var otherDollarLabelText: Driver<String?> = self.currentBillComparison.asDriver().map {
        guard let billComparison = $0 else { return nil }
        return billComparison.otherCostDifference.currencyString
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
}
