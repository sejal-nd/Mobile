//
//  WatchApp.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

@main
struct WatchApp: App {
    @StateObject private var authenticationController = AuthenticationController()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                WatchFlowContainer()
                    .environmentObject(authenticationController)
            }
            .onAppear(perform: appStartup)
        }
    }
    
    private func appStartup() {
        //        Log.info("NOTICE: Apple Watch App Did Finish Launching.")
        //
        //        WatchSessionManager.shared.start()
    }
}
