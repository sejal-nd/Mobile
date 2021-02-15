//
//  Color.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

extension Color {
    static let watchCardBackground = Color(red: 49/255,
                                           green: 50/255,
                                           blue: 51/255,
                                           opacity: 1.0)
    
    static var opco: Color {
        switch Configuration.shared.opco {
        case .bge:
            return Color(red: 121/255,
                         green: 176/255,
                         blue: 105/255,
                         opacity: 1.0)
        case .comEd:
            return Color(red: 190/255,
                         green: 45/255,
                         blue: 69/255,
                         opacity: 1.0)
        case .peco, .ace, .delmarva, .pepco:
            return Color(red: 68/255,
                         green: 162/255,
                         blue: 248/255,
                         opacity: 1.0)
        }
    }
}
