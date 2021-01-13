//
//  Bundle+Version.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 1/13/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

extension Bundle {
    var versionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}
