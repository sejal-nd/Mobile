//
//  Test.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/9/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

// todo this will be extracted to a playground once we have this in a swift package.
class NetworkTest {
    static let shared = NetworkTest()
    
    private init() { }
    
    private func minVersion() {
        NetworkingLayer.request(router: .minVersion) { (result: Result<MinimumVersion, NetworkingError>) in
            switch result {
            case .success(let data):
                print("NetworkTest SUCCESS: \(data) BREAK \(data.min)")
            case .failure(let error):
                print("NetworkTest FAIL: \(error)")
            }
        }
    }
    
    private func maint() {
        NetworkingLayer.request(router: .maintenanceMode) { (result: Result<MaintenanceMode, NetworkingError>) in
            switch result {
            case .success(let data):
                print("NetworkTest SUCCESS: \(data) BREAK \(data.all)")
            case .failure(let error):
                print("NetworkTest FAIL: \(error)")
            }
        }
    }
    
    private func weather() {
        NetworkingLayer.request(router: .weather(lat: "39.295", long: "-76.624")) { (result: Result<Weather, NetworkingError>) in
            switch result {
            case .success(let data):
                print("NetworkTest SUCCESS: \(data) BREAK \(data.temperature ?? 0)")
            case .failure(let error):
                print("NetworkTest FAIL: \(error)")
            }
        }
    }
    
    func wallet() {
        NetworkingLayer.request(router: .wallet()) { (result: Result<Wallet, NetworkingError>) in
            switch result {
            case .success(let data):
                print("NetworkTest SUCCESS: \(data) BREAK \(data.walletItems.first?.walletItemId ?? "")")
            case .failure(let error):
                print("NetworkTest FAIL: \(error)")
            }
        }
    }
    
    func payment(accountNumber: String) {
        NetworkingLayer.request(router: .payments(accountNumber: accountNumber)) { (result: Result<Payments, NetworkingError>) in
            switch result {
            case .success(let data):
                print("NetworkTest SUCCESS: \(data) BREAK \(data.billingInfo.payments.first?.amount ?? 0.0)")
            case .failure(let error):
                print("NetworkTest FAIL: \(error)")
            }
        }
    }
}
