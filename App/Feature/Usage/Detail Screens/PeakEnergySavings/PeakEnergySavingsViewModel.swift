//
//  PeakEnergySavingsViewModel.swift
//  Mobile
//
//  Created by Majumdar, Amit on 25/09/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

final class PeakEnergySavingsViewModel {
    
    let accountDetail: AccountDetail
    var subOpco: SubOpCo?
    
    init(accountDetail: AccountDetail) {
        self.accountDetail = accountDetail
        if let opco = accountDetail.subOpco {
            subOpco = opco
        }
    }
}
