//
//  SeamlessMoveWarningView.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 5/17/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct SeamlessMoveWarningView: View {
    
    let stopServiceAddress: String
    let startServiceAddress: String
    var didPressButton: () -> ()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Our records indicate that you have an active Third Party Electric Supplier on your electric account at:")
                .multilineTextAlignment(.leading)
                .padding(.bottom, 12)
            
            Group {
                Text("Stop Service Address")
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                Text(stopServiceAddress)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
            }
            
            Divider()
                .padding(.vertical, 12)
            
            Text("For your convenience, we will transfer your Third Party Electric Supplier for you, to your new address at:")
                .multilineTextAlignment(.leading)
                .padding(.bottom, 12)
            
            Group {
                Text("Start Service Address")
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                Text(startServiceAddress)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Button("Press me", action: didPressButton)
        }
        .padding()
        
        //Text("SEAMLESS MOVE")
    }
}

struct SeamlessMoveWarningView_Previews: PreviewProvider {
    static var previews: some View {
        SeamlessMoveWarningView(stopServiceAddress: "test 123 123 132",
                                startServiceAddress: "New 321 321 321") {
            
        }
    }
}
