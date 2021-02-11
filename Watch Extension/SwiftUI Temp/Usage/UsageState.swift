//
//  UsageState.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

enum UsageState {
    case loading
    case loaded(usage: WatchUsage, acccount: WatchAccount)
    case unforecasted(acccount: WatchAccount, days: Int)
    case unavailable(acccount: WatchAccount)
    case error(errorState: ErrorState)
}
