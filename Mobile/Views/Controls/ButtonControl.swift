//
//  ButtonControl.swift
//  Mobile
//
//  Created by Sam Francis on 5/5/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ButtonControl: UIControl {
    
    @IBInspectable var shouldFadeSubviewsOnPress: Bool = false
    @IBInspectable var backgroundColorOnPress: UIColor?

    let bag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        let normalStateColor = backgroundColor
        
        let pressed = rx.controlEvent(.touchDown).asDriver().map { true }
        
        let notPressed = Driver.merge(rx.controlEvent(.touchUpInside).asDriver(),
                                      rx.controlEvent(.touchUpOutside).asDriver(),
                                      rx.controlEvent(.touchDragExit).asDriver(),
                                      rx.controlEvent(.touchCancel).asDriver()).map { false }
        
        Driver.merge(pressed, notPressed)
            .startWith(false)
            .distinctUntilChanged()
            .drive(onNext: { [weak self] pressed in
                guard let `self` = self else { return }
                self.backgroundColor = pressed ? self.backgroundColorOnPress: normalStateColor
                if self.shouldFadeSubviewsOnPress {
                    self.fadeSubviews(fadeAmount: pressed ? 0.5: 1, animationDuration: 0.1)
                }
            })
            .disposed(by: bag)
        
        isAccessibilityElement = true
        accessibilityTraits = UIAccessibilityTraitButton
    }
    
    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1 : 0.33
            accessibilityTraits = isEnabled ? UIAccessibilityTraitButton : (UIAccessibilityTraitButton|UIAccessibilityTraitNotEnabled)
        }
    }

}
