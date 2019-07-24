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

@IBDesignable
class Checkbox: UIControl {
    
    private var imageView: UIImageView!
    
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
        imageView = UIImageView(frame: CGRect(x: 10, y: 10, width: 24, height: 24))
        imageView.image = #imageLiteral(resourceName: "ic_checkbox_deselected.pdf")
        addSubview(imageView)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 44, height: 44)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.isChecked = !isChecked
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

