//
//  MockData.swift
//  Mobile
//
//  Created by Samuel Francis on 5/8/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

struct MockData {
    var username: String?
    
    static var shared = MockData()
    
    private init() {}
    
}
