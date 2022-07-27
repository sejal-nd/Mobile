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
    let stopServiceCountyStateZip: String
    let startServiceAddress: String
    let startServiceCountyStateZip: String

    var didSelectRadioButton: (TransferServiceOption) -> ()
    
    @State private var transferOption: TransferServiceOption = .transfer
    
    var body: some View {
        VStack(alignment: .leading) {
            // Stop Service
            Text("Our records indicate that you have an active Third Party Electric Supplier on your electric account at:")
                .multilineTextAlignment(.leading)
                .padding(.bottom, 12)
                .foregroundColor(.deepGray)
            
            Group {
                Text("Stop Service Address")
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.deepGray)
                Text(stopServiceAddress)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.deepGray)
                Text(stopServiceCountyStateZip)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.deepGray)
            }
            
            Divider()
                .padding(.vertical, 12)
            
            
            // Start Service
            Text("For your convenience, we will transfer your Third Party Electric Supplier for you, to your new address at:")
                .multilineTextAlignment(.leading)
                .padding(.bottom, 12)
                .foregroundColor(.deepGray)
            
            Group {
                Text("Start Service Address")
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.deepGray)
                Text(startServiceAddress)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.deepGray)
                Text(startServiceCountyStateZip)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.deepGray)
            }
            
            Spacer()
            
            Text("Select Option")
                .fontWeight(.semibold)
                .multilineTextAlignment(.leading)
                .foregroundColor(.deepGray)
            
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
        SeamlessMoveWarningView(stopServiceAddress: "1310 Point St",
                                stopServiceCountyStateZip: "Baltimore, MD 21231",
                                startServiceAddress: "1310 Point St",
                                startServiceCountyStateZip: "Baltimore, MD 21231") { _ in
            
        }
    }
}
