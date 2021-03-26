//
//  FeatureFlagService.swift
//  Mobile
//
//  Created by Cody Dillon on 2/26/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

enum FeatureFlagService {
    static func getFeatureFlags(completion: @escaping (Result<FeatureFlags, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .getFeatureFlags) { (result: Result<FeatureFlagsContainer, NetworkingError>) in
            switch result {
            case .success(let container):
                completion(.success(container.iOS))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
