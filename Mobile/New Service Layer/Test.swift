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
//        json()
//
//        minVersion()
        
//        maint()
//  weather()
//
//        WeatherServiceNew.getWeather() { (result: Result<NewWeather, Error>) in
//
//        }
        
    }
    
//    private func json() {
//                ServiceLayer.logJSON(router: .minVersion) { (result: Result<String, Error>) in
//                switch result {
//                case .success(let data):
//                    print("JSON 1 SUCCESS: \(data)")
//                case .failure(let error):
//                    print("JSON 1 FAIL: \(error)")
//                }
//            }
//    }
    
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
    
    private func maint() {
        ServiceLayer.request(router: .maintenanceMode) { (result: Result<NewMaintenanceMode, Error>) in
            switch result {
            case .success(let data):
                print("NetworkTest 2 SUCCESS: \(data) BREAK \(data.all)")
            case .failure(let error):
                print("NetworkTest 2 FAIL: \(error)")
            }
        }
    }
    
    private func weather() {
//        ServiceLayer.logJSON(router: .weather(lat: "39.295", long: "-76.624")) { (result: Result<String, Error>) in
//            switch result {
//            case .success(let data):
//                print("NetworkTest 9 JSON SUCCESS: \(data) BREAK \(data)")
//            case .failure(let error):
//                print("NetworkTest 9 JSON FAIL: \(error)")
//            }
//        }
        
        ServiceLayer.request(router: .weather(lat: "39.295", long: "-76.624")) { (result: Result<NewWeather, Error>) in
            switch result {
            case .success(let data):
                print("NetworkTest 9 SUCCESS: \(data) BREAK \(data.temperature)")
            case .failure(let error):
                print("NetworkTest 9 FAIL: \(error)")
            }
        }
    }
    
    func wallet() {
        ServiceLayer.request(router: .wallet) { (result: Result<NewWallet, Error>) in
            switch result {
            case .success(let data):
                print("NetworkTest 10 SUCCESS: \(data) BREAK \(data.walletItems.first?.id)")
            case .failure(let error):
                print("NetworkTest 10 FAIL: \(error)")
            }
        }
    }
    
    func payment(accountNumber: String) {
        ServiceLayer.request(router: .payments(accountNumber: accountNumber)) { (result: Result<NewPayments, Error>) in
            switch result {
            case .success(let data):
                print("NetworkTest 11 SUCCESS: \(data) BREAK \(data.billingInfo.payments.first?.amount)")
            case .failure(let error):
                print("NetworkTest 11 FAIL: \(error)")
            }
        }
    }
}
