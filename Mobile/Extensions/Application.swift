//
//  Application.swift
//  Mobile
//
//  Created by Samuel Francis on 10/23/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

/// Just some convenience functions for opening URLs
extension UIApplication {
    func openUrlIfCan(_ url: URL?) {
        if let url = url, canOpenURL(url) {
            open(url)
        }
    }
    
    func openUrlIfCan(string: String) {
        if let url = URL(string: string), canOpenURL(url) {
            open(url)
        }
    }
    
    func openPhoneNumberIfCan(_ phoneNumber: String) {
        openUrlIfCan(string: "tel://" + phoneNumber)
    }
}
