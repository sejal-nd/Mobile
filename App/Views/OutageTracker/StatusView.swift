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
    case completed = "complete"
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
    @IBOutlet private weak var innerViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var innerViewHeightConstraint: NSLayoutConstraint!
    
    var isStormMode: Bool {
        return StormModeStatus.shared.isOn
    }
    
    func configure(withEvent event: EventSet, isPaused: Bool) {
        if let status = event.status, let state = TrackerState(rawValue: status) {
            let eventStatus = OutageTracker.Status(rawValue: event.eventSetDescription ?? "")
            
            let lastOne = eventStatus == .restored
            barView.isHidden = lastOne
            
            update(forState: state, isPaused: isPaused, isLast: lastOne)
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
            
            let textColor = isStormMode ? UIColor.white : UIColor.neutralDark
            statusTitleLabel.textColor = textColor
            statusDateLabel.textColor = textColor
        }
    }
    
    private func update(forState state: TrackerState, isPaused: Bool, isLast: Bool) {
        var innerViewConstant: CGFloat = 26.0
        
        let imageName = isStormMode ? "ic_check_white_sm" : "ic_check_white"
        checkmarkImageView.image = UIImage(named: imageName)
        
        statusTitleLabel.font = UIFont.subheadlineSemibold
        
        let emptyColor: UIColor = isStormMode ? .clear : .white
        let fillColor: UIColor = isStormMode ? .secondaryGreen : .secondaryBlue
        
        switch state {
            case .notStarted:
                innerView.backgroundColor = emptyColor
                outerView.isHidden = true
                checkmarkImageView.isHidden = true
            case .inProgress:
                innerView.backgroundColor = isPaused ? emptyColor : fillColor
                outerView.backgroundColor = emptyColor
                outerView.isHidden = false
                checkmarkImageView.isHidden = true
                statusTitleLabel.font = UIFont.subheadlineSemibold
                innerViewConstant = 24
            case .completed:
                innerView.backgroundColor = fillColor
                outerView.isHidden = true
                checkmarkImageView.isHidden = false
                if isLast {
                    statusTitleLabel.font = UIFont.subheadlineSemibold
                }
        }
        
        innerViewWidthConstraint.constant = innerViewConstant
        innerViewHeightConstraint.constant = innerViewConstant
        innerView.roundCorners(.allCorners, radius: innerViewConstant/2, borderColor: fillColor, borderWidth: 2.0)
        
        outerView.roundCorners(.allCorners, radius: 17, borderColor: fillColor, borderWidth: 2.0)
        
        let barViewRadius = barView.frame.size.width
        barView.roundCorners(.allCorners, radius: barViewRadius, borderColor: fillColor, borderWidth: 0.0)
        barView.backgroundColor = fillColor
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
