//
//  OutageContainerView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct OutageContainerView: View {
    let outage: WatchOutage
    let account: WatchAccount
    let isLoading: Bool

    #warning("does this view have a pupose anymore? Favor this over the flow controller?")
    
    var body: some View {
        OutageView(outage: outage,
                   account: account)
    }
}

struct OutageContainerView_Previews: PreviewProvider {
    static var previews: some View {
        OutageContainerView(outage: PreviewData.outageOn,
                            account: PreviewData.accounts[0],
                            isLoading: true)
        
        OutageContainerView(outage: PreviewData.outageOn,
                            account: PreviewData.accounts[0],
                            isLoading: false)
        
        OutageContainerView(outage: PreviewData.outageOff,
                            account: PreviewData.accounts[0],
                            isLoading: false)
    }
}
