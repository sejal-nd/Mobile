//
//  TerminateAgreementView.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 5/19/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import SwiftUI

enum TransferEligibility: Identifiable, CaseIterable {
    case eligible
    case ineligible
    
    var id: Self { self }
    
    var text: String {
        switch self {
        case .eligible:
            return "BGE recommends you contact your current retail electric supplier regarding any contractual issues that may result from closing your account, such as possible fees. Your retail electric supplier’s phone number is provided in the Electric Supply Charges portion of your BGE bill."
        case .ineligible:
            return "todo"
        }
    }
    
    var checkboxText: String {
        switch self {
        case .eligible:
            return "I opt out of my Third Party Electric Supplier Agreement"
        case .ineligible:
            return "todo"
        }
    }
    
    var buttonText: String {
        switch self {
        case .eligible:
            return "Submit"
        case .ineligible:
            return "todo"
        }
    }
}

struct TerminateAgreementView: View {
    
    var didSelectCheckbox: (Bool) -> ()
    
    var transferEligibility: TransferEligibility
    
    @State private var isSelected = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Terminate My Supplier Agreement")
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)
                .padding(.vertical, 6)
            
            Text(transferEligibility.text)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 6)
            CheckBoxView(isSelected: $isSelected,
                         text: transferEligibility.checkboxText) {
                didSelectCheckbox(isSelected)
            }
            Spacer()
        }
        .padding()
    }
}

struct TerminateAgreementView_Previews: PreviewProvider {
    static var previews: some View {
        TerminateAgreementView(didSelectCheckbox: { _ in
            
        }, transferEligibility: .eligible)
    }
}
