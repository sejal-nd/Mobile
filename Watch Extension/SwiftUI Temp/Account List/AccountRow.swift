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
    
    private var imageName: String {
        account.isResidential ? "house.fill" : "building.2.fill"
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: imageName)
            VStack(alignment: .leading,
                   spacing: 4) {
                Text(account.accountID)
                Text(account.address)
                    .lineLimit(1)
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
                   account: PreviewData.accounts[0])
        
        // Commercial, long address
        AccountRow(accounts: PreviewData.accounts,
                   account: PreviewData.accounts[1])
            .previewDevice("Apple Watch Series 6 - 40mm")
        
        // Residential, long address
        AccountRow(accounts: PreviewData.accounts,
                   account: PreviewData.accounts[2])
            .previewDevice("Apple Watch Series 6 - 44mm")
    }
}
