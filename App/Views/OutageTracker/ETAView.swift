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
    let viewModel = ETAViewModel()
    
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
            details = overrideOn ? viewModel.etaDetailOverrideOn : viewModel.etaDetailUnavailable
        } else {
            if status == .onSite {
                details = viewModel.etaOnSiteDetail
            } else {
                let type = tracker.etrType?.uppercased() ?? ""
                switch type {
                    case "G":
                        details = viewModel.etaDetailGlobal
                    case "F":
                        details = viewModel.etaDetailFeeder
                    default:
                        details = viewModel.etaDetail
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
        guard let cause = tracker.cause, !cause.isEmpty else {
            return ""
        }
        guard let key = viewModel.causes[cause], let causeText = viewModel.causeText[key] else {
            return ""
        }
        
        return NSLocalizedString(causeText, comment: "")
    }
    
    func hideETAUpdatedIndicator(detailText: String) -> Bool {
        if status == OutageTracker.Status.none {
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
            
            if dateTime.isEmpty && cause.isEmpty {
                // first time
                return true
            }
            
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

extension ETAView {
    
}
