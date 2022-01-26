//
//  TrackerStatusView.swift
//  EUMobile
//
//  Created by Gina Mullins on 12/3/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

class TrackerStatusView: UIView {
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var dateLabel: UILabel!
    
    var isStormMode: Bool {
        return StormModeStatus.shared.isOn
    }
    
    func configure(withEvents events: [EventSet], lastUpdated time: String, isPaused: Bool) {
        stackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        for event in events {
            let statusView = StatusView()
            statusView.configure(withEvent: event, isPaused: isPaused)
            stackView.addArrangedSubview(statusView)
        }
        dateLabel.text = "Last Update: \(time)"
        let textColor = isStormMode ? UIColor.white : UIColor.deepGray
        dateLabel.textColor = textColor
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