//
//  Top5EnergyTipsViewModel.swift
//  Mobile
//
//  Created by Sam Francis on 10/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class Top5EnergyTipsViewModel {
    
    private let usageService: UsageService
    
    let energyTips: Observable<[EnergyTip]>
    
    init(usageService: UsageService, accountDetail: AccountDetail) {
        self.usageService = usageService
        
        energyTips = usageService
            .fetchEnergyTips(accountNumber: accountDetail.accountNumber, premiseNumber: accountDetail.premiseNumber!)
            .map { Array($0.prefix(5)) }
    }
    
}
