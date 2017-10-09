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
    let barGraphSelectionStates = [Variable(false), Variable(false), Variable(false), Variable(false), Variable(false)]
    
    /*
     * 0 = Bill Period
     * 1 = Weather
     * 2 = Other
     */
    let likelyReasonsSelectionStates = [Variable(true), Variable(false), Variable(false)]
    
    private var currentFetchDisposable: Disposable?
    let isFetching = Variable(false)
    let isError = Variable(false)
    
    let electricGasSelectedSegmentIndex = Variable(0)
    let lastYearPreviousBillSelectedSegmentIndex = Variable(1)
    
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
        
        let yearAgo = lastYearPreviousBillSelectedSegmentIndex.value == 0
        
        print("Request for yearAgo = \(yearAgo): START")
        currentFetchDisposable =
            usageService.fetchBillComparison(accountNumber: accountDetail.accountNumber,
                                             premiseNumber: accountDetail.premiseNumber!,
                                             billDate: accountDetail.billingInfo.billDate!,
                                             yearAgo: lastYearPreviousBillSelectedSegmentIndex.value == 0,
                                             gas: gas)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] billComparison in
                self?.isFetching.value = false
                print("Request for yearAgo = \(yearAgo): COMPLETE")
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
    
    func setBarSelected(tag: Int) {
        for i in stride(from: 0, to: barGraphSelectionStates.count, by: 1) {
            let boolVar = barGraphSelectionStates[i]
            boolVar.value = i == tag
        }
    }
    
    func setLikelyReasonSelected(tag: Int) {
        for i in stride(from: 0, to: likelyReasonsSelectionStates.count, by: 1) {
            let boolVar = likelyReasonsSelectionStates[i]
            boolVar.value = i == tag
        }
    }
    
}
