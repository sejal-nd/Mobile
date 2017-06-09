//
//  SecurityQuestion.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

class SecurityQuestion {
    var securityQuestion = ""
    var answer = ""
    
    var selected = false
    
    init(question: String) {
        securityQuestion = question
        answer = ""
        selected = false
    }
}
