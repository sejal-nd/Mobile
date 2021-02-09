//
//  BillFlowContainerView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct BillFlowContainerView: View {
    @State private var billState: BillState = .loaded
    @State private var errorState: ErrorState? = nil
    
    var body: some View {
        Group {
            if let errorState = errorState {
                ErrorContainerView(errorState: errorState)
            } else {
                BillContainerView(billState: billState)
            }
        }
        .navigationTitle("Bill")
    }
}

struct BillFlowContainerView_Previews: PreviewProvider {
    static var previews: some View {
        BillFlowContainerView()
    }
}
