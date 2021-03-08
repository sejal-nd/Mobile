//
//  UsageState.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

enum UsageState: Equatable {
    case loading
    case loaded(usage: WatchUsage, account: WatchAccount)
    case unforecasted(account: WatchAccount, days: Int)
    case unavailable(account: WatchAccount)
    case error(errorState: ErrorState)
}
