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
                        AccountInfoBar(account: PreviewData.accountDefault)
                        BillContainerView(bill: PreviewData.billDefault,
                                          account: PreviewData.accountDefault,
                                          isLoading: true)
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
                        ImageTextView(imageName: AppImage.billNotReady.name,
                                      imageColor: .opco,
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
        BillFlowContainerView(state: .loading)
        
        Group {
            BillFlowContainerView(state: .loaded(bill: PreviewData.billStandard,
                                                 account: PreviewData.accounts[0]))
            
            BillFlowContainerView(state: .loaded(bill: PreviewData.billAutoPay,
                                                 account: PreviewData.accounts[0]))
            
            BillFlowContainerView(state: .loaded(bill: PreviewData.billPrecarious,
                                                 account: PreviewData.accounts[0]))

            BillFlowContainerView(state: .loaded(bill: PreviewData.billScheduled,
                                                 account: PreviewData.accounts[0]))
            
            BillFlowContainerView(state: .loaded(bill: PreviewData.billReceived,
                                                 account: PreviewData.accounts[0]))
            
            BillFlowContainerView(state: .loaded(bill: PreviewData.billPendingPayment,
                                                 account: PreviewData.accounts[0]))
        }
        
        BillFlowContainerView(state: .unavailable(account: PreviewData.accounts[0]))
        
        Group {
            BillFlowContainerView(state: .error(errorState: .maintenanceMode))
            
            BillFlowContainerView(state: .error(errorState: .passwordProtected))
            
            BillFlowContainerView(state: .error(errorState: .other))
        }
    }
}
