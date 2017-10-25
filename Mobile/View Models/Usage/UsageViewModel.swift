//
//  UsageViewModel.swift
//  Mobile
//
//  Created by Sam Francis on 10/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class UsageViewModel {
    
    let disposeBag = DisposeBag()
    
    let accountDetail: AccountDetail
    
    required init(accountDetail: AccountDetail) {
        self.accountDetail = accountDetail
    }
    
    var smartEnergyRewardsSeasonLabelText: String? {
        let events = accountDetail.SERInfo.eventResults
        if let mostRecentEvent = events.last {
            let latestEventYear = Calendar.opCoTime.component(.year, from: mostRecentEvent.eventStart)
            return "Summer \(latestEventYear)"
        }
        return nil
    }
    
}
