//
//  OutageView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct OutageView: View {
    let outageState: OutageState
    let watchOutage: WatchOutage?
    //    @State private var wave = false
    
    private var isPowerOn: Bool {
        watchOutage?.isPowerOn ?? true
    }
    
    private var powerText: String {
        isPowerOn ? "POWER IS ON" : "POWER IS OUT"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Our records indicate")
                .font(.subheadline)
            Text(powerText)
                .font(.system(size: 25))
                .fontWeight(.semibold)
                .padding(.bottom, 4)
            
            if let estimatedRestoration = watchOutage?.estimatedRestoration {
                Text("Estimated Restoration")
                    .font(.footnote)
                Text(estimatedRestoration)
                    .font(.footnote)
            }
            
            if watchOutage != nil {
                Image(isPowerOn ? "On_37" : "Out_37")
                    .frame(height: 25)
            }
            
            //                Circle()
            //                    .trim(from: 0.5, to: 1)
            //                    .stroke(lineWidth: 40)
            //                .frame(height: 25)
            //                    .foregroundColor(.green)
            //                    .scaleEffect(wave ? 2 : 1)
            //                    .opacity(wave ? 0.1 : 1)
            //                    .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: false).speed(0.5))
            //                    .onAppear {
            //                        wave.toggle()
            //                    }
        }
    }
}


struct OutageView_Previews: PreviewProvider {
    static var previews: some View {
        OutageView(outageState: .loading,
                   watchOutage: nil)
        
        OutageView(outageState: .loaded,
                   watchOutage: PreviewData.outageOff)
        
        OutageView(outageState: .loaded,
                   watchOutage: PreviewData.outageOn)
    }
}
