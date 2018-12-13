//
//  SafariViewController.swift
//  Mobile
//
//  Created by Sam Francis on 10/31/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import SafariServices

extension SFSafariViewController {
    static func createWithCustomStyle(url: URL) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredBarTintColor = .white
        safariVC.preferredControlTintColor = .primaryColor
        return safariVC
    }
}
