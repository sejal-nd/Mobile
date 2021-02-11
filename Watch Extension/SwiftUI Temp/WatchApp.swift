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
    @StateObject private var networkController = NetworkController()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                WatchFlowContainer()
                    .environmentObject(networkController)
            }
            .onAppear(perform: appStartup)
        }
    }
    
    private func appStartup() {
        WatchSessionController.shared.start()
    }
}
