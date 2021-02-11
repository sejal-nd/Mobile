//
//  OutageFlowContainerView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct OutageFlowContainerView: View {
    
    #warning("this will come from controller")
    @State private var isPresented = false
    
    var state: OutageState = .loading

    var body: some View {
        Group {
            switch state {
            case .loading:
                OutageContainerView(outage: PreviewData.outageOn,
                                    account: PreviewData.accounts[0],
                                    isLoading: true)
                    .redacted(reason: .placeholder)
            case .loaded(let outage, let account):
                VStack(spacing: 0) {
                    AccountInfoBar(accountID: account.accountID)
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
                    AccountInfoBar(accountID: account.accountID)
                    #warning("image sizes are not correct right now.")
                    ImageTextView(imageName: AppImage.gas.name,
                                  text: "Outage reporting for gas only accounts is not allowed online.")
                }
            case .unavailable(let account):
                VStack(spacing: 0) {
                    AccountInfoBar(accountID: account.accountID)
                    #warning("image sizes are not correct right now.")
                    ImageTextView(imageName: AppImage.outageUnavailable.name,
                                  text: "Outage Status and Reporting are not available for this account.")
                }
            case .error(let errorState):
                ErrorContainerView(errorState: errorState)
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
        OutageFlowContainerView(state: .loading)
        
        OutageFlowContainerView(state: .loaded(outage: PreviewData.outageOn,
                                               acccount: PreviewData.accounts[0]))
        
        OutageFlowContainerView(state: .loaded(outage: PreviewData.outageOff,
                                               acccount: PreviewData.accounts[1]))
        
        OutageFlowContainerView(state: .gasOnly(acccount: PreviewData.accounts[0]))
        
        OutageFlowContainerView(state: .unavailable(acccount: PreviewData.accounts[0]))
        
        OutageFlowContainerView(state: .error(errorState: .maintenanceMode))
        
        OutageFlowContainerView(state: .error(errorState: .passwordProtected))
        
        OutageFlowContainerView(state: .error(errorState: .other))
    }
}
