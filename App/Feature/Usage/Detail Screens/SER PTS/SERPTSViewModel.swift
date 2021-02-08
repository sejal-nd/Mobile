//
//  SERPTSViewModel.swift
//  Mobile
//
//  Created by Sam Francis on 10/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class SERPTSViewModel {
    
    let disposeBag = DisposeBag()
    
    let accountDetail: AccountDetail
    let eventResults: Observable<[SERResult]>
    
    let graphViewModel: SERPTSGraphViewModel
    
    required init(accountDetail: AccountDetail, eventResults: [SERResult]?) {
        self.accountDetail = accountDetail
        if let eventResults = eventResults {
            self.eventResults = Observable.just(eventResults).share(replay: 1)
        } else {
            self.eventResults = AccountService.rx.fetchSERResults(accountNumber: accountDetail.accountNumber).share(replay: 1)
        }
        
        graphViewModel = SERPTSGraphViewModel(eventResults: self.eventResults)
    }
    
    var shouldShowSmartEnergyRewards: Bool {
        if Configuration.shared.opco != .peco {
            return accountDetail.isSERAccount || accountDetail.isPTSAccount
        }
        return false
    }
    
    private(set) lazy var shouldShowSmartEnergyRewardsContent = eventResults
        .map { !$0.isEmpty }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var smartEnergyRewardsSeasonLabelText: Driver<String?> = eventResults
        .map { eventResults in
            if let mostRecentEvent = eventResults.first {
                let latestEventYear = Calendar.opCo.component(.year, from: mostRecentEvent.eventStart)
                return String(format: NSLocalizedString("Summer %d", comment: ""), latestEventYear)
            }
            return nil
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var smartEnergyRewardsFooterText: Driver<String> = eventResults
        .map { eventResults in
            if !eventResults.isEmpty {
                return NSLocalizedString("You earn bill credits for every kWh you save. We calculate how much you save by comparing the energy you use on an Energy Savings Day to your typical use.", comment: "")
            } else {
                let programName = Configuration.shared.opco == .comEd ? NSLocalizedString("Peak Time Savings", comment: "") : NSLocalizedString("Smart Energy Rewards", comment: "")
                return NSLocalizedString("As a \(programName) customer, you can earn bill credits for every kWh you save. We calculate how much you save by comparing the energy you use on an Energy Savings Day to your typical use. Your savings information for the most recent \(programName) season will display here once available.", comment: "")
            }
        }
        .asDriver(onErrorDriveWith: .empty())
    
}
