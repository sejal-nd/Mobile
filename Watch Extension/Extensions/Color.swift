//
//  Color.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

extension Color {
    static let watchSystemBackground = Color(red: 49/255,
                                             green: 50/255,
                                             blue: 51/255,
                                             opacity: 1.0)
    
    static var opco: Color {
        switch Configuration.shared.opco {
        case .bge:
            return Color(red: 103.0/255,
                         green: 179.0/255,
                         blue: 96.0/255,
                         opacity: 1.0)
        case .comEd:
            return Color(red: 235/255,
                         green: 0/255,
                         blue: 61/255,
                         opacity: 1.0)
        case .peco:
            return Color(red: 0.0/255,
                         green: 162.0/255,
                         blue: 255.0/255,
                         opacity: 1.0)
        case .ace, .delmarva, .pepco:
            return Color(red: 0/255,
                         green: 103/255,
                         blue: 177/255,
                         opacity: 1)
        }
    }
}
