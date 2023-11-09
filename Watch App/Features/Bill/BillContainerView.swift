//
//  BillContainerView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct BillContainerView: View {
    let bill: WatchBill
    let account: WatchAccount
    let isLoading: Bool
    
    var body: some View {
        BillView(bill: bill,
                 account: account,
                 isLoading: isLoading)
    }
}

struct BillContainerView_Previews: PreviewProvider {
    static var previews: some View {
        BillContainerView(bill: PreviewData.billDefault,
                          account: PreviewData.accounts[0],
                          isLoading: true)
        
        BillContainerView(bill: PreviewData.billStandard,
                          account: PreviewData.accounts[0],
                          isLoading: false)
        
        BillContainerView(bill: PreviewData.billAutoPay,
                          account: PreviewData.accounts[0],
                          isLoading: false)
        
        BillContainerView(bill: PreviewData.billPrecarious,
                          account: PreviewData.accounts[0],
                          isLoading: false)
    }
}
