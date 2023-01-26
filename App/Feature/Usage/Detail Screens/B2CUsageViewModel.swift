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
    
    let accountDetail = BehaviorRelay<AccountDetail?>(value: nil)
    let accessToken = BehaviorRelay<String?>(value: nil)
    let isLoading = BehaviorRelay<Bool>(value: false)
    let isError = BehaviorRelay<Bool>(value: false)
    var widget: AgentisWidget = .usage
    
    let selectedCommercialIndex = BehaviorRelay(value: 0)
    let commercialWidgets = BehaviorRelay<[AgentisWidget]>(value: [])
    
    var webViewRequest: URLRequest? {
        let oPowerWidgetURL = Configuration.shared.getSecureOpCoOpowerURLString(accountDetail.value?.opcoType ?? Configuration.shared.opco)
        if let url = URL(string: oPowerWidgetURL),
           let token = accessToken.value {
            var request = NSURLRequest(url: url) as URLRequest
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue(token, forHTTPHeaderField: "accessToken")
            request.addValue(widget.identifier, forHTTPHeaderField: "opowerWidgetId")
            request.addValue(accountDetail.value?.utilityCode ?? Configuration.shared.opco.rawValue, forHTTPHeaderField: "opco")
            request.addValue(accountDetail.value?.state ?? "MD", forHTTPHeaderField: "state")
            request.addValue("\(accountDetail.value?.isResidential == false)", forHTTPHeaderField: "isCommercial")
            
            // IMPORTANT - adding "accountNumber" header breaks the residential widgets
            if accountDetail.value?.isResidential == false {
                request.addValue(accountDetail.value?.accountNumber ?? "", forHTTPHeaderField: "accountNumber")
            }

            return request
        } else {
            return nil
        }
    }
    
    func fetchJWT() {
        
        isLoading.accept(true)
        
        let accountNumber = accountDetail.value?.accountNumber ?? ""
        var nonce = accountNumber
        
        if accountDetail.value?.isResidential == false {
            nonce = "NR-\(accountNumber)"
        }
        let request = B2CTokenRequest(scope: "https://\(Configuration.shared.b2cTenant).onmicrosoft.com/opower/opower_connect",
                                   nonce: nonce,
                                   grantType: "refresh_token",
                                   responseType: "token",
                                   refreshToken: UserSession.refreshToken)
        UsageService.fetchOpowerToken(request: request) { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading.accept(false)
            
            switch result {
            case .success(let tokenResponse):
                self.accessToken.accept(tokenResponse.token ?? "")
            case .failure:
                self.isError.accept(true)
            }
        }
    }
    
    func refreshCommercialWidgets() {
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
        
        self.commercialWidgets.accept(widgets)
        self.selectedCommercialIndex.accept(0)
        self.widget = selectedCommercialWidget()
    }
    
    func selectedCommercialWidget() -> AgentisWidget {
        return commercialWidgets.value[selectedCommercialIndex.value]
    }
    
    var isGasAccount: Bool {
        return accountDetail.value?.serviceType?.uppercased().contains("GAS")  ?? false
    }
    
    var isElectricAccount: Bool {
        return accountDetail.value?.serviceType?.uppercased().contains("ELECTRIC") ?? false
    }
}
