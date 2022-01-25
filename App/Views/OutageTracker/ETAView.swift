//
//  ETAView.swift
//  EUMobile
//
//  Created by Gina Mullins on 1/11/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import UIKit

protocol ETAViewDelegate: AnyObject {
    func showInfoView()
}

class ETAView: UIView {
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet weak var etaTitleLabel: UILabel!
    @IBOutlet weak var etaDateTimeLabel: UILabel!
    @IBOutlet weak var etaDetailLabel: UILabel!
    @IBOutlet weak var etaCauseLabel: UILabel!
    @IBOutlet weak var etaUpdatedView: UIView!
    @IBOutlet weak var etaInfoButtonView: UIView!
    
    weak var delegate: ETAViewDelegate?
    var tracker: OutageTracker!
    var status: OutageTracker.Status!
    
    var isStormMode: Bool {
        return StormModeStatus.shared.isOn
    }
    
    var hideUpdatedView: Bool = true {
        didSet {
            etaUpdatedView.isHidden = hideUpdatedView
        }
    }
    var hideInfoButtonView: Bool = false {
        didSet {
            etaInfoButtonView.isHidden = hideInfoButtonView
        }
    }
    
    var etaDetail: String {
        return NSLocalizedString("The current estimate is based on outage restoration history. ETRs are updated as new information becomes available.", comment: "")
    }
    var etaDetailUnavailable: String {
        return NSLocalizedString("BGE team members are actively working to restore power and will provide an updated ETR as soon as new information becomes available.", comment: "")
    }
    var etaOnSiteDetail: String {
        return NSLocalizedString("The current ETR is up-to-date based on the latest reports from the repair crew. ETRs are updated as new information becomes available.", comment: "")
    }
    var etaDetailFeeder: String {
        return NSLocalizedString("We expect the vast majority of customers in your area impacted by the storm to be restored at this time. We are working to establish an ETR specific to your outage.", comment: "")
    }
    var etaDetailGlobal: String {
        return NSLocalizedString("We expect the vast majority of customers impacted by the storm to be restored by this time. We are working to establish an ETR specific to your outage.", comment: "")
    }
    var etaDetailOverrideOn: String {
        return NSLocalizedString("BGE team members are actively working to restore power outages resulting from stormy weather conditions and will provide an ETR as quickly as possible.", comment: "")
    }
    
    func configure(tracker: OutageTracker, status: OutageTracker.Status) {
        self.tracker = tracker
        self.status = status
        
        hideInfoButtonView = status == .restored
        hideUpdatedView = true
        
        etaTitleLabel.text = etaTitle()
        etaDateTimeLabel.text = etaDateTime()
        etaDetailLabel.text = etaDetails()
        
        let cause = etaCause()
        etaCauseLabel.text = cause
        etaCauseLabel.font = SystemFont.bold.of(textStyle: .footnote)
        etaCauseLabel.isHidden = cause.isEmpty
        
        switch status {
            case .restored, .none:
                etaDetailLabel.isHidden = true
                etaCauseLabel.font = SystemFont.regular.of(textStyle: .footnote)
            default:
                break
        }
    }
    
    func etaTitle() -> String {
        if status == .restored {
            return NSLocalizedString("Your power was restored at:", comment: "")
        } else {
            return NSLocalizedString("Estimated Time of Restoration (ETR)", comment: "")
        }
    }
    
    func etaDetails() -> String {
        var details: String = ""
        
        if etaDateTime() == "Currently Unavailable" {
            let overrideOn = tracker.etrOverrideOn?.uppercased() == "Y"
            details = overrideOn ? etaDetailOverrideOn : etaDetailUnavailable
        } else {
            if status == .onSite {
                details = etaOnSiteDetail
            } else {
                let type = tracker.etrType?.uppercased() ?? ""
                switch type {
                    case "G":
                        details = etaDetailGlobal
                    case "F":
                        details = etaDetailFeeder
                    default:
                        details = etaDetail
                }
            }
        }
        if !details.isEmpty {
            hideUpdatedView = hideETAUpdatedIndicator(detailText: details)
        }
        return details
    }
    
    func etaDateTime() -> String {
        let unavailable = NSLocalizedString("Currently Unavailable", comment: "")
        
        if status == .restored {
            guard let events = tracker.eventSet else {
                return unavailable
            }
            guard let timeRestoredString = events.filter( { $0.eventSetDescription == OutageTracker.Status.restored.rawValue }).first?.dateTime, let timeRestored = DateFormatter.apiFormatter.date(from: timeRestoredString) else {
                return unavailable
            }
            return DateFormatter.fullMonthDayAndTimeFormatter.string(from: timeRestored)
        } else {
            guard let etr = tracker.etr else {
                return unavailable
            }
            guard let date = DateFormatter.apiFormatter.date(from: etr), date >= Date() else {
                return unavailable
            }
            return DateFormatter.fullMonthDayAndTimeFormatter.string(from: date)
        }
    }
    
    func etaCause() -> String {
        guard let cause = tracker.cause?.lowercased(), !cause.isEmpty, cause != "none" else {
            return ""
        }
        return NSLocalizedString("The outage was caused by \(cause).", comment: "")
    }
    
    func hideETAUpdatedIndicator(detailText: String) -> Bool {
        if status == OutageTracker.Status.none || status == .reported {
            clearETA()
            return true
        }
        let defaults = UserDefaults.standard
        
        // check for changes in ETA to show updated pill
        let dateTime = defaults.object(forKey: "etaDateTime") as? String ?? ""
        let cause = defaults.object(forKey: "etaCause") as? String ?? ""
        let details = defaults.object(forKey: "etaDetail") as? String ?? detailText
        
        if dateTime != etaDateTime() || cause != etaCause() || details != detailText {
            // save new values
            defaults.set(etaDateTime(), forKey: "etaDateTime")
            defaults.set(etaCause(), forKey: "etaCause")
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
    
    @IBAction func infoButtonPressed(_ sender: Any) {
        if let delegate = self.delegate {
            delegate.showInfoView()
        }
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
        
        self.roundCorners(.allCorners, radius: 10, borderColor: .successGreenText, borderWidth: 1.0)
        self.clipsToBounds = true
        
        let updatedViewRadius = etaUpdatedView.frame.size.height / 2
        etaUpdatedView.roundCorners(.allCorners, radius: updatedViewRadius, borderColor: .successGreenText, borderWidth: 1.0)
        etaUpdatedView.isHidden = true
    }

}
