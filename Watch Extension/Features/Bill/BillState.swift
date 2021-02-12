//
//  BillState.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

enum BillState {
    case loading
    case loaded(bill: WatchBill, account: WatchAccount)
    case unavailable(account: WatchAccount)
    case error(errorState: ErrorState)
}
