//
//  NetworkController.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

class NetworkController: ObservableObject {
    @Published var accounts = [WatchAccount]()
    @Published var outage: WatchOutage?
    @Published var usage: WatchUsage?
//    @Published var bill: WatchBill

    
    
}

// MARK: Network Requests

extension NetworkController {
//    private func fetchAccounts() {
//        AccountService.fetchAccounts { networkResult in
//            switch networkResult {
//            case .success(let accounts):
//                if AccountsStore.shared.currentIndex == nil {
//                    AccountsStore.shared.currentIndex = 0
//                }
//                self.accounts = accounts.map({ WatchAccount(account: $0) })
//            case .failure(let error):
//                if error == .passwordProtected {
//                    Log.info("Failed to retrieve account list.  Password Protected Account.")
////                    result(.failure(.passwordProtected))
//                } else {
//                    Log.info("Failed to retrieve account list: \(error.localizedDescription)")
////                    result(.failure(.fetchError))
//                }
//            }
//        }
//    }
//
//    private func fetchFeatureData() {
//
//    }
}
