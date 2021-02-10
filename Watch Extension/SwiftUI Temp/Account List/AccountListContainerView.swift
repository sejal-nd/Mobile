//
//  AccountListContainerView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct AccountListContainerView: View {
    let accounts: [WatchAccount]
    
    var body: some View {
        AccountList(accounts: accounts)
    }
}

struct AccountListContainerView_Previews: PreviewProvider {
    static var previews: some View {
        AccountListContainerView(accounts: PreviewData.accounts)
    }
}
