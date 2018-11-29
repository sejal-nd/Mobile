//
//  AccountListInterfaceController.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 9/20/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import WatchKit
import Foundation


class AccountListInterfaceController: WKInterfaceController {

    @IBOutlet weak var table: WKInterfaceTable!
    
    private var accounts = [Account]()
    
    
    // MARK: - Interface Life Cycle
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        loadTableData()
    }
    
    override func didAppear() {
        super.didAppear()
        
        // Log Analytics
        GATracker.shared.screenView(screenName: AccountListInterfaceController.className, customParameters: nil)
    }

    
    // MARK: - Helper
    
    private func loadTableData() {
        guard let storedAccounts = AccountsStore.shared.accounts,
              let currentAccount = AccountsStore.shared.currentAccount else { return }

        accounts = storedAccounts
        
        // Arrange Current Account to First in Array
        if let currentAccountIndex = accounts.lastIndex(of: currentAccount) {
            accounts.rearrange(from: currentAccountIndex, to: 0)
        }
        
        table.setNumberOfRows(accounts.count, withRowType: AccountTableRowController.className)
        
        for (index, account) in accounts.enumerated() {
            let row = table.rowController(at: index) as? AccountTableRowController
            row?.configure(account: account)
        }
    }
    
}


// MARK: - Table Selection

extension AccountListInterfaceController {
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        guard !accounts.isEmpty else {
            dismiss()
            return
        }
        
        // Set Selected Account
        let newAccount = accounts[rowIndex]
        AccountsStore.shared.currentAccount = newAccount
        NotificationCenter.default.post(name: Notification.Name.currentAccountUpdated, object: newAccount)
        
        dismiss()
    }
    
}
