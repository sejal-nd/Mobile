//
//  UsageInitExtensions.swift
//  Mobile
//
//  Created by Sam Francis on 2/22/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

extension EnergyTip {
    
    init(title: String = "",
         image: UIImage? = nil,
         body: String = "") {
        
        assert(Environment.sharedInstance.environmentName == "AUT",
               "init only available for tests")

        self.title = title
        self.image = image
        self.body = body
    }
}
