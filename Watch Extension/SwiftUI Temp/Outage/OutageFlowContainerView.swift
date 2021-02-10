//
//  OutageFlowContainerView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct OutageFlowContainerView: View {
    @State private var state: OutageState = .loading
    @State private var isPresented = false
    
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
                ImageTextView(imageName: AppImage.gas.name,
                              text: "Outage reporting for gas only accounts is not allowed online.")
                }
            case .unavailable(let account):
                VStack(spacing: 0) {
                    AccountInfoBar(accountID: account.accountID)
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
        OutageFlowContainerView()
    }
}
