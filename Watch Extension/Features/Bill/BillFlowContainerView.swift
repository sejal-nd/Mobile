//
//  BillFlowContainerView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct BillFlowContainerView: View {
    var state: BillState = .loading
    
    var body: some View {
        Group {
            switch state {
            case .loading:
                ScrollView {
                    VStack(spacing: 0) {
                        AccountInfoBar(account: PreviewData.accounts[0])
                        #warning("todo add preview data when it exists")
//                        BillContainerView(bill: <#T##WatchBill#>,
//                                          account: <#T##WatchAccount#>,
//                                          isLoading: true)
                    }
                    .redacted(reason: .placeholder)
                }
            case .loaded(let bill, let account):
                ScrollView {
                    VStack(spacing: 0) {
                        AccountInfoBar(account: account)
                        BillContainerView(bill: bill,
                                          account: account,
                                          isLoading: false)
                    }
                }
            case .unavailable(let account):
                ScrollView {
                    VStack(spacing: 0) {
                        AccountInfoBar(account: account)
                        #warning("image sizes are not correct right now.")
                        ImageTextView(imageName: AppImage.billNotReady.name,
                                      text: "Bill is not available for this account")
                    }
                }
            case .error(let errorState):
                ErrorContainerView(errorState: errorState)
            }
        }
        .navigationTitle("Bill")
        .onAppear(perform: logAnalytics)
    }
    
    private func logAnalytics() {
        AnalyticController.logScreenView(.bill)
    }
}

struct BillFlowContainerView_Previews: PreviewProvider {
    static var previews: some View {
        BillFlowContainerView()
    }
}
