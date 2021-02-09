//
//  OutageContainerView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct OutageContainerView: View {
    let outageState: OutageState
    #warning("image sizes are not correct right now.")
    var body: some View {
//        ScrollView {
            VStack(spacing: 0) {
                AccountInfoBar(accountID: "234783242")
//                Spacer()
                
                switch outageState {
                case .loaded:
                    OutageView(outageState: outageState)
                case .gasOnly:
                    ImageTextView(imageName: AppImage.gas.name,
                                  text: "Outage reporting for gas only accounts is not allowed online.")
                case .unavailable:
                    ImageTextView(imageName: AppImage.outageUnavailable.name,
                                  text: "Outage Status and Reporting are not available for this account.")
                }
                
//                Spacer()
            }
//        }
    }
}

struct OutageContainerView_Previews: PreviewProvider {
    static var previews: some View {
        OutageContainerView(outageState: .loaded)
    }
}
