//
//  OutageView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct OutageView: View {
    let outage: WatchOutage
    let account: WatchAccount
    var isLoading = false
    @State private var wave = false
    
    private var powerText: String {
        outage.isPowerOn ? "POWER IS ON" : "POWER IS OUT"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Text("Our records indicate")
                .font(.subheadline)
            Text(powerText)
                .font(.system(size: 25))
                .fontWeight(.semibold)
                .padding(.bottom, 4)
            
            if let estimatedRestoration = outage.estimatedRestoration {
                Text("Estimated Restoration")
                    .font(.footnote)
                Text(estimatedRestoration)
                    .font(.footnote)
            }
            
            Spacer()
            
            if !isLoading {
                OutageAnimation(isPowerOn: outage.isPowerOn)
            }
        }
    }
}

struct OutageView_Previews: PreviewProvider {
    static var previews: some View {
        OutageView(outage: PreviewData.outageOn,
                   account: PreviewData.accounts[0],
                   isLoading: true)
        
        OutageView(outage: PreviewData.outageOn,
                   account: PreviewData.accounts[0],
                   isLoading: false)
        
        OutageView(outage: PreviewData.outageOff,
                   account: PreviewData.accounts[0],
                   isLoading: false)
    }
}
