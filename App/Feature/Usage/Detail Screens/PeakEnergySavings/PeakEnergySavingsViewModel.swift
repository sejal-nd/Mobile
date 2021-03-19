//
//  PeakEnergySavingsViewModel.swift
//  Mobile
//
//  Created by Majumdar, Amit on 25/09/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

final class PeakEnergySavingsViewModel {
    
    func fetchSERResults(accountNumber: String, success: @escaping (([SERResult]) -> ()), failure: @escaping (NetworkingError) ->()) {
        AccountService.fetchSERResults(accountNumber: accountNumber) { (result) in
            switch result {
            case .success(let serInfo):
                success(serInfo)
            case .failure(let error):
                failure(error)
            }
        }
    }
}
