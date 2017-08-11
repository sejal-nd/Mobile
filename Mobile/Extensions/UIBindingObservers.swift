//
//  UIBindingObservers.swift
//  Mobile
//
//  Created by Sam Francis on 7/27/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

extension Reactive where Base: NSObject {
    
    /// Bindable sink for `accessibilityLabel` property.
    public var accessibilityLabel: UIBindingObserver<Base, String?> {
        return UIBindingObserver(UIElement: self.base) { object, text in
            object.accessibilityLabel = text
        }
    }
    
    /// Bindable sink for `isAccessibilityElement` property.
    public var isAccessibilityElement: UIBindingObserver<Base, Bool> {
        return UIBindingObserver(UIElement: self.base) { object, isAccessibilityElement in
            object.isAccessibilityElement = isAccessibilityElement
        }
    }
    
}

extension Reactive where Base: UIView {
    
    /// Bindable sink for `backgroundColor` property.
    public var backgroundColor: UIBindingObserver<Base, UIColor?> {
        return UIBindingObserver(UIElement: self.base) { view, color in
            view.backgroundColor = color
        }
    }
    
}

extension Reactive where Base: UILabel {
    
    /// Bindable sink for `textColor` property.
    public var textColor: UIBindingObserver<Base, UIColor?> {
        return UIBindingObserver(UIElement: self.base) { label, color in
            label.textColor = color
        }
    }
    
    /// Bindable sink for `font` property.
    public var font: UIBindingObserver<Base, UIFont?> {
        return UIBindingObserver(UIElement: self.base) { label, font in
            label.font = font
        }
    }
    
}

