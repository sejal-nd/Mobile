//
//  OutageStatusView.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/12/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Lottie
import UIKit

protocol OutageStatusDelegate: class {
    func didPressButton(button: UIButton, outageState: OutageState)
}

class OutageStatusView: UIView {
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var animationContentView: UIView!
    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet weak var statusHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var statusWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleDescriptionLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    @IBOutlet weak var button: UIButton!
    
    private var lottieAnimationView: LOTAnimationView?
    
    private var outageStatus: OutageStatus?
    private var reportedOutage: ReportedOutageResult?
    
    private var outageState: OutageState = .powerStatus(true) {
        didSet {
            configureOutageState(outageState)
        }
    }
    
    private var estimatedRestorationDateString: String {
        if let reportedOutage = reportedOutage {
            if let reportedETR = reportedOutage.etr {
                return DateFormatter.outageOpcoDateFormatter.string(from: reportedETR)
            }
        } else {
            if let statusETR = outageStatus?.etr {
                return DateFormatter.outageOpcoDateFormatter.string(from: statusETR)
            }
        }
        return NSLocalizedString("Assessing Damage", comment: "")
    }
    
    private var descriptionText: String {
        if Environment.shared.opco == .bge {
            return NSLocalizedString("Outage status and report an outage may not be available for this account. Please call Customer Service at 1-877-778-2222 for further information.", comment: "")
        } else {
            var text = ""
            switch outageState {
            case .unavailable:
                text = NSLocalizedString("Outage Status and Outage Reporting are not available for this account.", comment: "")
            case .nonPayment:
                text = NSLocalizedString("Our records indicate that you have been cut for non-payment. If you wish to restore your power, please make a payment.", comment: "")
            default:
                break
            }
            return text
        }
    }
    
    weak var delegate: OutageStatusDelegate?
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed(OutageStatusView.className, owner: self, options: nil)
        
        self.frame = contentView.frame
        addSubview(contentView)
        
        style()
    }
    
    private func style() {
        titleDescriptionLabel.textColor = .blackText
        titleDescriptionLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        titleLabel.textColor = .deepGray
        titleLabel.font = OpenSans.semibold.of(textStyle: .title3)
        
        descriptionLabel.textColor = .deepGray
        descriptionLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        
        detailDescriptionLabel.textColor = .deepGray
        detailDescriptionLabel.font = OpenSans.regular.of(textStyle: .caption1)
        detailLabel.textColor = .deepGray
        detailLabel.font = OpenSans.semibold.of(textStyle: .caption1)
    }
    
    
    // MARK: - Action
    
    @IBAction func buttonPress(_ sender: UIButton) {
        delegate?.didPressButton(button: sender, outageState: outageState)
    }
}


// MARK: - Configure Outage State

extension OutageStatusView {
    public func setOutageStatus(_ outageStatus: OutageStatus,
                                reportedResults: ReportedOutageResult? = nil,
                                hasJustReported: Bool = false) {
        self.outageStatus = outageStatus
        self.reportedOutage = reportedResults
        outageState = OutageStatus.getOutageState(outageStatus, reportedResults: reportedResults, hasJustReported: hasJustReported)
        
        // Populate Data
        descriptionLabel.text = descriptionText
        detailLabel.text = estimatedRestorationDateString
    }
    
    private func configureOutageState(_ outageState: OutageState) {
        switch outageState {
        case .powerStatus(let isOn):
            lottieAnimationView?.removeFromSuperview()
            if isOn {
                lottieAnimationView = LOTAnimationView(name: "outage_on")
                titleLabel.text = NSLocalizedString("POWER IS ON", comment: "")
                detailDescriptionLabel.isHidden = true
                detailLabel.isHidden = true
            } else {
                lottieAnimationView = LOTAnimationView(name: "outage_off")
                titleLabel.text = NSLocalizedString("POWER IS OUT", comment: "")
                detailDescriptionLabel.isHidden = false
                detailLabel.isHidden = false
            }
            statusImageView.isHidden = true
            statusHeightConstraint.constant = 107
            statusWidthConstraint.constant = 107
            
            titleDescriptionLabel.isHidden = false
            titleDescriptionLabel.text = NSLocalizedString("Our records indicate", comment: "")
            descriptionLabel.isHidden = true
            button.isHidden = false
            UIView.performWithoutAnimation {
                button.setTitle(NSLocalizedString("View Details", comment: ""), for: .normal)
                button.layoutIfNeeded()
            }
        case .reported:
            lottieAnimationView?.removeFromSuperview()
            lottieAnimationView = LOTAnimationView(name: "outage_reported")
            statusImageView.isHidden = true
            statusHeightConstraint.constant = 107
            statusWidthConstraint.constant = 107
            
            titleDescriptionLabel.text = NSLocalizedString("Your outage is", comment: "")
            titleLabel.text = NSLocalizedString("REPORTED", comment: "")
            descriptionLabel.isHidden = true
            detailDescriptionLabel.isHidden = false
            detailLabel.isHidden = false
            UIView.performWithoutAnimation {
                button.setTitle(NSLocalizedString("View Details", comment: ""), for: .normal)
                button.layoutIfNeeded()
            }
        case .unavailable:
            lottieAnimationView?.removeFromSuperview()
            statusImageView.isHidden = false
            statusHeightConstraint.constant = 125
            statusWidthConstraint.constant = 125
            
            titleLabel.text = NSLocalizedString("Outage Unavailable", comment: "")
            titleDescriptionLabel.isHidden = true
            descriptionLabel.isHidden = false
            detailDescriptionLabel.isHidden = true
            detailLabel.isHidden = true
            button.isHidden = true
        case .nonPayment:
            lottieAnimationView?.removeFromSuperview()
            statusImageView.isHidden = false
            statusHeightConstraint.constant = 125
            statusWidthConstraint.constant = 125
            
            titleLabel.text = NSLocalizedString("Outage Unavailable", comment: "")
            titleDescriptionLabel.isHidden = true
            descriptionLabel.isHidden = false
            detailDescriptionLabel.isHidden = true
            detailLabel.isHidden = true
            button.isHidden = false
            
            UIView.performWithoutAnimation {
                button.setTitle(NSLocalizedString("Pay Bill", comment: ""), for: .normal)
                button.layoutIfNeeded()
            }
        }
        
        lottieAnimationView?.frame = CGRect(x: 0, y: 1, width: animationContentView.frame.size.width, height: animationContentView.frame.size.height)
        lottieAnimationView?.loopAnimation = true
        lottieAnimationView?.contentMode = .scaleAspectFill
        
        guard let lottieAnimationView = lottieAnimationView else { return }
        animationContentView.addSubview(lottieAnimationView)
        
        lottieAnimationView.play()
    }
}
