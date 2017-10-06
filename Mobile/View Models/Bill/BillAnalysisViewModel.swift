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
    
}
