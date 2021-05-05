//
//  OutageState.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

enum OutageState: Equatable {
    case loading
    case loaded(outage: WatchOutage, account: WatchAccount)
    case gasOnly(account: WatchAccount)
    case unavailable(account: WatchAccount)
    case error(errorState: ErrorState)
}
