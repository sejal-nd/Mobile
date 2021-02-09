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
    
//    @State private var wave = false
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Our records indicate")
                .font(.subheadline)
            Text("POWER IS ON")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 4)
            
            Text("Estimated Restoration")
                .font(.footnote)
            Text("10:30AM 10/09/2021")
                .font(.footnote)
            
            Image("On_37")
                .frame(height: 25)

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
        OutageView(outageState: .loaded)
    }
}
