//
//  Array+OptionalLookup.swift
//  Mobile
//
//  Created by Marc Shilling on 12/16/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

extension Array {

    // Safely lookup an index that might be out of bounds, returning nil if so
    func get(at index: Int) -> Element? {
        if 0 <= index && index < count {
            return self[index]
        }
        return nil
    }
}
