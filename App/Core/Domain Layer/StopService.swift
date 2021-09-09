//
//  StopService.swift
//  EUMobile
//
//  Created by RAMAITHANI on 09/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
enum StopService {
    
    static func fetchWorkdays(completion: @escaping (Result<[String], NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .workDays) { (result: Result<[String], NetworkingError>) in
            switch result {
            case .success(let accounts):
                completion(.success(accounts))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
