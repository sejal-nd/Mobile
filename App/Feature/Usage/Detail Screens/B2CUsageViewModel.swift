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
    
    var accountDetail = BehaviorRelay<AccountDetail?>(value: nil)
    var accessToken: String?
    var widget: AgentisWidget = .usage
    
    let selectedCommercialIndex = BehaviorRelay(value: 0)
    
    var commercialWidgets: [AgentisWidget] {
        
        var widgets: [AgentisWidget] = []
        
        if isElectricAccount && FeatureFlagUtility.shared.bool(forKey: .isAgentisElectricUsageWidget) {
            widgets.append(.electricUsage)
        }
        
        if isGasAccount && FeatureFlagUtility.shared.bool(forKey: .isAgentisGasUsageWidget) {
            widgets.append(.gasUsage)
        }
        
        if isElectricAccount && FeatureFlagUtility.shared.bool(forKey: .isAgentisElectricCompareBillsWidget) {
            widgets.append(.compareElectric)
        }
        
        if isGasAccount && FeatureFlagUtility.shared.bool(forKey: .isAgentisGasCompareBillsWidget) {
            widgets.append(.compareGas)
        }
        
        if isElectricAccount && FeatureFlagUtility.shared.bool(forKey: .isAgentisElectricTipsWidget) {
            widgets.append(.electricTips)
        }
        
        if isGasAccount && FeatureFlagUtility.shared.bool(forKey: .isAgentisGasTipsWidget) {
            widgets.append(.gasTips)
        }
        
        if FeatureFlagUtility.shared.bool(forKey: .isAgentisProjectedUsageWidget) {
            widgets.append(.projectedUsage)
        }

        return widgets
    }
    
    func selectedCommercialWidget() -> AgentisWidget {
        return commercialWidgets[selectedCommercialIndex.value]
    }
    
    var isGasAccount: Bool {
        return accountDetail.value?.serviceType?.uppercased().contains("GAS")  ?? false
    }
    
    var isElectricAccount: Bool {
        return accountDetail.value?.serviceType?.uppercased().contains("ELECTRIC") ?? false
    }
}
