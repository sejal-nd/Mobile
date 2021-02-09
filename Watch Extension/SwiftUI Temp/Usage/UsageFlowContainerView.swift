//
//  UsageFlowContainerView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct UsageFlowContainerView: View {
    @State private var usageState: UsageState = .loaded
    @State private var errorState: ErrorState? = nil
    
    var body: some View {
        Group {
            if let errorState = errorState {
                ErrorContainerView(errorState: errorState)
            } else {
                UsageContainerView(usageState: usageState)
            }
        }
        .navigationTitle("Usage")
    }
}

struct UsageFlowContainerView_Previews: PreviewProvider {
    static var previews: some View {
        UsageFlowContainerView()
    }
}
