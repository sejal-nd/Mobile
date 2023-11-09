//
//  WatchAppDelegate.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 8/3/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

class WachAppDelegate: ObservableObject {
    init() {        
        WatchSessionController.shared.start()

        // Send jwt to phone if available
        guard AuthenticationService.isLoggedIn() else { return }
        UserSession.sendSessionToDevice()
    }
}
