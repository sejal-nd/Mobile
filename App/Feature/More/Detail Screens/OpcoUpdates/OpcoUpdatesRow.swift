//
//  OpcoUpdatesRow.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 10/26/23.
//  Copyright © 2023 Exelon Corporation. All rights reserved.
//

import SwiftUI
import EUDesignSystem

struct OpcoUpdatesRow: View {
    let update: Alert
    
    var body: some View {
        NavigationLink(destination: OpcoUpdateDetailView(update: update)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(update.title)
                        .scaledFont(style: .callout, weight: .semibold)
                        .foregroundStyle(.neutralDark)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                HStack {
                    Text(update.message)
                        .scaledFont(style: .footnote)
                        .foregroundStyle(.neutralDark)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
            }
            .padding(20)
            .roundedRect(strokeColor: .neutralLight)
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: 480)
    }
}

struct OpcoUpdatesRow_Previews: PreviewProvider {
    static var previews: some View {
        OpcoUpdatesRow(update: Alert(title: "Hello World",
                                     message: "This is an alert message."))
    }
}
