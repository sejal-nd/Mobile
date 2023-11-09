//
//  OutageAnimation.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/17/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct OutageAnimation: View {
    @State private var shouldAnimate = false
    
    var color: Color = .accentColor
    let isPowerOn: Bool
    
    var body: some View {
        ZStack {
            Arc()
                .stroke(style: StrokeStyle(lineWidth: 3.0, lineCap: .round))
                .frame(height: 25)
                .foregroundColor(color)
                .offset(x: 0, y: shouldAnimate ? -12 : 0)
                .opacity(isPowerOn ? 1 : (shouldAnimate ? 0.25 : 1))
            
            Arc()
                .stroke(style: StrokeStyle(lineWidth: 6.0, lineCap: .round))
                .frame(height: 25)
                .foregroundColor(color)
                .offset(x: 0, y: shouldAnimate ? -2 : 0)
        }
        .animation(Animation
                    .easeInOut(duration: 1)
                    .repeatForever(autoreverses: true)
                    .speed(0.5))
        .onAppear {
            shouldAnimate.toggle()
        }
    }
}

struct OutageAnimation_Previews: PreviewProvider {
    static var previews: some View {
        OutageAnimation(isPowerOn: true)
            .previewDevice("Apple Watch Series 6 - 40mm")
        
        OutageAnimation(isPowerOn: false)
            .previewDevice("Apple Watch Series 6 - 44mm")
    }
}
