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
            return mockEvents
        }
        return events
    }
    var statusTitle: String {
        return NSLocalizedString(status.statusTitleString, comment: "")
    }
    var statusDetails: String {
        guard let tracker = outageTracker.value else {
            return StatusDetailString.trackerNone
        }
        var details = ""
        if tracker.isCrewDiverted == true {
            details = StatusDetailString.crewDiverted
        } else if tracker.isCrewLeftSite == true {
            details = StatusDetailString.crewLeftSite
        } else if tracker.isCrewExtDamage == true {
            details = StatusDetailString.CrewExtDamage
        }
        return NSLocalizedString(details, comment: "")
    }
    
    // todo - where does these come from?
    var etaTitle: String {
        return NSLocalizedString("Estimated Time of Restoration (ETR)", comment: "")
    }
    var etaDateTime: String {
        return NSLocalizedString("January 1, 4:20 pm", comment: "")
    }
    var etaDetail: String {
        return NSLocalizedString("The current estimate is based on outage restoration history.", comment: "")
    }
    var etaCause: String {
        return NSLocalizedString("The outage was caused by a lightening strike", comment: "")
    }
    var neighborCount: String {
        // todo - this field is missing
        guard let tracker = outageTracker.value, let count = tracker.customersOutOnOutage else { return "" }
        return NSLocalizedString(count, comment: "")
    }
    var outageCount: String {
        guard let tracker = outageTracker.value, let count = tracker.customersOutOnOutage else { return "" }
        return NSLocalizedString(count, comment: "")
    }
    var lastUpdated: String {
        var time = ""
        guard let tracker = outageTracker.value else { return "" }
        if let dateString = tracker.lastUpdated {
            if let date = DateFormatter.apiFormatter.date(from: dateString) {
                time = DateFormatter.hmmaFormatter.string(from: date)
            }
        }
        
        return time
    }
    var isPartialRestoration: Bool {
        guard let tracker = outageTracker.value else { return false }
        return tracker.isPartialRestoration ?? false
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
    
    var animationName: String {
        switch status {
            case .reported:
                return "ot_reported"
            case .assigned:
                return "ot_assigned"
            case .enRoute:
                return "ot_enroute"
            case .onSite:
                return "ot_onsite"
            case .restored:
                return "Appt_Complete-FlavorBGE"
            default:
                return "Appt_Complete-FlavorBGE"
        }
    }
    
    var mockEvents: [EventSet] {
        var events: [EventSet] = []
        
        let event1 = EventSet(status: "not-started", eventSetDescription: "Outage Reported", dateTime: nil)
        events.append(event1)
        
        let event2 = EventSet(status: "not-started", eventSetDescription: "Crew Assigned", dateTime: nil)
        events.append(event2)
        
        let event3 = EventSet(status: "not-started", eventSetDescription: "Crew En Route", dateTime: nil)
        events.append(event3)
        
        let event4 = EventSet(status: "not-started", eventSetDescription: "Crew On Site", dateTime: nil)
        events.append(event4)
        
        let event5 = EventSet(status: "not-started", eventSetDescription: "Power Restored", dateTime: nil)
        events.append(event5)
        
        return events
        
    }
    
    func fetchOutageTracker() {
        AccountService.rx.fetchAccountSummary(includeDevice: true, includeMDM: false).flatMap {
            OutageService.rx.fetchOutageTracker(accountNumber: $0.accountNumber, deviceId: $0.deviceId ?? "", servicePointId: $0.servicePointId ?? "")
        }.subscribe(onNext: { tracker in
            self.outageTracker.accept(tracker)
        }, onError: { error in
            self.outageTracker.accept(nil)
            print("error fetching tracker: \(error.localizedDescription)")
        }).disposed(by: disposeBag)
    }
    
    func getOutageStatus() {
        OutageService.fetchOutageStatus(accountNumber: AccountsStore.shared.currentAccount.accountNumber, premiseNumberString: AccountsStore.shared.currentAccount.currentPremise?.premiseNumber ?? "") { [weak self] result in
            switch result {
                case .success(let outageStatus):
                    self?.outageStatus.accept(outageStatus)
                case .failure(let error):
                    print("Outage Status error: \(error.localizedDescription)")
                    self?.outageStatus.accept(nil)
            }
        }
    }
}


