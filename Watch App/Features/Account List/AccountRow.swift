//
//  AccountRow.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct AccountRow: View {
    @EnvironmentObject private var networkController: NetworkController
    
    let accounts: [WatchAccount]
    let account: WatchAccount
    let currentAccount: WatchAccount?
    
    private var imageName: String {
        account.isResidential ? "house.fill" : "building.2.fill"
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let currentAccount = currentAccount,
               account == currentAccount {
                Image(systemName: "checkmark")
            }
            Image(systemName: imageName)
            VStack(alignment: .leading,
                   spacing: 4) {
                Text(account.accountID)
                if !account.address.isEmpty {
                    Text(account.address)
                        .lineLimit(1)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: didSelectAccount)
    }
    
    private func didSelectAccount() {
        // Select new account
        AccountsStore.shared.currentIndex = accounts.firstIndex(of: account) ?? 0
        
        // Fetch new account data
        networkController.fetchFeatureData()
    }
}

struct AccountRow_Previews: PreviewProvider {
    static var previews: some View {
        // Residential, short address
        AccountRow(accounts: PreviewData.accounts,
                   account: PreviewData.accounts[0],
                   currentAccount: PreviewData.accountDefault)
        
        // Commercial, long address
        AccountRow(accounts: PreviewData.accounts,
                   account: PreviewData.accounts[1],
                   currentAccount: PreviewData.accountDefault)
            .previewDevice("Apple Watch Series 6 - 40mm")
        
        // Residential, long address
        AccountRow(accounts: PreviewData.accounts,
                   account: PreviewData.accounts[2],
                   currentAccount: PreviewData.accountDefault)
            .previewDevice("Apple Watch Series 6 - 44mm")
    }
}
