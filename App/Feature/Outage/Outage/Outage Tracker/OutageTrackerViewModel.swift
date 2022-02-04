//
//  OutageTrackerViewModel.swift
//  EUMobile
//
//  Created by Cody Dillon on 12/1/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

class OutageTrackerViewModel {
    let disposeBag = DisposeBag()
    var outageTracker = BehaviorRelay<OutageTracker?>(value: nil)
    var outageStatus = BehaviorRelay<OutageStatus?>(value: nil)
    
    var status: OutageTracker.Status {
        guard let trackerStatus = outageTracker.value?.trackerStatus else {
            return .none
        }
        return OutageTracker.Status(rawValue: trackerStatus) ?? .none
    }
    var events: [EventSet] {
        guard let events = outageTracker.value?.eventSet else {
            return []
        }
        return events
    }
    var neighborCount: String {
        guard let count = outageTracker.value?.customersOutOnOutage else {
            return "Unavailable"
        }
        return NSLocalizedString(count, comment: "")
    }
    var outageCount: String {
        guard let count = outageTracker.value?.outageSummary else {
            return "Unavailable"
        }
        return NSLocalizedString(count, comment: "")
    }
    var isActiveOutage: Bool {
        guard let tracker = outageTracker.value else {
            return true
        }
        return tracker.isOutageValid
    }
    var isGasOnly: Bool {
        return outageStatus.value?.isGasOnly ?? false
    }
    var isPaused: Bool {
        guard let tracker = outageTracker.value else {
            return false
        }
        if tracker.isCrewLeftSite == true || tracker.isCrewDiverted == true {
            return true
        }
        return false
    }
    var isDefinitive: Bool {
        guard let tracker = outageTracker.value, let status = tracker.meterStatus else {
            return false
        }
        return status.uppercased() == "ON"
    }
    var lastUpdated: String {
        var time = ""
        if let dateString = outageTracker.value?.lastUpdated {
            if let date = DateFormatter.apiFormatter.date(from: dateString) {
                time = DateFormatter.hmmaFormatter.string(from: date)
            }
        }
        return time
    }
    var hideWhyButton: Bool {
        guard let tracker = outageTracker.value else { return true }
        guard let isCrewLeftSite = tracker.isCrewLeftSite,
              let isCrewDiverted = tracker.isCrewDiverted else {
                  return true
              }
        
        if status == .restored { return false }
        if status == .onSite {
            if isCrewLeftSite || isCrewDiverted {
                return false
            }
        } else if status == .enRoute {
            if isCrewDiverted {
                return false
            }
        }
        
        return true
    }
    var whyButtonText: String {
        if status == .restored {
             return NSLocalizedString("Still Have an Outage?", comment: "")
        } else {
             return NSLocalizedString("Why Did This Happen?", comment: "")
        }
    }
    var footerText: NSAttributedString {
        let phone1 = "1-800-685-0123"
        let phone2 = "1-877-778-7798"
        let phone3 = "1-877-778-2222"
        let phoneNumbers = [phone1, phone2, phone3]
        let localizedString = String.localizedStringWithFormat(
                """
                If you smell natural gas, leave the area immediately and call %@ or %@\n
                For downed or sparking power lines, please call %@ or %@
                """
                ,phone1, phone2, phone1, phone3)

        let attributedText = NSMutableAttributedString(string: localizedString, attributes: [.font: SystemFont.regular.of(textStyle: .caption1)])
        for phone in phoneNumbers {
            localizedString.ranges(of: phone, options: .regularExpression)
                .map { NSRange($0, in: localizedString) }
                .forEach {
                    attributedText.addAttribute(.font, value: SystemFont.semibold.of(textStyle: .caption1), range: $0)
                }
        }
        return attributedText
    }
    
    func fetchOutageTracker() {
        AccountService.rx.fetchAccountDetails(payments: false, programs: false).flatMap {
            return OutageService.rx.fetchOutageTracker(
                accountNumber: $0.accountNumber,
                deviceId: $0.premiseInfo.first?.servicePoints.first?.usagePointLocation?.mRID ?? "",
                servicePointId: $0.premiseInfo.first?.servicePoints.first?.serviceLocation?.mRID ?? "")
        }.subscribe(onNext: { tracker in
            self.outageTracker.accept(tracker)
        }, onError: { error in
            self.outageTracker.accept(nil)
            Log.info("error fetching tracker: \(error.localizedDescription)")
        }).disposed(by: disposeBag)
    }
    
    func getOutageStatus() {
        OutageService.fetchOutageStatus(accountNumber: AccountsStore.shared.currentAccount.accountNumber, premiseNumberString: AccountsStore.shared.currentAccount.currentPremise?.premiseNumber ?? "") { [weak self] result in
            switch result {
                case .success(let outageStatus):
                    self?.outageStatus.accept(outageStatus)
                    self?.fetchOutageTracker()
                case .failure(let error):
                    Log.info("Outage Status error: \(error.localizedDescription)")
                    self?.outageStatus.accept(nil)
            }
        }
    }
}


