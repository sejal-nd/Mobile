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
                AccountRow(account: account) {
                    didSelectAccount(account)
                }
            }
        }
    }
    
    private func didSelectAccount(_ account: WatchAccount) {
        AccountsStore.shared.currentIndex = accounts.firstIndex(of: account) ?? 0
        
        #warning("todo, trigger network requests similar to app init")
        //        NotificationCenter.default.post(name: .currentAccountUpdated, object: AccountsStore.shared.currentAccount)
    }
}

struct AccountList_Previews: PreviewProvider {
    static var previews: some View {
        AccountList(accounts: PreviewData.accounts)
    }
}
