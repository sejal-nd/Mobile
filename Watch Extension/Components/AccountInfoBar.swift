//
//  AccountInfoBar.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct AccountInfoBar: View {
    let accountID: String
    var body: some View {
        HStack {
            Spacer()
            Label(accountID,
                  systemImage: "house.fill")
            Spacer()
        }
        .padding(.bottom, 8)
    }
}

struct AccountInfoBar_Previews: PreviewProvider {
    static var previews: some View {
        AccountInfoBar(accountID: "0453257831")
    }
}
