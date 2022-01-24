//
//  StatusTextView.swift
//  EUMobile
//
//  Created by Gina Mullins on 1/11/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import UIKit

class StatusTextView: UIView {
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet weak var statusTitleView: UIView!
    @IBOutlet weak var statusDetailView: UIView!
    @IBOutlet weak var statusTitleLabel: UILabel!
    @IBOutlet weak var statusDetailLabel: UILabel!
    @IBOutlet weak var titleLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var detailLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var detailTrailingConstraint: NSLayoutConstraint!
    
    var isStormMode: Bool {
        return StormModeStatus.shared.isOn
    }
    var tracker: OutageTracker!
    var status: OutageTracker.Status!
    
    func configure(tracker: OutageTracker, status: OutageTracker.Status) {
        self.tracker = tracker
        self.status = status
        
        statusTitleLabel.text = getTitle()
        
        let details = getDetail()
        statusDetailLabel.text = details
        
        statusDetailView.isHidden = details.isEmpty
        
        statusTitleLabel.textAlignment = .left
        detailLeadingConstraint.constant = 20
        detailTrailingConstraint.constant = 20
        titleLeadingConstraint.constant = 20
        titleTrailingConstraint.constant = 20
        
        if status == .none || status == .restored {
            statusTitleLabel.textAlignment = .center
            titleLeadingConstraint.constant = 40
            titleTrailingConstraint.constant = 39
        }
        
        let textColor = isStormMode ? UIColor.white : UIColor.deepGray
        statusTitleLabel.textColor = textColor
        statusDetailLabel.textColor = textColor
    }
    
    private func getTitle() -> String {
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
            else if tracker.isSafetyHazard == true {
                return StatusTitleString.onSiteTempStop
            }
        }
        
        let isDefinitive = tracker.meterStatus?.uppercased() == "ON"
        if status == .restored && !isDefinitive {
            return StatusTitleString.restoredNonDef
        }
        return status.statusTitleString
    }
    
    private func getDetail() -> String {
        var details = ""
        let isDefinitive = tracker.meterStatus?.uppercased() == "ON"
        
        if status == .restored {
            details = timeToRestore().detailText(isDefinitive: isDefinitive)
        } else if status == OutageTracker.Status.none {
            return StatusDetailString.none
        } 
        else {
            if status == .onSite {
                if tracker.isCrewExtDamage == true {
                    details = StatusDetailString.crewExtDamage
                } else if tracker.isPartialRestoration == true {
                    let count = tracker.customersOutOnOutage ?? ""
                    details = String.localizedStringWithFormat(StatusDetailString.partialRestoration, count)
                }
            } else if status == .reported {
                if tracker.isCrewDiverted == true {
                    details = StatusDetailString.crewLeftSite
                }
            }
        }
        
        return details
    }
    
    func timeToRestore() -> TimeToRestore {
        var restoreTime: TimeToRestore = .none
        let isDefinitive = tracker.meterStatus?.uppercased() == "ON"
        let events = tracker.eventSet ?? []
        
        guard let timeReportedString = events.filter( { $0.eventSetDescription == OutageTracker.Status.reported.rawValue }).first?.dateTime, let timeReported = DateFormatter.apiFormatter.date(from: timeReportedString) else {
            return .none
        }
        guard let timeRestoredString = events.filter( { $0.eventSetDescription == OutageTracker.Status.restored.rawValue }).first?.dateTime, let timeRestored = DateFormatter.apiFormatter.date(from: timeRestoredString) else {
            return .none
        }
        
        let diffComponents = Calendar.current.dateComponents([.minute], from: timeReported, to: timeRestored)
        let mins = diffComponents.minute ?? 60
        
        if isDefinitive {
            if mins <= 45 {
                restoreTime = .short
            } else if mins > 45 && mins < 180 {
                restoreTime = .regular
            } else {
                restoreTime = .long
            }
        } else {
            if mins < 180 {
                restoreTime = .regular
            } else {
                restoreTime = .long
            }
        }
        
        return restoreTime
    }
    
    
    // MARK: Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(self.className, owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

}

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

struct StatusDetailString {
    static let crewLeftSite = NSLocalizedString("The outage affecting your address requires additional repair work to be completed at another location before we can begin work in your area. We appreciate your patience during this difficult restoration process.", comment: "")
    static let crewDiverted = NSLocalizedString("This can occur during severe emergencies or potentially hazardous situations. A new BGE crew will be dispatched as soon as possible to retore your service.", comment: "")
    static let crewExtDamage = NSLocalizedString("We have multiple crews on site working hard to restore your power. Thank you for your patience.", comment: "")
    static let partialRestoration = "BGE was able to restore service to some customers in your area, but due to the location of the damage, you and %@ others are still affected by this outage."
    static let none = NSLocalizedString("We’re actively trying to fix the problem, please check back soon. If your power is not on, please help us by reporting the outage.", comment: "")
    
    // restored
    static let restoredDefLong = NSLocalizedString("Our systems indicate that the power has been restored to your address. We understand that you have been without power for an extended time. We appreciate your patience during this difficult restoration process.", comment: "")
    static let restoredDefReg = NSLocalizedString("Our systems indicate that the power has been restored to your address.", comment: "")
    static let restoredDefShort = NSLocalizedString("Our systems indicate that the power has been restored to your address. We understand that even brief power outages can be a significant inconvenience, and we appreciate your patience.", comment: "")
    static let restoredNonDefLong = NSLocalizedString("We have received notification from our repair crew that the power at your address has been restored. However, we have not yet received confirmation from your smart meter. We understand that you have been without power for an extended time. We appreciate your patience during this difficult restoration process.", comment: "")
    static let restoredNonDefReg = NSLocalizedString("We have received notification from our repair crew that the power at your address has been restored. However, we have not yet received confirmation from your smart meter.", comment: "")
}

