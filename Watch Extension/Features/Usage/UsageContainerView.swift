//
//  UsageContainerView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct UsageContainerView: View {
    let usage: WatchUsage
    let account: WatchAccount
    let isLoading: Bool
    
    var body: some View {
        UsageView(usage: usage,
                  account: account,
                  isLoading: isLoading)
    }
}

struct UsageContainerView_Previews: PreviewProvider {
    static var previews: some View {
        UsageContainerView(usage: PreviewData.usageElectricModeled,
                           account: PreviewData.accounts[0],
                           isLoading: true)
        
        // Electric
        UsageContainerView(usage: PreviewData.usageElectricModeled,
                           account: PreviewData.accounts[0],
                           isLoading: false)
        
        UsageContainerView(usage: PreviewData.usageElectricUnmodeled,
                           account: PreviewData.accounts[0],
                           isLoading: false)
        
        // Gas
        UsageContainerView(usage: PreviewData.usageGasModeled,
                           account: PreviewData.accounts[0],
                           isLoading: false)
        
        UsageContainerView(usage: PreviewData.usageGasUnmodeled,
                           account: PreviewData.accounts[0],
                           isLoading: false)
        
        // Both
        UsageContainerView(usage: PreviewData.usageGasAndElectricModeled,
                           account: PreviewData.accounts[0],
                           isLoading: false)
        
        UsageContainerView(usage: PreviewData.usageGasAndElectricUnmodeled,
                           account: PreviewData.accounts[0],
                           isLoading: false)
    }
}
