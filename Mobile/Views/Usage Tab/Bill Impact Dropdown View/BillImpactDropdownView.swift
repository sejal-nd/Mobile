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
            addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
        }
    }
    @IBOutlet weak var roundedBgView: UIView! {
        didSet {
            roundedBgView.layer.cornerRadius = 10
            roundedBgView.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var likelyReasonsStackView: UIStackView!
    @IBOutlet weak var likelyReasonsDescriptionTriangleCenterXConstraint: NSLayoutConstraint!
    @IBOutlet weak var likelyReasonsDescriptionView: UIView!
    @IBOutlet weak var billFactorView: UIView! {
        didSet {
            billFactorView.isHidden = true
        }
    }
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
    
    // Buttons
    @IBOutlet weak var billPeriodButton: ButtonControl!
    @IBOutlet weak var billPeriodCircleButton: UIView! {
        didSet {
            billPeriodCircleButton.layer.cornerRadius = billPeriodCircleButton.frame.height / 2
            billPeriodCircleButton.layer.borderWidth = 2
            billPeriodCircleButton.layer.borderColor = UIColor.primaryColor.cgColor
            billPeriodCircleButton.addShadow(color: .black, opacity: 0.15, offset: CGSize(width: 0, height: 2), radius: 4)
        }
    }
    @IBOutlet weak var billPeriodTitleLabel: UILabel! {
        didSet {
            billPeriodTitleLabel.font = OpenSans.regular.of(textStyle: .footnote)
        }
    }
    @IBOutlet weak var weatherButton: ButtonControl!
    @IBOutlet weak var weatherCircleButton: UIView! {
        didSet {
            weatherCircleButton.layer.cornerRadius = weatherCircleButton.frame.height / 2
            weatherCircleButton.layer.borderWidth = 2
            weatherCircleButton.layer.borderColor = UIColor.clear.cgColor
            weatherCircleButton.addShadow(color: .black, opacity: 0.15, offset: CGSize(width: 0, height: 2), radius: 4)
        }
    }
    @IBOutlet weak var weatherTitleLabel: UILabel! {
        didSet {
            weatherTitleLabel.font = OpenSans.regular.of(textStyle: .footnote)
        }
    }
    @IBOutlet weak var otherButton: ButtonControl!
    @IBOutlet weak var otherCircleButton: UIView! {
        didSet {
            otherCircleButton.layer.cornerRadius = otherCircleButton.frame.height / 2
            otherCircleButton.layer.borderWidth = 2
            otherCircleButton.layer.borderColor = UIColor.clear.cgColor
            otherCircleButton.addShadow(color: .black, opacity: 0.15, offset: CGSize(width: 0, height: 2), radius: 4)
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
            bubbleView.addShadow(color: .black, opacity: 0.08, offset: CGSize(width: 0, height: 2), radius: 4)
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
    
    private var hasLoadedView = false
    
    private var isExpanded = false {
        didSet {
            guard hasLoadedView else { return }
            UIView.animate(withDuration: 0.3, animations: { [weak self] in
                if let isExpanded = self?.isExpanded, isExpanded {
                    self?.billFactorView.isHidden = false
                    self?.carrotImageView.image = #imageLiteral(resourceName: "ic_carat_up")
                } else {
                    self?.billFactorView.isHidden = true
                    self?.carrotImageView.image = #imageLiteral(resourceName: "ic_carat_down")
                }
                self?.contentStackView.layoutIfNeeded()
            })
        }
    }
    
    private var selectedPillView: UIView!{
        didSet {
            switch selectedPillView.tag {
            case 1:
                billPeriodCircleButton.layer.borderColor = UIColor.primaryColor.cgColor
                weatherCircleButton.layer.borderColor = UIColor.clear.cgColor
                otherCircleButton.layer.borderColor = UIColor.clear.cgColor
            case 2:
                billPeriodCircleButton.layer.borderColor = UIColor.clear.cgColor
                weatherCircleButton.layer.borderColor = UIColor.primaryColor.cgColor
                otherCircleButton.layer.borderColor = UIColor.clear.cgColor
            case 3:
                billPeriodCircleButton.layer.borderColor = UIColor.clear.cgColor
                weatherCircleButton.layer.borderColor = UIColor.clear.cgColor
                otherCircleButton.layer.borderColor = UIColor.primaryColor.cgColor
            default:
                break
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
        
        hasLoadedView = true
    }
    
    private func prepareViews() {
        // Default to collapsed
        isExpanded = false
        
        // Default button selected is Bill Period
        factorImpactPress(billPeriodButton)
    }
    
    
    // MARK: - Configuration
    
    func configureView() {
        // set data, handle no data states ect...
    }
    
    
    // MARK: - Actions
    
    @IBAction func toggleStackView(_ sender: Any) {
        isExpanded = !isExpanded
    }
    
    @IBAction func factorImpactPress(_ sender: ButtonControl) {
        selectedPillView = sender
        let centerPoint = sender.center
        let convertedPoint = likelyReasonsStackView.convert(centerPoint, to: likelyReasonsDescriptionView)
        
        let centerXOffset = (likelyReasonsDescriptionView.bounds.width / 2)
        if convertedPoint.x < centerXOffset {
            likelyReasonsDescriptionTriangleCenterXConstraint.constant = -1 * (centerXOffset - convertedPoint.x)
        } else if convertedPoint.x > centerXOffset {
            likelyReasonsDescriptionTriangleCenterXConstraint.constant = convertedPoint.x - centerXOffset
        } else {
            likelyReasonsDescriptionTriangleCenterXConstraint.constant = 0
        }
        
        if sender.tag == 1 {
            Analytics.log(event: .BillPreviousReason)
        } else if sender.tag == 2 {
            Analytics.log(event: .BillWeatherReason)
        } else {
            Analytics.log(event: .BillOtherReason)
        }
    }
    
}
