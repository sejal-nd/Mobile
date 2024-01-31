//
//  OutageAuthenticationView.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 1/18/24.
//  Copyright © 2024 Exelon Corporation. All rights reserved.
//

import SwiftUI
import EUDesignSystem

struct OutageAuthenticationView: View {
    @StateObject private var viewModel = ViewModel()
        
    var body: some View {
        ScrollView {
            VStack {
                Text("Please help us validate your account.")
                MaterialTextField(text: $viewModel.phoneNumber, placeholder: "Primary Phone Number*")
                
                // Divider
                HStack {
                    VStack {
                        Divider()
                    }
                    Text("OR")
                    VStack {
                        Divider()
                    }
                }
                
                MaterialTextField(text: $viewModel.accountNumber, placeholder: "Account Number*")
                
                // TODO: Make this a component - ContaactFooterView
                Divider()
                Text("If you small...")
                Text("For downed or sparking power lines...")
                
            }
        }
        .navigationTitle("Outage")
    }
}
