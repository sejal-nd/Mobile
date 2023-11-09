//
//  AccountInfoBar.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct AccountInfoBar: View {
    let account: WatchAccount
    
    private var imageName: String {
        account.isResidential ? "house.fill" : "building.2.fill"
    }

    var body: some View {
        HStack {
            Spacer()
            Label(account.accountID,
                  systemImage: imageName)
            Spacer()
        }
        .padding(.bottom, 8)
    }
}

struct AccountInfoBar_Previews: PreviewProvider {
    static var previews: some View {
        AccountInfoBar(account: PreviewData.accountDefault)
    }
}
