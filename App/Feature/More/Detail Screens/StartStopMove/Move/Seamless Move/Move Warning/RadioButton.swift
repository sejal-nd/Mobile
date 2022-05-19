//
//  RadioButton.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 5/19/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import SwiftUI

enum TransferServiceOption: Identifiable, CaseIterable {
    case transfer
    case doNotTransfer
    
    var id: Self { self }
    
    var text: String {
        switch self {
        case .transfer:
            return "Transfer my Third Party Agreement"
        case .doNotTransfer:
            return "Discontinue my Third Party Agreement"
        }
    }
}

struct RadioButton: View {
    let transferServiceOption: TransferServiceOption
    @Binding var selectedTransferServiceOption: TransferServiceOption
    
    let text: String
    
    var didSelectRadioButton: () -> ()
    
    var body: some View {
        HStack {
            Button(action: didPressButton) {
                HStack {
                    Image(transferServiceOption == selectedTransferServiceOption ? "ic_radiobutton_selected" : "ic_radiobutton_deselected")
                    Text(text)
                        .foregroundColor(.black)
                }
            }
        }
    }
    
    private func didPressButton() {
        selectedTransferServiceOption = transferServiceOption
        didSelectRadioButton()
    }
}

//struct RadioButton_Previews: PreviewProvider {
//    static var previews: some View {
//        RadioButton(isSelected: .constant(true), text: "Test")
//    }
//}
