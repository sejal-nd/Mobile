//
//  UsageTabViewModel.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/20/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class UsageTabViewModel {
    
    let disposeBag = DisposeBag()
    
    let accountService: AccountService
    
    
    var accountDetail: AccountDetail? {
        didSet {
            guard let accountDetail = accountDetail else { return }
            
            switch Environment.shared.opco {
            case .bge:
                if accountDetail.peakRewards == "ACTIVE" {
                    usageToolCards.insert(MyUsageToolCard(image: #imageLiteral(resourceName: "ic_budgetlearn"), title: "PeakRewards"), at: 1)
                }
                
                if accountDetail.isSERAccount {
                    usageToolCards.append(MyUsageToolCard(image: #imageLiteral(resourceName: "ic_budgetlearn"), title: "Smart Energy Rewards"))
                }
            case .comEd:
                usageToolCards.insert(MyUsageToolCard(image: #imageLiteral(resourceName: "ic_budgetlearn"), title: "PeakRewards"), at: 1)

                if accountDetail.isPTSAccount {
                    usageToolCards.append(MyUsageToolCard(image: #imageLiteral(resourceName: "ic_budgetlearn"), title: "Peak Time Savings"))
                }
            case .peco:
                break
            }
        }
    }
    
    var isFetchingAccountDetail = false
    
    let usageService: UsageService
    
    
    /*
     * 0 = No Data
     * 1 = Previous
     * 2 = Current
     * 3 = Projected
     * 4 = Projection Not Available
     */
    let barGraphSelectionStates = [false, false, false, false, false]
    
    
    
    
    /*
     * 0 = View My Usage Data
     * 1 = Peak Rewards
     * 2 = Hourly Pricing
     * 3 = Top 5 Energy Tips
     * 4 = My Home Profile
     * 5 = Smart ENergy Rewards
     * 6 = Peak Time Savings
     */
    
    
    //var shouldShowUsageStates = [true, false, false, true, true, false, false]
    var usageToolCards = [MyUsageToolCard(image: #imageLiteral(resourceName: "ic_budgetlearn"), title: "View My Usage Data"), MyUsageToolCard(image: #imageLiteral(resourceName: "ic_budgetlearn"), title: "Top 5 Energy Tips"), MyUsageToolCard(image: #imageLiteral(resourceName: "ic_budgetlearn"), title: "My Home Profile")]
    
//    var isLoading = false {
//        didSet {
//
//        }
//    }
    
    
    required init(accountService: AccountService, usageService: UsageService) {
        self.accountService = accountService
        self.usageService = usageService
    }
    
//    deinit {
//        if let disposable = currentFetchDisposable {
//            disposable.dispose()
//        }
//    }

    func fetchData(onSuccess: (() -> Void)?) {
        guard let currentAccount = AccountsStore.shared.currentAccount else { return }
        isFetchingAccountDetail = true
        //isFetchingUpdates.value = true
        //isAccountDetailError.value = false
        //isUpdatesError.value = false
        //isNoNetworkConnection.value = false
        
        accountService.fetchAccountDetail(account: currentAccount)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] accountDetail in
                guard let `self` = self else { return }
                self.accountDetail = accountDetail
                self.isFetchingAccountDetail = false
                
                onSuccess?()
                print("ACCOUNT DETAIL@@@@@@@: \(accountDetail)")
                //self.isNoNetworkConnection.value = false
                //self.a11yScreenChangedEvent.onNext(())
//                self.alertsService.fetchOpcoUpdates(accountDetail: accountDetail)
//                    .observeOn(MainScheduler.instance)
//                    .subscribe(onNext: { [weak self] opcoUpdates in
//                        self?.currentOpcoUpdates.value = opcoUpdates
//                        self?.isFetchingUpdates.value = false
//                        self?.isNoNetworkConnection.value = false
//                        self?.reloadUpdatesTableViewEvent.onNext(())
//                        self?.a11yScreenChangedEvent.onNext(())
//                        }, onError: { [weak self] err in
//                            self?.isFetchingUpdates.value = false
//                            self?.isUpdatesError.value = true
//                            if let error = err as? ServiceError {
//                                self?.isNoNetworkConnection.value = error.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue
//                            }
//                    }).disposed(by: self.disposeBag)
                }, onError: { [weak self] err in
                    self?.isFetchingAccountDetail = false
                    print("Failure")
                    //self?.isFetchingUpdates.value = false
                    //self?.isAccountDetailError.value = true
                    //self?.isUpdatesError.value = true
//                    if let error = err as? ServiceError {
//                        self?.isNoNetworkConnection.value = error.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue
//                    }
            }).disposed(by: disposeBag)
    }
    
//    func fetchBillComparison() -> Observable<Void> {
//        noPreviousData = false
//        currentBillComparison = nil
//
//        // The premiseNumber force unwrap is safe because it's checked in BillViewModel: shouldShowNeedHelpUnderstanding
//        return usageService.fetchBillComparison(accountNumber: accountDetail.accountNumber,
//                                                premiseNumber: accountDetail.premiseNumber!,
//                                                yearAgo: lastYearPreviousBillSelectedSegmentIndex.value == 0,
//                                                gas: isGas).map { [weak self] billComparison in
//                                                    self?.currentBillComparison.value = billComparison
//                                                    if billComparison.compared == nil {
//                                                        self?.noPreviousData.value = true
//                                                    }
//        }
//    }
//
//    func fetchBillForecast() -> Observable<Void> {
//        return usageService.fetchBillForecast(accountNumber: accountDetail.accountNumber, premiseNumber: accountDetail.premiseNumber!).map { [weak self] forecastResults in
//            if let elecResult = forecastResults[0] {
//                self?.electricForecast.value = elecResult
//            }
//            if let gasResult = forecastResults[1] {
//                self?.gasForecast.value = gasResult
//            }
//        }
//    }
//
//    // MARK: Projection Bar Drivers
//
//    private(set) lazy var projectedCost: Driver<Double?> =
//        Driver.combineLatest(self.electricForecast.asDriver(),
//                             self.gasForecast.asDriver(),
//                             self.electricGasSelectedSegmentIndex.asDriver()) { [weak self] elecForecast, gasForecast, segmentIndex in
//                                // We only combine electricGasSelectedSegmentIndex here to trigger a driver update, then we use self.isGas to determine
//                                guard let `self` = self else { return nil }
//                                if let gasForecast = gasForecast, self.isGas {
//                                    return gasForecast.projectedCost
//                                }
//                                if let elecForecast = elecForecast, !self.isGas {
//                                    return elecForecast.projectedCost
//                                }
//                                return nil
//    }
//
//    private(set) lazy var projectedUsage: Driver<Double?> =
//        Driver.combineLatest(self.electricForecast.asDriver(),
//                             self.gasForecast.asDriver(),
//                             self.electricGasSelectedSegmentIndex.asDriver()) { [weak self] elecForecast, gasForecast, segmentIndex in
//                                // We only combine electricGasSelectedSegmentIndex here to trigger a driver update, then we use self.isGas to determine
//                                guard let `self` = self else { return nil }
//                                if let gasForecast = gasForecast, self.isGas {
//                                    return gasForecast.projectedUsage
//                                }
//                                if let elecForecast = elecForecast, !self.isGas {
//                                    return elecForecast.projectedUsage
//                                }
//                                return nil
//    }
    
}
