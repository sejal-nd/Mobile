//
//  AccountListFlowContainerView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct AccountListFlowContainerView: View {
    @State private var state: AccountListState = .loading
    
    var body: some View {
        Group {
            switch state {
            case .loading:
                AccountListContainerView(accounts: [])
                    .redacted(reason: .placeholder)
            case .loaded(let accounts):
                AccountListContainerView(accounts: accounts)
            case .error(let errorState):
                ErrorContainerView(errorState: errorState)
            }
        }
        .navigationTitle("Accounts")
    }
}

struct AccountListFlowContainerView_Previews: PreviewProvider {
    static var previews: some View {
        AccountListFlowContainerView()
    }
}
