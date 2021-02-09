//
//  BillContainerView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct BillContainerView: View {
    let billState: BillState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AccountInfoBar(accountID: "234783242")
                
                switch billState {
                case .loaded:
                    BillView(billState: billState)
                case .unavailable:
                    #warning("Todo")
                    ImageTextView(imageName: AppImage.billNotReady.name,
                                  text: "Usage is not available for this account")
                }
            }
        }
    }
}

struct BillContainerView_Previews: PreviewProvider {
    static var previews: some View {
        BillContainerView(billState: .loaded)
    }
}
