//
//  Tab.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

enum Tab: Int, Identifiable, CaseIterable {
    case accountList
    case outage
    case usage
    case bill
    
    var id: Int { rawValue }
}
