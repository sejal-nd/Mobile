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
    
    var billingInfo: BillingInfo! // Passed from BillViewController, used for displaying ComEd pie chart
    var serviceType: String! // Passed from BillViewController, used for displaying Gas/Electric segmented control
    
    let usageService: UsageService

    required init(usageService: UsageService) {
        self.usageService = usageService
    }
    
    var shouldShowElectricGasToggle: Bool {
        if Environment.sharedInstance.opco != .comEd {
            return serviceType.uppercased() == "GAS/ELECTRIC"
        }
        return false
    }
    
    var shouldShowCurrentChargesSection: Bool {
        if Environment.sharedInstance.opco == .comEd {
            let supplyCharges = billingInfo.supplyCharges ?? 0
            let taxesAndFees = billingInfo.taxesAndFees ?? 0
            let deliveryCharges = billingInfo.deliveryCharges ?? 0
            let totalCharges = supplyCharges + taxesAndFees + deliveryCharges
            return totalCharges > 0
        }
        return false
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
