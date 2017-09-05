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
    let walletUpdated = PublishSubject<Void>()
    
    private init() { }
    
}
