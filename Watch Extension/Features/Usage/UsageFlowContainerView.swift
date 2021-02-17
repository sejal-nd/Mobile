//
//  UsageFlowContainerView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct UsageFlowContainerView: View {
    var state: UsageState = .loading
    
    var body: some View {
        Group {
            switch state {
            case .loading:
                ScrollView {
                    VStack(spacing: 0) {
                        AccountInfoBar(account: PreviewData.accountDefault)
                        UsageContainerView(usage: PreviewData.usageDefault,
                                           account: PreviewData.accountDefault,
                                           isLoading: true)
                    }
                    .redacted(reason: .placeholder)
                }
            case .loaded(let usage, let account):
                ScrollView {
                    VStack(spacing: 0) {
                        AccountInfoBar(account: account)
                        UsageContainerView(usage: usage,
                                           account: account,
                                           isLoading: false)
                    }
                }
            case .unforecasted(let account, let daysToForecast):
                ScrollView {
                    VStack(spacing: 0) {
                        AccountInfoBar(account: account)
                        ImageTextView(imageName: AppConstant.ImageName.noUsageData.name,
                                      imageColor: .accentColor,
                                      title: "\(daysToForecast) days",
                                      text: "until next forecast")
                    }
                }
            case .unavailable(let account):
                ScrollView {
                    VStack(spacing: 0) {
                        AccountInfoBar(account: account)
                        ImageTextView(imageName: AppConstant.ImageName.noUsageData.name,
                                      imageColor: .accentColor,
                                      text: "Usage is not available for this account")
                    }
                }
            case .error(let errorState):
                ErrorContainerView(errorState: errorState)
            }
        }
        .navigationTitle("Usage")
        .onAppear(perform: logAnalytics)
    }
    
    private func logAnalytics() {
        AnalyticController.logScreenView(.usage)
    }
}

struct UsageFlowContainerView_Previews: PreviewProvider {
    static var previews: some View {
        UsageFlowContainerView(state: .loading)
        
        Group {
            // Electric
            UsageFlowContainerView(state: .loaded(usage: PreviewData.usageElectricModeled,
                                                  account: PreviewData.accounts[0]))
            
            UsageFlowContainerView(state: .loaded(usage: PreviewData.usageElectricUnmodeled,
                                                  account: PreviewData.accounts[0]))
            
            // Gas
            UsageFlowContainerView(state: .loaded(usage: PreviewData.usageGasModeled,
                                                  account: PreviewData.accounts[0]))
            
            UsageFlowContainerView(state: .loaded(usage: PreviewData.usageGasUnmodeled,
                                                  account: PreviewData.accounts[0]))
            
            // Both
            UsageFlowContainerView(state: .loaded(usage: PreviewData.usageGasAndElectricModeled,
                                                  account: PreviewData.accounts[0]))
            
            UsageFlowContainerView(state: .loaded(usage: PreviewData.usageGasAndElectricUnmodeled,
                                                  account: PreviewData.accounts[0]))
        }
        
        UsageFlowContainerView(state: .unforecasted(account: PreviewData.accounts[0],
                                                    days: 5))
        
        UsageFlowContainerView(state: .unavailable(account: PreviewData.accounts[0]))
        
        Group {
            UsageFlowContainerView(state: .error(errorState: .maintenanceMode))
            
            UsageFlowContainerView(state: .error(errorState: .passwordProtected))
            
            UsageFlowContainerView(state: .error(errorState: .other))
        }
    }
}
