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

enum TimeToRestore: Int {
    case short
    case regular
    case long
    case none
    
    func detailText(isDefinitive: Bool) -> String {
        switch self {
            case .short:
                return StatusDetailString.restoredDefShort
            case .regular:
                return isDefinitive ? StatusDetailString.restoredDefReg : StatusDetailString.restoredNonDefReg
            case .long:
                return isDefinitive ? StatusDetailString.restoredDefLong : StatusDetailString.restoredNonDefLong
            case .none: return ""
        }
    }
}

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
        guard let tracker = outageTracker.value else {
            return StatusTitleString.none
        }
        if status == .enRoute && tracker.isCrewDiverted == true {
            return StatusTitleString.enRouteRerouted
        }
        if status == .onSite {
            if tracker.isCrewExtDamage == true {
                return StatusTitleString.onSiteExtDamage
            }
            else if tracker.isCrewDiverted == true {
                return StatusTitleString.onSiteTempStop
            }
            else if tracker.isCrewLeftSite == true {
                return StatusTitleString.onSiteTempStop
            }
        }
        if status == .restored && !isDefinitive {
            return StatusTitleString.restoredNonDef
        }
        return status.statusTitleString
    }
    var statusDetails: String {
        guard let tracker = outageTracker.value else {
            return StatusDetailString.none
        }
        var details = ""
        if status == .restored {
            details = timeToRestore().detailText(isDefinitive: isDefinitive)
        } else if status == .none {
            return StatusDetailString.none
        } else {
            if tracker.isCrewExtDamage == true {
                details = StatusDetailString.crewExtDamage
            } else if tracker.isSafetyHazard == true {
                details = StatusDetailString.crewSafetyHazard
            } else if tracker.isPartialRestoration == true {
                let count = tracker.customersOutOnOutage ?? ""
                details = String.localizedStringWithFormat(StatusDetailString.partialRestoration, count)
            }
        }
        
        return details
    }
    var etaTitle: String {
        if status == .restored {
            return NSLocalizedString("Your power was restored at:", comment: "")
        } else {
            return NSLocalizedString("Estimated Time of Restoration (ETR)", comment: "")
        }
    }
    var etaDateTime: String {
        if let etr = outageTracker.value?.etr {
            if let date = DateFormatter.apiFormatter.date(from: etr) {
                return DateFormatter.fullMonthDayAndTimeFormatter.string(from: date)
            }
        }
        return NSLocalizedString("Currently Unavailable", comment: "")
    }
    var etaDetail: String {
        return NSLocalizedString("The current estimate is based on outage restoration history. ETRs are updated as new information becomes available.", comment: "")
    }
    var etaOnSiteDetail: String {
        return NSLocalizedString("The current ETR is up-to-date based on the latest reports from the repair crew. ETRs are updated as new information becomes available.", comment: "")
    }
    var etaCause: String {
        guard let cause = outageTracker.value?.cause, !cause.isEmpty else {
            return ""
        }
        return NSLocalizedString("The outage was caused by \(cause).", comment: "")
    }
    var neighborCount: String {
        // todo - this field is missing
        guard let count = outageTracker.value?.customersOutOnOutage else {
            return ""
        }
        return NSLocalizedString(count, comment: "")
    }
    var outageCount: String {
        guard let count = outageTracker.value?.customersOutOnOutage else {
            return ""
        }
        return NSLocalizedString(count, comment: "")
    }
    var isActiveOutage: Bool {
        // restored state shows as no longer active but may have tracker data
        if outageStatus.value?.isActiveOutage == true {
            return true
        } else {
            guard let tracker = outageTracker.value else {
                return false
            }
            return tracker.isOutageValid
        }
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
        // todo: where does this come from
        return outageStatus.value?.isSmartMeter ?? false
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
        
        if tracker.isSafetyHazard == true { return false }
        if status == .onSite {
            if tracker.isCrewLeftSite == true || tracker.isCrewDiverted == true {
                return false
            }
        } else if status == .enRoute && tracker.isCrewDiverted == true {
            return false
        } else if status == .restored { return false }
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
    var surveyURL: String {
        switch status {
            case .reported:
                return "https://www.surveymonkey.com/r/HHCD7YP"
            case .assigned:
                return "https://www.surveymonkey.com/r/HPSN8XX"
            case .enRoute:
                return "https://www.surveymonkey.com/r/HPTDG6T"
            case .onSite:
                return "https://www.surveymonkey.com/r/HPXXPCW"
            case .restored:
                return "https://www.surveymonkey.com/r/HPXZBBD"
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
    
    func hideETAUpdatedIndicator(detailText: String) -> Bool {
        if status == .none || status == .reported {
            clearETA()
            return true
        }
        let defaults = UserDefaults.standard
        
        // check for changes in ETA to show updated pill
        let dateTime = defaults.object(forKey: "etaDateTime") as? String ?? ""
        let cause = defaults.object(forKey: "etaCause") as? String ?? ""
        let details = defaults.object(forKey: "etaDetail") as? String ?? etaDetail
        
        if dateTime != etaDateTime || cause != etaCause || details != detailText {
            // save new values
            defaults.set(etaDateTime, forKey: "etaDateTime")
            defaults.set(etaCause, forKey: "etaCause")
            defaults.set(detailText, forKey: "etaDetail")
            
            return false
        } else {
            return true
        }
    }
    
    func clearETA() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "etaDateTime")
        defaults.removeObject(forKey: "etaCause")
        defaults.removeObject(forKey: "etaDetail")
    }
    
    func timeToRestore() -> TimeToRestore {
        var restoreTime: TimeToRestore = .none
        
        guard let timeReportedString = events.filter( { $0.eventSetDescription == OutageTracker.Status.reported.rawValue }).first?.dateTime, let timeReported = DateFormatter.apiFormatter.date(from: timeReportedString) else {
            return .none
        }
        guard let timeRestoredString = events.filter( { $0.eventSetDescription == OutageTracker.Status.restored.rawValue }).first?.dateTime, let timeRestored = DateFormatter.apiFormatter.date(from: timeRestoredString) else {
            return .none
        }
    
        let diffComponents = Calendar.current.dateComponents([.hour], from: timeReported, to: timeRestored)
        let hours = diffComponents.hour ?? 1
        
        if isDefinitive {
            if hours == 0 {
                restoreTime = .short
            } else if hours >= 1 && hours < 3 {
                restoreTime = .regular
            } else {
                restoreTime = .long
            }
        } else {
            if hours < 3 {
                restoreTime = .regular
            } else {
                restoreTime = .long
            }
        }
        
        return restoreTime
    }
    
    func fetchOutageTracker() {
        AccountService.rx.fetchAccountSummary(includeDevice: true, includeMDM: true).flatMap {
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


