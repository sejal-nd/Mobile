//
//  MiniWalletViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 6/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

class MiniWalletSheetViewModel {
    let walletItems = [WalletItem]()
    var selectedWalletItem: WalletItem?
    var temporaryWalletItem: WalletItem?
    var editingWalletItem: WalletItem?

    var tableViewWalletItems: [WalletItem] {
        var items = walletItems
        if let temporaryWalletItem = temporaryWalletItem {
            if !items.contains(temporaryWalletItem) {
                items.insert(temporaryWalletItem, at: 0)
            }
        }
        return items
    }
}
