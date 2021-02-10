//
//  AccountRow.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct AccountRow: View {
    let account: WatchAccount
    let didSelectAccount: () -> Void
    
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
}

struct AccountRow_Previews: PreviewProvider {
    static var previews: some View {
        // Residential, short address
        AccountRow(account: PreviewData.accounts[0],
                   didSelectAccount: { })
        
        // Commercial, long address
        AccountRow(account: PreviewData.accounts[1],
                   didSelectAccount: { })
            .previewDevice("Apple Watch Series 6 - 40mm")
        
        // Residential, long address
        AccountRow(account: PreviewData.accounts[2],
                   didSelectAccount: { })
            .previewDevice("Apple Watch Series 6 - 44mm")
    }
}
