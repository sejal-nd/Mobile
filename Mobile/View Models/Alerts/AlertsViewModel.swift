//
//  AlertsViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 11/1/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class AlertsViewModel {
    
    let disposeBag = DisposeBag()
    
    let selectedSegmentIndex = Variable(0)
    
    required init() {
        
    }
    
    private(set) lazy var shouldShowAlertsTableView: Driver<Bool> = self.selectedSegmentIndex.asDriver().map { $0 == 0 }
    private(set) lazy var shouldShowUpdatesTableView: Driver<Bool> = self.selectedSegmentIndex.asDriver().map { $0 == 1 }

}
