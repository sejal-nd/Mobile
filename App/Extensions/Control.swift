//
//  Control.swift
//  Mobile
//
//  Created by Sam Francis on 5/5/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import UIKit

extension Reactive where Base : UIControl {
    var touchUpInside: RxCocoa.ControlEvent<Swift.Void> {
        return controlEvent(.touchUpInside)
    }
}
