//
//  Arc.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/17/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct Arc: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let width = Double(rect.width)
            let height = Double(rect.height)
            
            path.move(to: CGPoint(x: 6, y: height))
            path.addCurve(to: CGPoint(x: width - 6, y: height),
                          control1: CGPoint(x: width / 2 - 40 , y: (height * 0.5)),
                          control2: CGPoint(x: width / 2 + 40, y: (height * 0.5)))
        }
    }
}
