//
//  UsageContainerView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct UsageContainerView: View {
    let usageState: UsageState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AccountInfoBar(accountID: "234783242")
                
                switch usageState {
                case .loading, .loaded:
                    UsageView(usageState: usageState)
                case .unavailable:
                    ImageTextView(imageName: AppImage.usage.name,
                                  text: "Usage is not available for this account")
                }
            }
        }
    }
}

struct UsageContainerView_Previews: PreviewProvider {
    static var previews: some View {
        UsageContainerView(usageState: .loaded)
    }
}
