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

    var body: some View {
//        if authenticationController.isLoggedIn {
            TabView {
                OutageFlowContainerView()
                
                UsageFlowContainerView()
                
                BillFlowContainerView()
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
