//
//  TerminateAgreementView.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 5/19/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct TerminateAgreementView: View {
    
    var didSelectCheckbox: (Bool) -> ()
    
    @State private var isSelected = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Terminate My Supplier Agreement")
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)
                .padding(.vertical, 6)
            
            Text("BGE recommends you contact your current retail electric supplier regarding any contractual issues that may result from closing your account, such as possible fees. Your retail electric supplier's phone number is provided in the Electric Supply Charges portion of your BGE bill.")
                .multilineTextAlignment(.leading)
                .padding(.bottom, 6)
            CheckBoxView(isSelected: $isSelected,
                         text: "I opt out of my Third Party Electric Supplier Agreement") {
                didSelectCheckbox(isSelected)
            }
            Spacer()
        }
        .padding()
    }
}

struct TerminateAgreementView_Previews: PreviewProvider {
    static var previews: some View {
        TerminateAgreementView() { _ in
            
        }
    }
}
