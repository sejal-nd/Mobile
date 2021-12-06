//
//  StatusView.swift
//  EUMobile
//
//  Created by Gina Mullins on 12/3/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

enum TrackerStatus: String {
    case notStarted = "not-started"
    case inProgress = "in-progress"
    case completed = "completed"
    
    var image: UIImage? {
        switch self {
            case .notStarted:
                return UIImage(named: "todo")
            case .inProgress:
                return UIImage(named: "todo")
            case .completed:
                return UIImage(named: "todo")
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
    
    init(withEvent event: EventSet) {
        let status = TrackerState(rawValue: event.status)
        statusImageView.image = status.image
        statusTitleLabel.text = event.eventSetDescription
        if let dateString = event.dateTime {
            let date = DateFormatter.yyyyMMddTHHmmssSSSFormatter.date(from: dateString)
            let dateTime = DateFormatter.shortMonthDayAndTimeFormatter.string(from: date)
            statusDateLabel.text = dateTime
        }
        barWidthConstraint.constant = status.completed ? 5 : 2
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
