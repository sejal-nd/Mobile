//
//  Account.swift
//  Mobile
//
//  Created by Marc Shilling on 3/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

enum AccountType {
    case Residential
    case Commercial
}

struct Account {
    var accountType: AccountType
    var accountNumber: String
    var address: String
}
