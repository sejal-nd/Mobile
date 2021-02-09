//
//  OutageState.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

enum OutageState: Int, Identifiable, Equatable {
    var id: Int { rawValue }
    
    case loaded
    case gasOnly
    case unavailable
}
