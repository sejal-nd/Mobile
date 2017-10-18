//
//  HomeUsageCardViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 10/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class HomeUsageCardViewModel {
    
    let disposeBag = DisposeBag()
    
    let accountDetailEvents: Observable<Event<AccountDetail>>
    private let usageService: UsageService
    
    let fetchingTracker: ActivityTracker
    let loadingTracker = ActivityTracker()
    
    let electricGasSelectedSegmentIndex = Variable(0)
    
    var initialLoadComplete = false
    
    required init(accountDetailEvents: Observable<Event<AccountDetail>>,
                  usageService: UsageService,
                  fetchingTracker: ActivityTracker) {
        self.accountDetailEvents = accountDetailEvents
        self.usageService = usageService
        self.fetchingTracker = fetchingTracker
    }
    
    private(set) lazy var billComparisonEvents: Observable<Event<BillComparison>> = Observable.combineLatest(self.accountDetailEvents.elements(),
                                                                                                             self.electricGasSelectedSegmentIndex.asObservable())
        .flatMapLatest { [unowned self] accountDetail, segmentIndex -> Observable<Event<BillComparison>> in
            guard let premiseNumber = accountDetail.premiseNumber else { return .empty() }
            guard let serviceType = accountDetail.serviceType else { return .empty() }
            if serviceType.uppercased() != "GAS" && serviceType.uppercased() != "ELECTRIC" && serviceType.uppercased() != "GAS/ELECTRIC" {
                 return .empty()
            }

            var gas = false // Default to electric
            if serviceType.uppercased() == "GAS" { // If account is gas only
                gas = true
            } else if serviceType.uppercased() == "GAS/ELECTRIC" { // Use value of segmented control
                gas = segmentIndex == 1
            }
            
            let activeTracker = self.initialLoadComplete ? self.loadingTracker : self.fetchingTracker
            return self.usageService.fetchBillComparison(accountNumber: accountDetail.accountNumber, premiseNumber: premiseNumber, yearAgo: false, gas: gas)
                .do(onNext: { [weak self] _ in
                    self?.initialLoadComplete = true
                })
                .trackActivity(activeTracker)
                .materialize()
            
        }.shareReplay(1)
    
//    private(set) lazy var accountDetailDriver: Driver<AccountDetail> = self.accountDetailEvents.elements().asDriver(onErrorDriveWith: .empty())
//    private(set) lazy var billComparisonDriver: Driver<BillComparison> = self.billComparisonEvents.elements().asDriver(onErrorDriveWith: .empty())
//    private(set) lazy var billComparisonError: Observable<Bool> = self.billComparisonEvents.errors().map {
//        if let serviceError = $0 as? ServiceError {
//            return true
//        }
//        return false
//    }
    
    private(set) lazy var shouldShowErrorView: Driver<Bool> =
        Observable.combineLatest(self.loadingTracker.asObservable(), self.billComparisonEvents) {
            !$0 && $1.error != nil
        }.asDriver(onErrorDriveWith: .empty())
    
    
    private(set) lazy var shouldShowBillComparisonContentView: Driver<Bool> =
        Observable.combineLatest(self.loadingTracker.asObservable(), self.billComparisonEvents) {
            !$0 && $1.error == nil
        }.asDriver(onErrorDriveWith: .empty())

}
