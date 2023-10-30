//
//  OpcoUpdateDetailView.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 10/26/23.
//  Copyright © 2023 Exelon Corporation. All rights reserved.
//

import SwiftUI
import EUDesignSystem

struct OpcoUpdateDetailView: View {
    let update: Alert
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(update.title)
                    .scaledFont(style: .title3, weight: .semibold)
                    .foregroundStyle(.neutralDark)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            HStack {
                Text(update.message)
                    .scaledFont(style: .body)
                    .foregroundStyle(.neutralDark)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            Spacer()
        }
        .padding(20)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct OpcoUpdateDetailView_Previews: PreviewProvider {
    static var previews: some View {
        OpcoUpdateDetailView(update: Alert(title: "Hello World",
                                           message: "This is an alert message."))
    }
}
