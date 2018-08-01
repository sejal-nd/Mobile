//
//  SmartEnergyRewardsVCViewModel.swift
//  Mobile
//
//  Created by Sam Francis on 10/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class SmartEnergyRewardsVCViewModel {
    
    let disposeBag = DisposeBag()
    
    let accountDetail: AccountDetail
    
    required init(accountDetail: AccountDetail) {
        self.accountDetail = accountDetail
    }
    
    var shouldShowSmartEnergyRewards: Bool {
        if Environment.shared.opco != .peco {
            return accountDetail.isSERAccount || accountDetail.isPTSAccount
        }
        return false
    }
    
    var shouldShowSmartEnergyRewardsContent: Bool {
        let events = accountDetail.serInfo.eventResults
        return events.count > 0
    }
    
    var smartEnergyRewardsSeasonLabelText: String? {
        let events = accountDetail.serInfo.eventResults
        if let mostRecentEvent = events.last {
            let latestEventYear = Calendar.opCo.component(.year, from: mostRecentEvent.eventStart)
            return String(format: NSLocalizedString("Summer %d", comment: ""), latestEventYear)
        }
        return nil
    }
    
    var smartEnergyRewardsFooterText: String {
        if accountDetail.serInfo.eventResults.count > 0 {
            return NSLocalizedString("You earn bill credits for every kWh you save. We calculate how much you save by comparing the energy you use on an Energy Savings Day to your typical use.", comment: "")
        }
        
        let programName = Environment.shared.opco == .comEd ? NSLocalizedString("Peak Time Savings", comment: "") : NSLocalizedString("Smart Energy Rewards", comment: "")
        return NSLocalizedString("As a \(programName) customer, you can earn bill credits for every kWh you save. We calculate how much you save by comparing the energy you use on an Energy Savings Day to your typical use. Your savings information for the most recent \(programName) season will display here once available.", comment: "")
    }
    
}
