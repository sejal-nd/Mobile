//
//  Equatable+Rearrange.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 9/26/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

extension RangeReplaceableCollection where Indices: Equatable {
    mutating func rearrange(from: Index, to: Index) {
        guard from != to && indices.contains(from) && indices.contains(to) else { return }
        insert(remove(at: from), at: to)
    }
}
