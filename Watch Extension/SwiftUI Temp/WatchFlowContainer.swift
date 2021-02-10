//
//  WatchFlowContainer.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct WatchFlowContainer: View {
    @EnvironmentObject var authenticationController: AuthenticationController
    
    @SceneStorage("selectedTab") private var selectedTab: Tab = .outage
    
    var body: some View {
        //        if authenticationController.isLoggedIn {
        TabView(selection: $selectedTab) {
            AccountListFlowContainerView()
                .tag(Tab.accountList)
            
            OutageFlowContainerView()
                .tag(Tab.outage)
            
            UsageFlowContainerView()
                .tag(Tab.usage)
            
            BillFlowContainerView()
                .tag(Tab.bill)
        }
        
        //        } else {
        //            SignInView()
        //        }
    }
}

struct WatchFlowContainer_Previews: PreviewProvider {
    static var previews: some View {
        WatchFlowContainer()
    }
}
