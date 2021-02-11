//
//  BillState.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

enum BillState: Int, Identifiable, Equatable {
    var id: Int { rawValue }
    
    case loading
    case loaded
    case unavailable
}
