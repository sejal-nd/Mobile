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
    
    @IBOutlet weak var barGraphStackView: UIStackView!
    
    @IBOutlet weak var bar1ContainerButton: ButtonControl!
    @IBOutlet weak var bar1DollarLabel: UILabel!
    @IBOutlet weak var bar1BarView: UIView!
    @IBOutlet weak var bar1DateLabel: UILabel!
    @IBOutlet weak var bar1HeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bar2ContainerButton: ButtonControl!
    @IBOutlet weak var bar2DollarLabel: UILabel!
    @IBOutlet weak var bar2BarView: UIView!
    @IBOutlet weak var bar2DateLabel: UILabel!
    @IBOutlet weak var bar2HeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bar3ContainerButton: ButtonControl!
    @IBOutlet weak var bar3DollarLabel: UILabel!
    @IBOutlet weak var bar3BarView: UIView!
    @IBOutlet weak var bar3DateLabel: UILabel!
    @IBOutlet weak var bar3HeightConstraint: NSLayoutConstraint!
    
    // Bill Comparison - Bar Graph Description View
    @IBOutlet weak var barDescriptionView: UIView!
    @IBOutlet weak var barDescriptionDateLabel: UILabel!
    @IBOutlet weak var barDescriptionPeakHoursLabel: UILabel!
    @IBOutlet weak var barDescriptionTypicalUseTitleLabel: UILabel!
    @IBOutlet weak var barDescriptionTypicalUseValueLabel: UILabel!
    @IBOutlet weak var barDescriptionActualUseTitleLabel: UILabel!
    @IBOutlet weak var barDescriptionActualUseValueLabel: UILabel!
    @IBOutlet weak var barDescriptionEnergySavingsTitleLabel: UILabel!
    @IBOutlet weak var barDescriptionEnergySavingsValueLabel: UILabel!
    @IBOutlet weak var barDescriptionBillCreditTitleLabel: UILabel!
    @IBOutlet weak var barDescriptionBillCreditValueLabel: UILabel!
    @IBOutlet weak var barDescriptionTriangleCenterXConstraint: NSLayoutConstraint!
    
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
        
        backgroundColor = .clear
        
        styleViews()
    }
    
    private func styleViews() {
        // Bar Graph Text Colors
        bar1DollarLabel.textColor = .deepGray
        bar1DateLabel.textColor = .blackText
        bar2DollarLabel.textColor = .blackText
        bar2DateLabel.textColor = .blackText
        bar3DollarLabel.textColor = .blackText
        bar3DateLabel.textColor = .blackText
        
        barDescriptionView.addShadow(color: .black, opacity: 0.08, offset: .zero, radius: 2)
        barDescriptionDateLabel.textColor = .blackText
        barDescriptionDateLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        barDescriptionPeakHoursLabel.textColor = .blackText
        barDescriptionPeakHoursLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        barDescriptionTypicalUseTitleLabel.textColor = .blackText
        barDescriptionTypicalUseTitleLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        barDescriptionTypicalUseValueLabel.textColor = .blackText
        barDescriptionTypicalUseValueLabel.font = OpenSans.regular.of(textStyle: .footnote)
        barDescriptionActualUseTitleLabel.textColor = .blackText
        barDescriptionActualUseTitleLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        barDescriptionActualUseValueLabel.textColor = .blackText
        barDescriptionActualUseValueLabel.font = OpenSans.regular.of(textStyle: .footnote)
        barDescriptionEnergySavingsTitleLabel.textColor = .blackText
        barDescriptionEnergySavingsTitleLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        barDescriptionEnergySavingsValueLabel.textColor = .blackText
        barDescriptionEnergySavingsValueLabel.font = OpenSans.regular.of(textStyle: .footnote)
        barDescriptionBillCreditTitleLabel.textColor = .blackText
        barDescriptionBillCreditTitleLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        barDescriptionBillCreditValueLabel.textColor = .blackText
        barDescriptionBillCreditValueLabel.font = OpenSans.regular.of(textStyle: .footnote)
    }

}
