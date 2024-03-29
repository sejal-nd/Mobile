//
//  ReviewStopServiceViewModel.swift
//  EUMobile
//
//  Created by RAMAITHANI on 15/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxSwiftExt
import RxCocoa
import UIKit
import RxRelay

class ReviewStopServiceViewModel {
    
    var onStopSubmit = PublishSubject<StopServiceFlowData>()
    var disposeBag = DisposeBag()
    private let isLoading = BehaviorRelay(value: true)
    var response = PublishSubject<StopServiceResponse>()
    var errorResponse = PublishSubject<Error>()

    init() {
        
        onStopSubmit
            .toAsyncRequest { [weak self] stopFlowData -> Observable<StopServiceResponse> in
                
                guard let `self` = self else { return Observable.empty() }
                if !self.isLoading.value {
                    self.isLoading.accept(true)
                }
                return Observable.create { observer -> Disposable in
                    StopService.stopService(stopFlowData: stopFlowData, completion: { observer.handle(result: $0) }) 
                    
                    return Disposables.create()
                }
            }.subscribe(onNext: { [weak self] result in
                guard let `self` = self else {return }
                if let response = result.element {
                    self.response.onNext(response)
                } else if let error = result.error {
                    self.errorResponse.onNext(error)
                }
            }, onError: { [weak self] error in
                self?.errorResponse.onNext(error)
            }).disposed(by: disposeBag)
    }
    
    
    func isValidDate(_ date: Date, workDays: [WorkdaysResponse.WorkDay])-> Bool {
        
        let calendarDate = DateFormatter.mmDdYyyyFormatter.string(from: date)
        return workDays.contains { $0.value == calendarDate }
    }
}
