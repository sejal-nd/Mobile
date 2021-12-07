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
    
    var status: OutageTracker.Status {
        guard let trackerStatus = outageTracker.value?.trackerStatus else {
            return .none
        }
        return OutageTracker.Status(rawValue: trackerStatus) ?? .none
    }
    
    var events: [EventSet] {
        guard let events = outageTracker.value?.eventSet else { return [] }
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
    
}


