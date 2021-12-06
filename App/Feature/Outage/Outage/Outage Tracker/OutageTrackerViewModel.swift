//
//  OutageTrackerViewModel.swift
//  EUMobile
//
//  Created by Cody Dillon on 12/1/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import RxSwift

class OutageTrackerViewModel {
    
    let disposeBag = DisposeBag()
    var outageTracker: Observable<OutageTracker?> = nil
    
    var status: OutageTracker.Status {
        if let trackerStatus = outageTracker?.trackerStatus {
            return OutageTracker.Status(rawValue: trackerStatus) ?? .none
        }
        
        return .none
    }
}


