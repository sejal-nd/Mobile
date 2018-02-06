//
//  MockUsageService.swift
//  Mobile
//
//  Created by Marc Shilling on 2/2/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

struct MockUsageService: UsageService {
    
    func fetchBillComparison(accountNumber: String, premiseNumber: String, yearAgo: Bool, gas: Bool, completion: @escaping (ServiceResult<BillComparison>) -> Void) {
        
    }
    
    func fetchBillForecast(accountNumber: String, premiseNumber: String, completion: @escaping (ServiceResult<[BillForecast?]>) -> Void) {
        
    }
    
    func fetchHomeProfile(accountNumber: String, premiseNumber: String, completion: @escaping (ServiceResult<HomeProfile>) -> Void) {
        
    }
    
    func updateHomeProfile(accountNumber: String, premiseNumber: String, homeProfile: HomeProfile, completion: @escaping (ServiceResult<Void>) -> Void) {
        
    }
    
    func fetchEnergyTips(accountNumber: String, premiseNumber: String, completion: @escaping (ServiceResult<[EnergyTip]>) -> Void) {
        
    }
    
    func fetchEnergyTipByName(accountNumber: String, premiseNumber: String, tipName: String, completion: @escaping (ServiceResult<EnergyTip>) -> Void) {
        
    }
}
