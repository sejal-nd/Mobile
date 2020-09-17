//
//  EnergyWiseRewardsViewModel.swift
//  Mobile
//
//  Created by Majumdar, Amit on 17/09/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

final class EnergyWiseRewardsViewModel {
    
    let accountDetail: AccountDetail
    var opcoType: OpCo?
    
    init(accountDetail: AccountDetail) {
        self.accountDetail = accountDetail
        if let opco = accountDetail.opcoType {
            opcoType = opco
        }
    }

    var energyWiseRewardsInformation: String {
        switch opcoType {
        case .ace:
            return "Due to changes in the federal and regional requirements that govern programs like Energy Wise Rewards™, the program will be discontinued effective May 31, 2020. Enrollment for Energy Wise Rewards™ is now closed. Your program device can remain at your home. If you have a web-programmable thermostat, you can continue to use it normally, including programming it to fit your needs to save up to 10 percent annually on heating and cooling your home. Thank you for participating in Energy Wise Rewards™. For information on other programs to help save money and energy, visit atlanticcityelectric.com/waystosave."
        case .pepco, .delmarva:
            let url = opcoType == .pepco ? "energywiserewards.pepco.com" : "energywiserewards.delmarva.com"
            return NSLocalizedString(String(format: "Energy Wise Rewards works by cycling your central air conditioner or heat pump over short intervals (conservation periods) on selected summer days (called Peak Savings Days). To access your Energy Wise Rewards or enroll, please visit %@.", url), comment: "")
        default:
            return ""
        }
    }
}
