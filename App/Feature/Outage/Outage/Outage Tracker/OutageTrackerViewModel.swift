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
            details = StatusDetailString.crewExtDamage
        } else if tracker.isSafetyHazard == true {
            details = StatusDetailString.crewSafetyHazard
        } else if tracker.isPartialRestoration == true {
            details = StatusDetailString.partialRestoration
        }
        return NSLocalizedString(details, comment: "")
    }
    var etaTitle: String {
        return NSLocalizedString("Estimated Time of Restoration (ETR)", comment: "")
    }
    var etaDateTime: String {
        return NSLocalizedString("January 1, 4:20 pm", comment: "")
    }
    var etaDetail: String {
        return NSLocalizedString("The current estimate is based on outage restoration history.", comment: "")
    }
    var etaOnSiteDetail: String {
        return NSLocalizedString("The current estimate is up-to-date based on the latest reports from the repair crew.", comment: "")
    }
    var etaCause: String {
        guard let tracker = outageTracker.value, let cause = tracker.cause else {
            return ""
        }
        return NSLocalizedString(cause, comment: "")
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
    var hideWhyButton: Bool {
        guard let tracker = outageTracker.value else { return true }
        
        if tracker.isSafetyHazard == true { return false }
        if status == .onSite && tracker.isCrewLeftSite == true {
            return false
        } else if status == .enRoute && tracker.isCrewDiverted == true {
            return false
        } else if status == .restored { return false }
        return true
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
                return ""
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
    
    func getOutageTracker(onSuccess: @escaping () -> Void, onError: @escaping (NetworkingError) -> Void) {
        OutageService.fetchOutageTracker(accountNumber: AccountsStore.shared.currentAccount.accountNumber) { [weak self] result in
            switch result {
                case .success(let outageTracker):
                    self?.outageTracker.accept(outageTracker)
                    onSuccess()
                case .failure(let error):
                    self?.outageTracker.accept(nil)
                    onError(error)
            }
        }
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


