//
//  RxNotifications.swift
//  Mobile
//
//  Created by Sam Francis on 9/5/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

struct RxNotifications {
    static let shared = RxNotifications()
    
    let accountDetailUpdated = PublishSubject<Void>()
    let recentPaymentsUpdated = PublishSubject<Void>()
    let defaultWalletItemUpdated = PublishSubject<Void>()
    let outageReported = PublishSubject<Void>()
    let configureQuickActions = PublishSubject<Bool>()
    
    let mfaJustEnabled = BehaviorSubject<Bool>(value: false)
    let mfaRemindMeLater = BehaviorSubject<Bool>(value: false)
    
    private init() { }
    
}
