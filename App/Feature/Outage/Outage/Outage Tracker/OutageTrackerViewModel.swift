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
        guard let events = outageTracker.value?.eventSet else { return mockEvents }
        return events
    }
    var statusTitle: String {
        //return NSLocalizedString(status.statusTitleString, comment: "")
        return "BGE has received a report of an outage at your address."
    }
    var statusDetails: String {
        guard let tracker = outageTracker.value else { return "We have multiple crews on site working hard to restore your power. Thank you for your patience."
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
    
    // todo - where does this come from?
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
        return NSLocalizedString("378", comment: "")
    }
    var outageCount: String {
        return NSLocalizedString("1,271", comment: "")
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
    
    var mockEvents: [EventSet] {
        var events: [EventSet] = []
        
        let event1 = EventSet(status: "completed", eventSetDescription: "Outage Reported", dateTime: "2021-10-28T04:20:39")
        events.append(event1)
        
        let event2 = EventSet(status: "in-progress", eventSetDescription: "Crew Assigned", dateTime: "2021-10-29T04:20:39")
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
                    self?.outageStatus.accept(nil)
            }
        }
    }
}


