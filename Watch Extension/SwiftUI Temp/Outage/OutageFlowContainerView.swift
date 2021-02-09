//
//  OutageFlowContainerView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct OutageFlowContainerView: View {
    @State private var outageState: OutageState = .loaded
    @State private var errorState: ErrorState? = nil
    
    @State private var isPresented = false
    
    var body: some View {
        Group {
            if let errorState = errorState {
                ErrorContainerView(errorState: errorState)
            } else {
                OutageContainerView(outageState: outageState)
                    .sheet(isPresented: $isPresented,
                           content: reportOutageContent)
                    .onTapGesture {
                        isPresented.toggle()
                    }
            }
        }
        .navigationTitle("Outage")
    }
    
    @ViewBuilder
    private func reportOutageContent() -> some View {
        ReportOutageView()
    }
}

struct OutageFlowContainerView_Previews: PreviewProvider {
    static var previews: some View {
        OutageFlowContainerView()
    }
}
