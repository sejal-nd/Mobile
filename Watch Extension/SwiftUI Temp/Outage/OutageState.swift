//
//  OutageState.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

enum OutageState {
    case loading
    case loaded(outage: WatchOutage, acccount: WatchAccount)
    case gasOnly(acccount: WatchAccount)
    case unavailable(acccount: WatchAccount)
    case error(errorState: ErrorState)
}
