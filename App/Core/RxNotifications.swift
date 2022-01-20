//
//  RxNotifications.swift
//  Mobile
//
//  Created by Sam Francis on 9/5/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxRelay

struct RxNotifications {
    static let shared = RxNotifications()
    
    let accountDetailUpdated = PublishSubject<Void>()
    let recentPaymentsUpdated = PublishSubject<Void>()
    let defaultWalletItemUpdated = PublishSubject<Void>()
    let outageReported = PublishSubject<Void>()
    let configureQuickActions = PublishSubject<Bool>()
    
    let mfaJustEnabled = BehaviorRelay<Bool>(value: false)
    let mfaBypass = BehaviorRelay<Bool>(value: false)
    let profileEditAction = BehaviorRelay<String?>(value: nil)
    
    private init() { }
    
}
