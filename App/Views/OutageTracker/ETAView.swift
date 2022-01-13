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
    var etaOnSiteDetail: String {
        return NSLocalizedString("The current ETR is up-to-date based on the latest reports from the repair crew. ETRs are updated as new information becomes available.", comment: "")
    }
    
    func configure(tracker: OutageTracker, status: OutageTracker.Status) {
        self.tracker = tracker
        self.status = status
        
        etaTitleLabel.text = etaTitle()
        etaDateTimeLabel.text = etaDateTime()
        etaDetailLabel.text = etaDetails()
        
        let cause = etaCause()
        etaCauseLabel.text = cause
        etaCauseLabel.font = SystemFont.bold.of(textStyle: .footnote)
        etaCauseLabel.isHidden = cause.isEmpty
        
        hideInfoButtonView = status == .restored
        hideUpdatedView = true
        
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
        let details = status == .onSite ? etaOnSiteDetail : etaDetail
        if !details.isEmpty {
            hideUpdatedView = hideETAUpdatedIndicator(detailText: details)
        }
        return details
    }
    
    func etaDateTime() -> String {
        if let etr = tracker.etr {
            if let date = DateFormatter.apiFormatter.date(from: etr) {
                return DateFormatter.fullMonthDayAndTimeFormatter.string(from: date)
            }
        }
        return NSLocalizedString("Currently Unavailable", comment: "")
    }
    
    func etaCause() -> String {
        guard let cause = tracker.cause, !cause.isEmpty else {
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
        let details = defaults.object(forKey: "etaDetail") as? String ?? etaDetail
        
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
