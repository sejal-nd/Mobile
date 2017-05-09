//
//  NibViews.swift
//  Mobile
//
//  Created by Sam Francis on 5/8/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

extension NSObject {
    public class var className: String {
        return NSStringFromClass(self).components(separatedBy: ".").last!
    }
    
    public var className: String {
        return NSStringFromClass(type(of: self)).components(separatedBy: ".").last!
    }
}

extension Bundle {
    func loadViewFromNib<View: UIView>() -> View {
        return loadNibNamed(View.className, owner: nil, options: nil)![0] as! View
    }
}
