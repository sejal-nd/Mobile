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
    
    var shouldFadeSubviews = true
    
    var backgroundColorOnPress = UIColor.clear

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
        let normalStateColor = backgroundColor ?? .clear
        
        let selected = rx.controlEvent(.touchDown).asDriver()
            .map { true }
        
        let deselected = Driver.merge(rx.controlEvent(.touchUpInside).asDriver(),
                                           rx.controlEvent(.touchUpOutside).asDriver(),
                                           rx.controlEvent(.touchCancel).asDriver())
            .map { false }
        
        Driver.merge(selected, deselected)
            .drive(onNext: { [weak self] selected in
                self?.backgroundColor = selected ? self?.backgroundColorOnPress: normalStateColor
                self?.fadeSubviews(fadeAmount: selected ? 0.5: 1, animationDuration: 0.0)
            })
            .addDisposableTo(bag)
    }
    
    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1 : 0.33
        }
    }

    
}

extension UIView {
    func fadeSubviews(fadeAmount amount: CGFloat, animationDuration: TimeInterval, excludedViews: [UIView] = [UIView]()) {
        let subviews = self.subviews + self.subviews.flatMap { $0.subviews }
        UIView.animate(withDuration: animationDuration, animations: {
            subviews.filter { !excludedViews.contains($0) }.forEach { subview in
                if !(subview is UIStackView) {
                    subview.alpha = amount
                } else {
                    subview.fadeSubviews(fadeAmount: amount, animationDuration: animationDuration)
                }
            }
        })
    }
}
