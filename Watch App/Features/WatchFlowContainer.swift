//
//  WatchFlowContainer.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct WatchFlowContainer: View {
    @EnvironmentObject private var networkController: NetworkController
    
    @SceneStorage("selectedTab") private var selectedTab: Tab = .outage
    
    var body: some View {
        if networkController.isLoggedIn {
            TabView(selection: $selectedTab) {
                AccountListFlowContainerView(state: networkController.accountListState)
                    .tag(Tab.accountList)
                
                OutageFlowContainerView(state: networkController.outageState)
                    .tag(Tab.outage)
                
                UsageFlowContainerView(state: networkController.usageState)
                    .tag(Tab.usage)
                
                BillFlowContainerView(state: networkController.billingState)
                    .tag(Tab.bill)
            }
        } else {
            SignInView()
        }
    }
}

struct WatchFlowContainer_Previews: PreviewProvider {
    static var previews: some View {
        WatchFlowContainer()
    }
}
