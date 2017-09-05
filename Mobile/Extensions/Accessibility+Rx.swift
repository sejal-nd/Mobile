//
//  Accessibility+Rx.swift
//  Mobile
//
//  Created by Sam Francis on 7/27/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

extension Reactive where Base: UILabel {
    
    /// Bindable sink for `accessibilityLabel` property.
    public var accessibilityLabel: UIBindingObserver<Base, String?> {
        return UIBindingObserver(UIElement: self.base) { label, text in
            label.accessibilityLabel = text
        }
    }
    
}
