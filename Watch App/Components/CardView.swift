//
//  CardView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct CardView: View {
    private let watchCardBackground = Color(red: 49/255,
                                            green: 50/255,
                                            blue: 51/255,
                                            opacity: 1.0)
    var body: some View {
        RoundedRectangle(cornerRadius: 8.0,
                         style: .continuous)
            .foregroundColor(watchCardBackground)
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView()
    }
}
