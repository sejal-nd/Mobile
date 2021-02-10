//
//  PreviewData.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

enum PreviewData { }

// MARK: Account

extension PreviewData {
    static let accounts = [
        WatchAccount(accountID: "798123445",
                     address: "10 Anywhere…",
                     isResidential: true),
        WatchAccount(accountID: "798123445",
                     address: "10 Anywhere 10 Anywhere 10 Anywhere",
                     isResidential: false),
        WatchAccount(accountID: "798123445",
                     address: "10 Anywhere 10 Anywhere 10 Anywhere",
                     isResidential: true)
    ]
}

// MARK: Outage

extension PreviewData {
    static let outageOn = WatchOutage(isPowerOn: true)
    
    static let outageOff = WatchOutage(isPowerOn: false,
                                       estimatedRestoration: "10:30AM 10/09/2018")
}
