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
    
    var isChecked: Bool = false {
        didSet {
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
    
    func commonInit() {
        backgroundColor = .clear
        
        imageView = UIImageView(frame: CGRect(x: 0, y: 10, width: 24, height: 24))
        imageView.image = #imageLiteral(resourceName: "ic_checkbox_deselected.pdf")
        addSubview(imageView)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 44, height: 44)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.isChecked = !isChecked
        justToggled = true
    }
    
    private var accessibilityLabelInternal: String?
    override var accessibilityLabel: String? {
        set {
            self.accessibilityLabelInternal = newValue
        }
        get {
            let checkedState = isChecked ? "Checked" : "Unchecked"
            if justToggled { // Prevent duplicate readings of the full label (matches UISwitch behavior)
                justToggled = false
                return checkedState
            }
            if let label = self.accessibilityLabelInternal {
                return "\(label), Checkbox, \(checkedState)"
            }
            return "Checkbox, \(checkedState)"
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

