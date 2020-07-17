//
//  AnyObserver.swift
//  Mobile
//
//  Created by Cody Dillon on 7/14/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

extension AnyObserver where Element: Decodable {
    func handle <T: Decodable>(result: Result<T, NetworkingError>) {
        switch result {
        case .success(let data):
            self.onNext(data as! Element)
            self.onCompleted()
        case .failure(let error):
            self.onError(error)
        }
    }
}
