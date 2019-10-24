//
//  Checkbox.swift
//  Mobile
//
//  Created by Marc Shilling on 7/24/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class Checkbox: UIControl {
    
    private var imageView: UIImageView!

    private var justToggled = false
    private var indeterminate = false
    
    var isChecked: Bool = false {
        didSet {
            indeterminate = false
            imageView.image = isChecked ? #imageLiteral(resourceName: "ic_checkbox_selected.pdf") :#imageLiteral(resourceName: "ic_checkbox_deselected.pdf")
            sendActions(for: .valueChanged)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .clear
        
        imageView = UIImageView(frame: CGRect(x: 0, y: 10, width: 24, height: 24))
        imageView.image = #imageLiteral(resourceName: "ic_checkbox_deselected.pdf")
        addSubview(imageView)
        
        isAccessibilityElement = true
    }
    
    func setIndeterminate(_ indeterminate: Bool) {
        self.indeterminate = indeterminate
        if indeterminate {
            imageView.image = #imageLiteral(resourceName: "ic_checkbox_indeterminate.pdf")
        } else {
            imageView.image = isChecked ? #imageLiteral(resourceName: "ic_checkbox_selected.pdf") :#imageLiteral(resourceName: "ic_checkbox_deselected.pdf")
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 44, height: 44)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if indeterminate {
            self.isChecked = true
        } else {
            self.isChecked = !isChecked
        }
        justToggled = true
    }
    
    override var isEnabled: Bool {
        didSet {
            imageView.alpha = isEnabled ? 1.0 : 0.4
        }
    }
    
    private var accessibilityLabelInternal: String?
    override var accessibilityLabel: String? {
        set {
            self.accessibilityLabelInternal = newValue
        }
        get {
            let state: String
            if indeterminate {
                state = NSLocalizedString("Indeterminate", comment: "")
            } else {
                state = isChecked ? NSLocalizedString("Checked", comment: "") :
                    NSLocalizedString("Unchecked", comment: "")
            }
            
            if justToggled { // Prevents duplicate readings of the full label (matches UISwitch behavior)
                justToggled = false
                return state
            }
            
            if let label = self.accessibilityLabelInternal {
                return String.localizedStringWithFormat("%@, Checkbox, %@", label, state)
            }
            return String.localizedStringWithFormat("Checkbox, %@", state)
        }
    }

}

extension Reactive where Base: Checkbox {
    var isChecked: ControlProperty<Bool> {
        return base.rx.controlProperty(editingEvents: [.valueChanged], getter: { checkbox in
            return checkbox.isChecked
        }, setter: { checkbox, isChecked in
            checkbox.isChecked = isChecked
        })
    }
}

