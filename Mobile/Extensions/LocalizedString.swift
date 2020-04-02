//
//  LocalizedString.swift
//  Mobile
//
//  Created by Cody Dillon on 4/2/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import UIKit

extension String {
    func localized(comment: String? = nil) -> String {
        return Environment.shared.opco == .bge ? localized(tableName: "BGEStrings", comment: comment) : NSLocalizedString(self, comment: comment ?? "")
    }
    
    func localized(tableName: String? = nil, comment: String? = nil) -> String {
        return NSLocalizedString(self, tableName: tableName, comment: comment ?? "")
    }
}
