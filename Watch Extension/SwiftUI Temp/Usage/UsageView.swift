//
//  UsageView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct UsageView: View {
    let usageState: UsageState
    
    var body: some View {
        VStack {
            ZStack {
                Image("usageGraph21") // todo
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                
                VStack {
                    Image(AppImage.gas.name)
                    Text("Spent So Far")
                    Text("$80")  // todo
                        .fontWeight(.semibold)
                }
            }
            .padding(.bottom, 16)
            
            VStack(alignment: .leading,
                   spacing: 16) {
                VStack(alignment: .leading) {
                    Divider()
                    Text("Spent So Far")
                        .foregroundColor(.gray)
                    Text("$80")  // todo
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading) {
                    Divider()
                    Text("Projected Bill")
                        .foregroundColor(.gray)
                    Text("$120")  // todo
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading) {
                    Divider()
                    Text("Bill Period")
                        .foregroundColor(.gray)
                    Text("May 24 - Jun 19") // todo
                        .foregroundColor(.gray)
                }
                
                Text("This is an estimate and the actual amount may vary based on your energy use, taxes, and fees.")
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.gray)
                    .font(.footnote)
            }
        }
    }
}

struct UsageView_Previews: PreviewProvider {
    static var previews: some View {
        UsageView(usageState: .loaded)
    }
}
