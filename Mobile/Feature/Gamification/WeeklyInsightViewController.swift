//
//  WeeklyInsightViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/25/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class WeeklyInsightViewController: UIViewController {
    
    @IBOutlet weak var segmentedControlContainer: UIView!
    @IBOutlet weak var segmentedControl: SegmentedControl!
    
    @IBOutlet weak var contentContainer: UIView!
    @IBOutlet weak var thisWeekDateLabel: UILabel!
    @IBOutlet weak var thisWeekBarView: UIView!
    @IBOutlet weak var thisWeekBarWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var lastWeekDateLabel: UILabel!
    @IBOutlet weak var lastWeekBarView: UIView!
    @IBOutlet weak var lastWeekBarWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var comparisonLabel: UILabel!
    @IBOutlet weak var mostEnergyLabel: UILabel!
    @IBOutlet weak var leastEnergyLabel: UILabel!
    @IBOutlet weak var billProjectionLabel: UILabel!
    
    @IBOutlet weak var stickyFooterLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addCloseButton()

        title = NSLocalizedString("Weekly Insight", comment: "")
        
        segmentedControl.items = [
            NSLocalizedString("Electric", comment: ""),
            NSLocalizedString("Gas", comment: "")
        ]
                
        thisWeekDateLabel.textColor = .deepGray
        thisWeekDateLabel.font = SystemFont.semibold.of(textStyle: .footnote)
        
        thisWeekBarView.backgroundColor = .primaryColor
        thisWeekBarView.layer.cornerRadius = 7.5
        
        lastWeekDateLabel.textColor = .deepGray
        lastWeekDateLabel.font = SystemFont.semibold.of(textStyle: .footnote)
        
        lastWeekBarView.backgroundColor = .accentGray
        lastWeekBarView.layer.cornerRadius = 7.5

        comparisonLabel.textColor = .deepGray
        comparisonLabel.font = SystemFont.regular.of(textStyle: .body)
        
        mostEnergyLabel.textColor = .deepGray
        mostEnergyLabel.font = SystemFont.regular.of(textStyle: .body)
        
        leastEnergyLabel.textColor = .deepGray
        leastEnergyLabel.font = SystemFont.regular.of(textStyle: .body)
        
        billProjectionLabel.textColor = .deepGray
        billProjectionLabel.font = SystemFont.regular.of(textStyle: .body)
        
        stickyFooterLabel.textColor = .deepGray
        stickyFooterLabel.font = SystemFont.regular.of(textStyle: .caption1)
        stickyFooterLabel.text = NSLocalizedString("This is an estimate and the actual amount may vary based on your energy use, taxes, and fees.", comment: "")
    }
    



}
