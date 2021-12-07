//
//  StatusView.swift
//  EUMobile
//
//  Created by Gina Mullins on 12/3/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

enum TrackerState: String {
    case notStarted = "not-started"
    case inProgress = "in-progress"
    case completed = "completed"
    
    var image: UIImage? {
        switch self {
            case .notStarted:
                return UIImage(named: "ic_appt_otw")
            case .inProgress:
                return UIImage(named: "ic_appt_inprogress")
            case .completed:
                return UIImage(named: "ic_appt_complete")
        }
    }
}

class StatusView: UIView {

    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var statusImageView: UIImageView!
    @IBOutlet private weak var statusTitleLabel: UILabel!
    @IBOutlet private weak var statusDateLabel: UILabel!
    @IBOutlet private weak var barView: UIView!
    @IBOutlet private weak var barWidthConstraint: NSLayoutConstraint!
    
    func configure(withEvent event: EventSet) {
        if let status = event.status, let state = TrackerState(rawValue: status) {
            statusImageView.image = state.image
            statusTitleLabel.text = event.eventSetDescription
            statusDateLabel.text = ""
            if let dateString = event.dateTime {
                if let date = DateFormatter.apiFormatter.date(from: dateString) {
                    let dateTime = DateFormatter.shortMonthDayAndTimeFormatter.string(from: date)
                    statusDateLabel.text = dateTime
                }
            }
            barWidthConstraint.constant = state == .completed ? 5 : 2
            let eventStatus = OutageTracker.Status(rawValue: event.eventSetDescription ?? "")
            barView.isHidden = eventStatus == .restored
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
        contentView.backgroundColor = UIColor.softGray
    }

}
