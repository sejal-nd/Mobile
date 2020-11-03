//
//  Top5EnergyTipsViewModel.swift
//  Mobile
//
//  Created by Sam Francis on 10/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class Top5EnergyTipsViewModel {
    
    
    var energyTips: Observable<[EnergyTip]>
    
    init(accountDetail: AccountDetail) {
        energyTips = UsageService.rx
            .fetchEnergyTips(accountNumber: accountDetail.accountNumber, premiseNumber: accountDetail.premiseNumber!)
            .map { Array($0).filter { !$0.title.isEmpty && !($0.body?.isEmpty ?? true) } }
            .map { Array($0.prefix(5)) }
    }
    
}
