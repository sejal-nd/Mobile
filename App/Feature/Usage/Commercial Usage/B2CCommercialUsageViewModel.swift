//
//  B2CCommercialUsageViewModel.swift
//  EUMobile
//
//  Created by Cody Dillon on 3/29/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxSwiftExt

class B2CCommercialUsageViewModel {
    let tabs = BehaviorRelay(value: B2CUsageWebViewController.WidgetName.commercialWidgets)
    let selectedIndex = BehaviorRelay(value: 0)
    
    func selectedWidget() -> B2CUsageWebViewController.WidgetName {
        return B2CUsageWebViewController.WidgetName.commercialWidgets[selectedIndex.value]
    }
}
