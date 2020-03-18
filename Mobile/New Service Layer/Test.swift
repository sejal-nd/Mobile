//
//  Test.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/9/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

class NetworkTest {
    static let shared = NetworkTest()
    
    private init() {
        json()
        
        minVersion()
    }
    
    private func json() {
                ServiceLayer.logJSON(router: .minVersion) { (result: Result<String, Error>) in
                switch result {
                case .success(let data):
                    print("JSON 1 SUCCESS: \(data)")
                case .failure(let error):
                    print("JSON 1 FAIL: \(error)")
                }
            }
    }
    
    private func minVersion() {
        ServiceLayer.request(router: .minVersion) { (result: Result<NewVersion, Error>) in
            switch result {
            case .success(let data):
                print("NetworkTest 1 SUCCESS: \(data) BREAK \(data.min)")
            case .failure(let error):
                print("NetworkTest 1 FAIL: \(error)")
            }
        }
    }
}
