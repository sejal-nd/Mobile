//
//  AccountStore+SelectedAccount.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 9/20/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

extension AccountsStore {
    
    private static var selectedAccountKey = "SelectedAccount"
    
    /// Returns the most up to date current account, Note: DO NOT use `AccountStore.shared.currentAccount`
    public func getSelectedAccount() -> Account? {
        guard let accountData = UserDefaults.standard.value(forKey: AccountsStore.selectedAccountKey) as? Data else { return nil }
        return try? JSONDecoder().decode(Account.self, from: accountData)
    }

    /// Used from DataSource.Swift to update the currently selected account: This defaults to the first account in the returned accountList
    public func setSelectedAccount(_ account: Account?, isUserSelection: Bool = false) {
        guard let encoded = try? JSONEncoder().encode(account) else {
            if account == nil {
                UserDefaults.standard.set(account, forKey: AccountsStore.selectedAccountKey)
            }
            return
        }

        UserDefaults.standard.set(encoded, forKey: AccountsStore.selectedAccountKey)
        
        if isUserSelection {
            currentAccount = account
        }
    }
    
}
