//
//  RadioButton.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 5/19/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import SwiftUI

/// Whether the user selects to transfer third party supplier or not
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
    
    var warningText: String {
        switch self {
        case .transfer:
            return "You have indicated that we should carry forward your Third Party Electric Supplier Agreement. For any questions or concerns, please contact your Third Party Supplier. Your retail electric supplier’s phone number is provided in the Electric Supply Charges portion of your BGE bill."
        case .doNotTransfer:
            return "You have chosen to discontinue your Third Party Electric Supplier Agreement. This will be reflected in your account after your new service start date. For any questions or concerns, please contact your Third Party Supplier. Your retail electric supplier’s phone number is provided in the Electric Supply Charges portion of your BGE bill."
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
                        .foregroundColor(.deepGray)
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
