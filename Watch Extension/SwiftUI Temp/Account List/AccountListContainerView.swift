//
//  AccountListContainerView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct AccountListContainerView: View {
    var body: some View {
        AccountList(accounts: [])
            .navigationTitle("Accounts")
    }
}

struct AccountListContainerView_Previews: PreviewProvider {
    static var previews: some View {
        AccountListContainerView()
    }
}
