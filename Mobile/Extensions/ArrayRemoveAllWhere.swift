//
//  ArrayRemoveAllWhere.swift
//  Mobile
//
//  Created by Samuel Francis on 6/19/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

@available(iOS, deprecated: 12.0, message: "`removeAll(where:)` is in the Swift 4.2 standard library, so we can remove this when we update.")
extension Array {
    mutating func removeAll(where shouldRemove: (Element) -> Bool) {
        let partitionIndex = halfStablePartition(isSuffixElement: shouldRemove)
        removeSubrange(partitionIndex...)
    }
    
    mutating func halfStablePartition(isSuffixElement: (Element) -> Bool) -> Index {
        guard var i = enumerated().first(where: { isSuffixElement($1) })?.0 else { return endIndex }
        var j = index(after: i)
        while j != endIndex {
            if !isSuffixElement(self[j]) { swapAt(i, j); formIndex(after: &i) }
            formIndex(after: &j)
        }
        return i
    }
}

extension Array {
    func removingAll(where shouldRemove: (Element) -> Bool) -> [Element] {
        var a = self
        a.removeAll(where: shouldRemove)
        return a
    }
}
