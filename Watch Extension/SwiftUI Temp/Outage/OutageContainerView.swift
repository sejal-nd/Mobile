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

    #warning("image sizes are not correct right now.")
    var body: some View {
        OutageView(outage: outage,
                   account: account)
    }
}

//struct OutageContainerView_Previews: PreviewProvider {
//    static var previews: some View {
//        OutageContainerView(outageState: .loading,
//                            watchOutage: nil)
//        
//        OutageContainerView(outageState: .loaded,
//                            watchOutage: PreviewData.outageOn)
//        
//        OutageContainerView(outageState: .loaded,
//                            watchOutage: PreviewData.outageOff)
//        
//        OutageContainerView(outageState: .gasOnly,
//                            watchOutage: nil)
//        
//        OutageContainerView(outageState: .unavailable,
//                            watchOutage: nil)
//    }
//}
