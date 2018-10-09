//
//  URLSession+Rx.swift
//  Mobile
//
//  Created by Sam Francis on 10/8/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

extension Reactive where Base: URLSession {
    
    func fullResponse(request: URLRequest) -> Observable<(HTTPURLResponse, Data)> {
        return Observable
            .create { observer in
                let task = self.base.dataTask(with: request) { (data, response, error) in
                    guard let response = response, let data = data else {
                        observer.on(.error(ServiceError(cause: error)))
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        observer.on(.error(ServiceError()))
                        return
                    }
                    
                    observer.on(.next((httpResponse, data)))
                    observer.on(.completed)
                }
                
                task.resume()
                return Disposables.create(with: task.cancel)
        }
    }
    
    func dataResponse(request: URLRequest) -> Observable<Data> {
        return fullResponse(request: request)
            .map { _, data in data }
    }
}
