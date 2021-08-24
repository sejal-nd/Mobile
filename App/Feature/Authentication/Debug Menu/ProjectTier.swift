//
//  ProjectTier.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 1/25/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

enum ProjectTier: String, Identifiable, Equatable, CaseIterable {
    var id: String { rawValue }
    
    case dev = "Dev"
    case test = "Test"
    case stage = "Stage"
}
