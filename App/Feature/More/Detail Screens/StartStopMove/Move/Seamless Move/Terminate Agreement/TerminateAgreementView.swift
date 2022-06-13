//
//  TerminateAgreementView.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 5/19/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import SwiftUI

/// Whether user is deemed eligible for seamless move based on server even though they have a third party supplier
enum TransferEligibility: Identifiable, CaseIterable {
    case eligible
    case ineligible
    
    var id: Self { self }
    
    var text: String {
        switch self {
        case .eligible:
            return "BGE recommends you contact your current retail electric supplier regarding any contractual issues that may result from closing your account, such as possible fees. Your retail electric supplier’s phone number is provided in the Electric Supply Charges portion of your BGE bill."
        case .ineligible:
            return "Completing your Stop Service request will close your current BGE account and your supply agreement with your retail electric supplier will terminate as a result.\n\nBGE recommends you contact your current retail electric supplier regarding any contractual issues that may result from closing your account, such as possible fees. Your retail electric supplier’s phone number is provided in the Electric Supply Charges portion of your BGE bill."
        }
    }
    
    var checkboxText: String {
        switch self {
        case .eligible:
            return "I opt out of my Third Party Electric Supplier Agreement."
        case .ineligible:
            return "I understand that my supplier agreement will stop. If I decide to move my supplier agreement to my new BGE address, I will contact my supplier to arrange the service."
        }
    }
    
    var buttonText: String {
        return "Submit"
    }
}

struct TerminateAgreementView: View {
    
    var didSelectCheckbox: (Bool) -> ()
    
    var transferEligibility: TransferEligibility
    
    @State private var isSelected = false
    
    var body: some View {
        VStack(alignment: .leading) {
            if transferEligibility == .eligible {
                Text("Terminate My Supplier Agreement")
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .padding(.vertical, 6)
                    .foregroundColor(.deepGray)
            }
            
            Text(transferEligibility.text)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 6)
                .foregroundColor(.deepGray)
            CheckBoxView(isSelected: $isSelected,
                         text: transferEligibility.checkboxText) {
                didSelectCheckbox(isSelected)
            }
            Spacer()
        }
        .padding()
        .foregroundColor(.deepGray)
    }
}

struct TerminateAgreementView_Previews: PreviewProvider {
    static var previews: some View {
        TerminateAgreementView(didSelectCheckbox: { _ in
            
        }, transferEligibility: .eligible)
    }
}
