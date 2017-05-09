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
        
        let selectedColor = rx.controlEvent(.touchDown).asDriver()
            .map { UIColor.softGray }
        
        let deselectedColor = Driver.merge(rx.controlEvent(.touchUpInside).asDriver(),
                                           rx.controlEvent(.touchUpOutside).asDriver(),
                                           rx.controlEvent(.touchCancel).asDriver())
            .map { normalStateColor }
        
        Driver.merge(selectedColor, deselectedColor)
            .drive(onNext: { [weak self] color in
                self?.backgroundColor = color
            })
            .addDisposableTo(bag)
    }

}
