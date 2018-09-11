//
//  OutageStatusButton.swift
//  Mobile
//
//  Created by Marc Shilling on 9/8/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Lottie

protocol OutageStatusButtonDelegate: class {
    func outageStatusButtonWasTapped(_ outageStatusButton: OutageStatusButton)
}

class OutageStatusButton: UIView {
    
    weak var delegate: OutageStatusButtonDelegate?
    
    @IBOutlet weak private var view: UIView!
    
    @IBOutlet weak private var animationView: UIView!
    @IBOutlet weak private var outerCircleView: UIView!
    @IBOutlet weak private var innerCircleView: UIView!
    
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet weak var statusTitleLabel: UILabel! {
        didSet {
            statusTitleLabel.font = OpenSans.regular.of(size: 14)
            statusTitleLabel.textColor = .white
            statusTitleLabel.textAlignment = .center
        }
    }
    @IBOutlet weak var statusDetailLabel: UILabel! {
        didSet {
            statusDetailLabel.font = OpenSans.bold.of(size: 22)
            statusDetailLabel.textColor = .white
            statusDetailLabel.textAlignment = .center
        }
    }

    @IBOutlet weak var reportedView: UIView!
    @IBOutlet weak var reportedImageView: UIImageView!
    @IBOutlet weak var reportedTitleLabel: UILabel! {
        didSet {
            reportedTitleLabel.font = OpenSans.regular.of(size: 16)
            reportedTitleLabel.textColor = .white
            reportedTitleLabel.textAlignment = .center
        }
    }
    @IBOutlet weak var reportedDetailLabel: UILabel! {
        didSet {
            reportedDetailLabel.font = OpenSans.bold.of(size: 22)
            reportedDetailLabel.textColor = .white
            reportedDetailLabel.textAlignment = .center
        }
    }
    @IBOutlet weak var reportedETRTitleLabel: UILabel! {
        didSet {
            reportedETRTitleLabel.font = OpenSans.regular.of(size: 12)
            reportedETRTitleLabel.textColor = .white
            reportedETRTitleLabel.textAlignment = .center
        }
    }
    @IBOutlet weak var reportedETRLabel: UILabel! {
        didSet {
            reportedETRLabel.font = OpenSans.bold.of(size: 15)
            reportedETRLabel.textColor = .white
            reportedETRLabel.textAlignment = .center
            reportedETRLabel.adjustsFontSizeToFitWidth = true
            reportedETRLabel.minimumScaleFactor = 0.5
        }
    }
    
    @IBOutlet weak var inelligableView: UIView!
    @IBOutlet weak var inelligableDescriptionTextView: DataDetectorTextView! {
        didSet {
            inelligableDescriptionTextView.textContainerInset = .zero
            inelligableDescriptionTextView.font = SystemFont.light.of(size: 14)
            inelligableDescriptionTextView.tintColor = .actionBlue // For the phone numbers
            inelligableDescriptionTextView.textColor = .white
            inelligableDescriptionTextView.textAlignment = .center
        }
    }
    @IBOutlet weak var inelligablePayBillLabel: UILabel! {
        didSet {
            inelligablePayBillLabel.font = SystemFont.semibold.of(size: 16)
            inelligablePayBillLabel.textColor = .white
            inelligablePayBillLabel.textAlignment = .center
        }
    }

    var onLottieAnimation: LOTAnimationView?
    
    @IBInspectable
    public var isStormMode: Bool = false {
        didSet {
            onLottieAnimation?.removeFromSuperview()
            
            if isStormMode {
                onLottieAnimation = LOTAnimationView(name: "sm_outage")
            } else {
                onLottieAnimation = LOTAnimationView(name: "outage")
            }
            
            onLottieAnimation?.frame = CGRect(x: 0, y: 1, width: animationView.frame.size.width, height: animationView.frame.size.height)
            onLottieAnimation?.loopAnimation = true
            onLottieAnimation?.contentMode = .scaleAspectFill
            
            guard let onLottieAnimation = onLottieAnimation else { return }
            animationView.addSubview(onLottieAnimation)
            
            onLottieAnimation.play()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(OutageStatusButton.className, owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        addSubview(view)
        
        outerCircleView.layer.cornerRadius = outerCircleView.bounds.size.width / 2
        innerCircleView.layer.cornerRadius = innerCircleView.bounds.size.width / 2

        // Triggers Initial DidSet
        isStormMode = false

        setGrayCircles()
    }

    private func setGrayCircles() {
        outerCircleView.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.3)
        innerCircleView.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.1)
    }
    
    func setReportedState(estimatedRestorationDateString: String) {
        animationView.isHidden = true
        outerCircleView.isHidden = false
        
        statusView.isHidden = true
        inelligableView.isHidden = true
        reportedView.isHidden = false
        
        reportedImageView.image = #imageLiteral(resourceName: "ic_outagestatus_reported")
        reportedTitleLabel.text = NSLocalizedString("Your outage is", comment: "")
        reportedDetailLabel.text = NSLocalizedString("REPORTED", comment: "")
        reportedETRTitleLabel.text = NSLocalizedString("Estimated Restoration", comment: "")
        reportedETRLabel.text = estimatedRestorationDateString

        innerCircleView.accessibilityLabel = NSLocalizedString("Outage status, button. Your outage is reported. Estimated restoration \(estimatedRestorationDateString).", comment: "")
    }
    
    func setOutageState(estimatedRestorationDateString: String) {
        animationView.isHidden = true
        outerCircleView.isHidden = false
        
        statusView.isHidden = true
        inelligableView.isHidden = true
        reportedView.isHidden = false

        reportedImageView.image = #imageLiteral(resourceName: "ic_outagestatus_out")
        reportedTitleLabel.text = NSLocalizedString("Our records indicate your", comment: "")
        reportedDetailLabel.text = NSLocalizedString("POWER IS OUT", comment: "")
        reportedETRTitleLabel.text = NSLocalizedString("Estimated Restoration", comment: "")
        reportedETRLabel.text = estimatedRestorationDateString

        innerCircleView.accessibilityLabel = NSLocalizedString("Outage status, button. Our records indicate your power is out. Estimated restoration \(estimatedRestorationDateString).", comment: "")
    }
    
    func setIneligibleState(flagFinaled: Bool, nonPayFinaledMessage: String) {
        animationView.isHidden = true
        outerCircleView.isHidden = false
        
        statusView.isHidden = true
        inelligableView.isHidden = false
        reportedView.isHidden = true

        if Environment.shared.opco != .bge && !flagFinaled {
            inelligablePayBillLabel.text = NSLocalizedString("Pay Bill", comment: "")
        }

        inelligableDescriptionTextView.text = nonPayFinaledMessage

        innerCircleView.accessibilityLabel = NSLocalizedString("Outage status, button. \(nonPayFinaledMessage).", comment: "")
    }
    
    func setPowerOnState() {
        animationView.isHidden = false
        outerCircleView.isHidden = true
        
        statusView.isHidden = false
        inelligableView.isHidden = true
        reportedView.isHidden = true

        statusImageView.image = #imageLiteral(resourceName: "ic_outagestatus_on")
        statusTitleLabel.text = NSLocalizedString("Our records indicate", comment: "")
        statusDetailLabel.text = NSLocalizedString("POWER IS ON", comment: "")

        innerCircleView.accessibilityLabel = NSLocalizedString("Outage status, Button. Our records indicate your power is on.", comment: "")
    }

    @objc func onBigButtonTap() {
        delegate?.outageStatusButtonWasTapped(self)
    }
    
}
