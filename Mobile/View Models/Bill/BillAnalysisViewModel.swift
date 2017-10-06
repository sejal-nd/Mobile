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

    
    required init(usageService: UsageService) {

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
    
    // MARK: Bill Comparison Bar Graph Drivers
    
    private(set) lazy var noDataLabelFont: Driver<UIFont> = self.barGraphSelectionStates[0].asDriver().map {
        $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline)
    }
    
    private(set) lazy var previousLabelFont: Driver<UIFont> = self.barGraphSelectionStates[1].asDriver().map {
        $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline)
    }
    
    private(set) lazy var currentLabelFont: Driver<UIFont> = self.barGraphSelectionStates[2].asDriver().map {
        $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline)
    }
    
    private(set) lazy var projectedLabelFont: Driver<UIFont> = self.barGraphSelectionStates[3].asDriver().map {
        $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline)
    }
    
    private(set) lazy var projectionNotAvailableLabelFont: Driver<UIFont> = self.barGraphSelectionStates[4].asDriver().map {
        $0 ? OpenSans.bold.of(textStyle: .subheadline) : OpenSans.semibold.of(textStyle: .subheadline)
    }
    
    // MARK: Likely Reasons Drivers
    
    private(set) lazy var billPeriodBorderColor: Driver<CGColor> = self.likelyReasonsSelectionStates[0].asDriver().map {
        $0 ? UIColor.primaryColor.cgColor : UIColor.clear.cgColor
    }
    
    private(set) lazy var weatherBorderColor: Driver<CGColor> = self.likelyReasonsSelectionStates[1].asDriver().map {
        $0 ? UIColor.primaryColor.cgColor : UIColor.clear.cgColor
    }
    
    private(set) lazy var otherBorderColor: Driver<CGColor> = self.likelyReasonsSelectionStates[2].asDriver().map {
        $0 ? UIColor.primaryColor.cgColor : UIColor.clear.cgColor
    }

}
