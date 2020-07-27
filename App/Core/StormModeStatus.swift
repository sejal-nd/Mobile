//
//  StormModeStatus.swift
//  Mobile
//
//  Created by Samuel Francis on 9/11/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

struct StormModeStatus {
    static var shared = StormModeStatus()
    
    var isOn = false
    
    private init() { }
}
