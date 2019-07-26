//
//  MiniWalletViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 6/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

class MiniWalletSheetViewModel {
    var walletItems = [WalletItem]()
    var selectedWalletItem: WalletItem? // we may not need this variable.
    var temporaryWalletItem: WalletItem?
    var editingWalletItem: WalletItem?

    var tableViewWalletItems: [WalletItem] {
        var items = walletItems
        
        // Temp
        if let temporaryWalletItem = temporaryWalletItem {
            if !items.contains(temporaryWalletItem) {
                items.insert(temporaryWalletItem, at: 0)
            }
        }
        
        // Editing
        if let editingWalletItem = editingWalletItem {
            if !items.contains(editingWalletItem) {
                items.insert(editingWalletItem, at: 0)
            }
        }
        
        return items
    }
}
