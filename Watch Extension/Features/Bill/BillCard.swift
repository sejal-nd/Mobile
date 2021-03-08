//
//  BillCard.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct BillCard: View {
    let value: String
    var shouldItalisizeValue = false
    let title: String
    var dateText: String? = nil
    var dateColor: Color = .primary
    
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                if shouldItalisizeValue {
                    Text(value)
                        .italic()
                } else {
                    Text(value)

                }
                Text(title)
                    .multilineTextAlignment(.center)
                
                if let dateText = dateText {
                    Text(dateText)
                        .multilineTextAlignment(.center)
                        .foregroundColor(dateColor)
                }
            }
            Spacer()
        }
        .padding()
        .background(CardView())
    }
}

struct BillCard_Previews: PreviewProvider {
    static var previews: some View {
        BillCard(value: "-$500.00",
                 title: "Pending Payments",
                 dateText: "Due Immdiately",
                 dateColor: .red)
    }
}
