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
    
    func configure(withTitle title: String, detail: String, status: OutageTracker.Status) {
        
        statusTitleLabel.text = title
        statusDetailLabel.text = detail
        
        statusDetailView.isHidden = detail.isEmpty
        
        statusTitleLabel.textAlignment = .left
        detailLeadingConstraint.constant = 20
        detailTrailingConstraint.constant = 20
        titleLeadingConstraint.constant = 20
        titleTrailingConstraint.constant = 20
        
        if status == .none || status == .restored {
            statusTitleLabel.textAlignment = .center
            titleLeadingConstraint.constant = 30
            titleTrailingConstraint.constant = 30
        }
        
        let textColor = isStormMode ? UIColor.white : UIColor.deepGray
        statusTitleLabel.textColor = textColor
        statusDetailLabel.textColor = textColor
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
