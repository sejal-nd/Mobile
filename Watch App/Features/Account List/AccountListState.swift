//
//  AccountListState.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

enum AccountListState: Equatable {
    case loading
    case loaded(accounts: [WatchAccount])
    case error(errorState: ErrorState)
}
