//
//  UIViewUsingAutoLayout.swift
//  Mobile
//
//  Created by Sam Francis on 11/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIView {
    func usingAutoLayout() -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        return self
    }
}
