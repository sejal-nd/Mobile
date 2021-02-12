//
//  OutageFlowContainerView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct OutageFlowContainerView: View {
    @State private var isPresented = false
    
    var state: OutageState = .loading
    
    var body: some View {
        Group {
            switch state {
            case .loading:
                VStack(spacing: 0) {
                    AccountInfoBar(account: PreviewData.accounts[0])
                    OutageContainerView(outage: PreviewData.outageOn,
                                        account: PreviewData.accounts[0],
                                        isLoading: true)
                }
                .redacted(reason: .placeholder)
            case .loaded(let outage, let account):
                VStack(spacing: 0) {
                    AccountInfoBar(account: account)
                    OutageContainerView(outage: outage,
                                        account: account,
                                        isLoading: false)
                        .sheet(isPresented: $isPresented,
                               content: reportOutageContent)
                        .onTapGesture {
                            isPresented.toggle()
                        }
                }
            case .gasOnly(let account):
                VStack(spacing: 0) {
                    AccountInfoBar(account: account)
                    #warning("image sizes are not correct right now.")
                    ImageTextView(imageName: AppImage.gas.name,
                                  text: "Outage reporting for gas only accounts is not allowed online.")
                }
            case .unavailable(let account):
                VStack(spacing: 0) {
                    AccountInfoBar(account: account)
                    #warning("image sizes are not correct right now.")
                    ImageTextView(imageName: AppImage.outageUnavailable.name,
                                  text: "Outage Status and Reporting are not available for this account.")
                }
            case .error(let errorState):
                ErrorContainerView(errorState: errorState)
            }
        }
        .navigationTitle("Outage")
        .onAppear(perform: logAnalytics)
    }
    
    private func logAnalytics() {
        AnalyticController.logScreenView(.outage)
    }
    
    @ViewBuilder
    private func reportOutageContent() -> some View {
        ReportOutageView()
    }
}

struct OutageFlowContainerView_Previews: PreviewProvider {
    static var previews: some View {
        OutageFlowContainerView(state: .loading)
        
        OutageFlowContainerView(state: .loaded(outage: PreviewData.outageOn,
                                               account: PreviewData.accounts[0]))
        
        OutageFlowContainerView(state: .loaded(outage: PreviewData.outageOff,
                                               account: PreviewData.accounts[1]))
        
        OutageFlowContainerView(state: .gasOnly(account: PreviewData.accounts[0]))
        
        OutageFlowContainerView(state: .unavailable(account: PreviewData.accounts[0]))
        
        OutageFlowContainerView(state: .error(errorState: .maintenanceMode))
        
        OutageFlowContainerView(state: .error(errorState: .passwordProtected))
        
        OutageFlowContainerView(state: .error(errorState: .other))
    }
}
