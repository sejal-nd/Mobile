//
//  CardView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct CardView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8.0,
                         style: .continuous)
            .foregroundColor(Color.watchCardBackground)
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView()
    }
}
