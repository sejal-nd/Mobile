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
    var didSelectRadioButton: (TransferServiceOption) -> ()
    
    @State private var transferOption: TransferServiceOption = .transfer
    
    var body: some View {
        VStack(alignment: .leading) {
            // Stop Service
            Text("Our records indicate that you have an active Third Party Electric Supplier on your electric account at:")
                .multilineTextAlignment(.leading)
                .padding(.bottom, 12)
            
            Group {
                Text("Stop Service Address")
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                #warning("TODO, pass in stop service address")
                Text(stopServiceAddress)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
            }
            
            Divider()
                .padding(.vertical, 12)
            
            
            // Start Service
            Text("For your convenience, we will transfer your Third Party Electric Supplier for you, to your new address at:")
                .multilineTextAlignment(.leading)
                .padding(.bottom, 12)
            
            Group {
                Text("Start Service Address")
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                #warning("TODO, pass in start service address")
                Text(startServiceAddress)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // User Options
            ForEach(TransferServiceOption.allCases) { option in
                RadioButton(transferServiceOption: option,
                            selectedTransferServiceOption: $transferOption,
                            text: option.text) {
                    didSelectRadioButton(transferOption)
                }
                    .padding(.vertical)
                Divider()
                    .padding(.leading, 24)
            }
        }
        .padding()
    }
}

struct SeamlessMoveWarningView_Previews: PreviewProvider {
    static var previews: some View {
        SeamlessMoveWarningView(stopServiceAddress: "test 123 123 132",
                                startServiceAddress: "New 321 321 321") { _ in
            
        }
    }
}
