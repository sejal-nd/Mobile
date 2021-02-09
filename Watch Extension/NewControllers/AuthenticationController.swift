//
//  AuthenticationController.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

class AuthenticationController: ObservableObject {
    @Published var isLoggedIn = false
    var authToken: String?
    
    init() {
        authToken = KeychainManager.shared[keychainKeys.authToken]
        isLoggedIn = authToken != nil
    }
}
