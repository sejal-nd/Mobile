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
}

class StatusView: UIView {

    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var statusTitleLabel: UILabel!
    @IBOutlet private weak var statusDateLabel: UILabel!
    @IBOutlet private weak var innerView: UIView!
    @IBOutlet private weak var outerView: UIView!
    @IBOutlet private weak var barView: UIView!
    @IBOutlet private weak var checkmarkImageView: UIImageView!
    @IBOutlet private weak var barWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var barTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var barBottomConstraint: NSLayoutConstraint!
    
    func configure(withEvent event: EventSet) {
        if let status = event.status, let state = TrackerState(rawValue: status) {
            update(forState: state)
            statusTitleLabel.text = event.eventSetDescription
            statusDateLabel.text = ""
            if let dateString = event.dateTime {
                if let date = DateFormatter.apiFormatter.date(from: dateString) {
                    let dateTime = DateFormatter.shortMonthDayAndTimeFormatter.string(from: date)
                    statusDateLabel.text = dateTime
                }
            }
            barWidthConstraint.constant = state == .completed ? 4 : 2
            barBottomConstraint.constant = state == .completed ? 3 : 0
            barTopConstraint.constant = state == .inProgress ? 3 : 0
            
            let eventStatus = OutageTracker.Status(rawValue: event.eventSetDescription ?? "")
            barView.isHidden = eventStatus == .restored
        }
    }
    
    private func update(forState state: TrackerState) {
        
        outerView.roundCorners(.allCorners, radius: 16, borderColor: .successGreenText, borderWidth: 1.0)
        innerView.roundCorners(.allCorners, radius: 12, borderColor: .successGreenText, borderWidth: 1.0)
        
        switch state {
            case .notStarted:
                innerView.backgroundColor = .white
                outerView.isHidden = true
                checkmarkImageView.isHidden = true
            case .inProgress:
                innerView.backgroundColor = .successGreenText
                outerView.isHidden = false
                checkmarkImageView.isHidden = true
            case .completed:
                innerView.backgroundColor = .successGreenText
                outerView.isHidden = true
                checkmarkImageView.isHidden = false
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
    }

}
