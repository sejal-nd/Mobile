//
//  OutageAuthenticationViewModel.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 1/18/24.
//  Copyright © 2024 Exelon Corporation. All rights reserved.
//

import SwiftUI
//import EUDesignSystem

extension OutageAuthenticationView {
    class ViewModel: ObservableObject {
        @Published var phoneNumber: String = ""
        @Published var accountNumber: String = ""
    }
}
