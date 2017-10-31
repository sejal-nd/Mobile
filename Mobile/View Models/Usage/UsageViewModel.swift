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
    
    var shouldShowSmartEnergyRewards: Bool {
        if Environment.sharedInstance.opco != .peco {
            return accountDetail.isSERAccount || accountDetail.isPTSAccount
        }
        return false
    }
    
    var shouldShowSmartEnergyRewardsContent: Bool {
        let events = accountDetail.SERInfo.eventResults
        return events.count > 0
    }
    
    var smartEnergyRewardsSeasonLabelText: String? {
        let events = accountDetail.SERInfo.eventResults
        if let mostRecentEvent = events.last {
            let latestEventYear = Calendar.opCo.component(.year, from: mostRecentEvent.eventStart)
            return String(format: NSLocalizedString("Summer %d", comment: ""), latestEventYear)
        }
        return nil
    }
    
}
