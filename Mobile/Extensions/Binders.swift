//
//  Binders.swift
//  Mobile
//
//  Created by Sam Francis on 7/27/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

extension Reactive where Base: NSObject {
    
    /// Bindable sink for `accessibilityLabel` property.
    public var accessibilityLabel: Binder<String?> {
        return Binder(base) { object, text in
            object.accessibilityLabel = text
        }
    }
    
    /// Bindable sink for `isAccessibilityElement` property.
    public var isAccessibilityElement: Binder<Bool> {
        return Binder(base) { object, isAccessibilityElement in
            object.isAccessibilityElement = isAccessibilityElement
        }
    }
    
}

extension Reactive where Base: UIView {
    
    /// Bindable sink for `backgroundColor` property.
    public var backgroundColor: Binder<UIColor?> {
        return Binder(base) { view, color in
            view.backgroundColor = color
        }
    }
    
}

extension Reactive where Base: UILabel {
    
    /// Bindable sink for `textColor` property.
    public var textColor: Binder<UIColor?> {
        return Binder(base) { label, color in
            label.textColor = color
        }
    }
    
    /// Bindable sink for `font` property.
    public var font: Binder<UIFont?> {
        return Binder(base) { label, font in
            label.font = font
        }
    }
    
}

