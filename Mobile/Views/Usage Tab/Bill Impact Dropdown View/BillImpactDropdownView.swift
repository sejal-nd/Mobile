//
//  BillImpactDropdownView.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/13/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class BillImpactDropdownView: UIView {
    
    @IBOutlet var contentView: UIView! {
        didSet {
            addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 6)
        }
    }
    @IBOutlet weak var roundedBgView: UIView! {
        didSet {
            roundedBgView.layer.cornerRadius = 10
            roundedBgView.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var billFactorView: UIView!
    @IBOutlet weak var toggleButtonLabel: UILabel! {
        didSet {
            toggleButtonLabel.textColor = .actionBlue
        }
    }
    @IBOutlet weak var carrotImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel! {
        didSet {
            descriptionLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        }
    }
    @IBOutlet weak var contrastRoundedView: UIView! {
        didSet {
            contrastRoundedView.layer.cornerRadius = 10
        }
    }
    
    // Pill Buttons
    @IBOutlet weak var billPeriodCircleButton: UIView! {
        didSet {
            billPeriodCircleButton.layer.cornerRadius = billPeriodCircleButton.frame.height / 2
        }
    }
    @IBOutlet weak var billPeriodTitleLabel: UILabel! {
        didSet {
            billPeriodTitleLabel.font = OpenSans.regular.of(textStyle: .footnote)
        }
    }
    @IBOutlet weak var weatherCircleButton: UIView! {
        didSet {
            weatherCircleButton.layer.cornerRadius = weatherCircleButton.frame.height / 2
        }
    }
    @IBOutlet weak var weatherTitleLabel: UILabel! {
        didSet {
            weatherTitleLabel.font = OpenSans.regular.of(textStyle: .footnote)
        }
    }
    @IBOutlet weak var otherCircleButton: UIView! {
        didSet {
            otherCircleButton.layer.cornerRadius = otherCircleButton.frame.height / 2
        }
    }
    @IBOutlet weak var otherTitleLabel: UILabel! {
        didSet {
            otherTitleLabel.font = OpenSans.regular.of(textStyle: .footnote)
        }
    }
    @IBOutlet weak var bubbleView: UIView! {
        didSet {
            bubbleView.layer.cornerRadius = 10
            bubbleView.addShadow(color: .black, opacity: 0.08, offset: CGSize(width: 0, height: 2), radius: 8)
        }
    }
    @IBOutlet weak var bubbleViewTitleLabel: UILabel! {
        didSet {
            bubbleViewTitleLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        }
    }
    @IBOutlet weak var bubbleViewDescriptionLabel: UILabel! {
        didSet {
            bubbleViewDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        }
    }
    
    @IBOutlet weak var footerLabel: UILabel! {
        didSet {
            footerLabel.font = OpenSans.regular.of(textStyle: .footnote)
        }
    }
    
    private var isExpanded = false {
        didSet {
            if isExpanded {
                billFactorView.isHidden = false
                carrotImageView.image = #imageLiteral(resourceName: "ic_carat_up")
            } else {
                billFactorView.isHidden = true
                carrotImageView.image = #imageLiteral(resourceName: "ic_carat_down")
            }
        }
    }
    
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
        
        prepareViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
        
        prepareViews()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("BillImpactDropdownView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    private func prepareViews() {
        isExpanded = false
    }
    
    
    // MARK: - Configuration
    

    
    // MARK: - Actions
    
    @IBAction func toggleStackView(_ sender: Any) {
        isExpanded = !isExpanded
    }
    
}
