//
//  NibViews.swift
//  Mobile
//
//  Created by Sam Francis on 5/8/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

extension NSObject {
    @nonobjc public class var className: String {
        return String(describing: self)
    }
    
    @nonobjc public var className: String {
        return String(describing: type(of: self))
    }
}

#if os(iOS)
extension Bundle {
    func loadViewFromNib<View: UIView>() -> View {
        return loadNibNamed(View.className, owner: nil, options: nil)![0] as! View
    }
}
#endif
