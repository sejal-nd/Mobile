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
    
    private var currentAccount: WatchAccount? {
        // Work around since account store does not correctly use optionality
        guard AccountsStore.shared.accounts != nil,
              AccountsStore.shared.currentIndex != nil,
              AccountsStore.shared.currentAccount != nil else { return nil }
        return WatchAccount(account: AccountsStore.shared.currentAccount)
    }
    
    var body: some View {
        List {
            ForEach(accounts) { account in
                AccountRow(accounts: accounts,
                           account: account,
                           currentAccount: currentAccount)
            }
        }
    }
}

struct AccountList_Previews: PreviewProvider {
    static var previews: some View {
        AccountList(accounts: PreviewData.accounts)
    }
}
