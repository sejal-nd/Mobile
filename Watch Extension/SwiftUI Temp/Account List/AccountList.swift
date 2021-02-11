//
//  AccountList.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct AccountList: View {
    let accounts: [WatchAccount]
    
    var body: some View {
        List {
            ForEach(accounts) { account in
                AccountRow(accounts: accounts,
                           account: account)
            }
        }
    }
}

struct AccountList_Previews: PreviewProvider {
    static var previews: some View {
        AccountList(accounts: PreviewData.accounts)
    }
}
