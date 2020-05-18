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
    
    /// Bindable sink for `accessibilityElementsHidden` property.
    public var accessibilityElementsHidden: Binder<Bool> {
        return Binder(base) { object, accessibilityElementsHidden in
            object.accessibilityElementsHidden = accessibilityElementsHidden
        }
    }
    
    /// Bindable sink for `accessibilityValue` property.
    public var accessibilityValue: Binder<String?> {
        return Binder(base) { object, value in
            object.accessibilityValue = value
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
    
    public var borderColor: Binder<CGColor?> {
        return Binder(base) { view, color in
            view.layer.borderColor = color
        }
    }
    
    public var borderWidth: Binder<CGFloat> {
        return Binder(base) { view, width in
            view.layer.borderWidth = width
        }
    }
    
    public var cornerRadius: Binder<CGFloat> {
        return Binder(base) { view, radius in
            view.layer.cornerRadius = radius
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
