//
//  UsageFlowContainerView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct UsageFlowContainerView: View {
    @State private var usageState: UsageState = .loading
    @State private var watchUsage: WatchUsage?
    @State private var errorState: ErrorState?
    
    var body: some View {
        VStack {
            if let errorState = errorState {
                ErrorContainerView(errorState: errorState)
            } else {
                UsageContainerView(usageState: usageState,
                                   watchUsage: watchUsage)
                    .redacted(reason: usageState == .loading ? .placeholder : [])
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
