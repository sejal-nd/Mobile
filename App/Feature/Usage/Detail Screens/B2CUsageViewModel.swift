//
//  B2CUsageViewModel.swift
//  EUMobile
//
//  Created by Cody Dillon on 3/29/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxSwiftExt

class B2CUsageViewModel {
    
    var accountDetail: AccountDetail?
    var accessToken: String?
    var widget: AgentisWidget = .usage
    
    let selectedCommercialIndex = BehaviorRelay(value: 0)
    
    var commercialWidgets: [AgentisWidget] {
        
        var widgets: [AgentisWidget] = []
        
        if FeatureFlagUtility.shared.bool(forKey: .isAgentisUsageWidget) {
            if isElectricAccount {
                widgets.append(.electricUsage)
            }
            if isGasAccount {
                widgets.append(.gasUsage)
            }
        }
        
        if FeatureFlagUtility.shared.bool(forKey: .isAgentisCompareWidget) {
            if isElectricAccount {
                widgets.append(.compareElectric)
            }
            if isGasAccount {
                widgets.append(.compareGas)
            }
        }
        
        if FeatureFlagUtility.shared.bool(forKey: .isAgentisTipsWidget) {
            if isElectricAccount {
                widgets.append(.electricTips)
            }
            if isGasAccount {
                widgets.append(.gasTips)
            }
        }
        
        if FeatureFlagUtility.shared.bool(forKey: .isAgentisProjectedUsageWidget) {
            widgets.append(.projectedUsage)
        }
//        return AgentisWidget.commercialWidgets.filter { widget in
//            if widget == .gasUsage || widget == .compareGas || widget == .gasTips {
//                return accountDetail?.serviceType?.uppercased().contains("GAS")  ?? false
//            } else if widget == .electricUsage || widget == .compareElectric || widget == .electricTips {
//                return accountDetail?.serviceType?.uppercased().contains("ELECTRIC") ?? false
//            } else {
//                return true
//            }
//        }
        return widgets
    }
    
    func selectedCommercialWidget() -> AgentisWidget {
        return commercialWidgets[selectedCommercialIndex.value]
    }
    
    var isGasAccount: Bool {
        return accountDetail?.serviceType?.uppercased().contains("GAS")  ?? false
    }
    
    var isElectricAccount: Bool {
        return accountDetail?.serviceType?.uppercased().contains("ELECTRIC") ?? false
    }
}
