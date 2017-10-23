//
//  SmartEnergyRewardsView.swift
//  Mobile
//
//  Created by Marc Shilling on 10/23/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class SmartEnergyRewardsView: UIView {

    @IBOutlet weak var view: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var seasonLabel: UILabel!
    
    @IBOutlet weak var barGraphStackView: UIStackView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(SmartEnergyRewardsView.className, owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        addSubview(view)
        
        styleViews()
    }
    
    private func styleViews() {
        titleLabel.textColor = .blackText
        titleLabel.font = OpenSans.bold.of(textStyle: .title1)
        titleLabel.text = Environment.sharedInstance.opco == .comEd ? NSLocalizedString("Peak Time Savings", comment: "") :
            NSLocalizedString("Smart Energy Rewards", comment: "")
        
        seasonLabel.textColor = .deepGray
        seasonLabel.font = OpenSans.semibold.of(textStyle: .subheadline)
    }

}
