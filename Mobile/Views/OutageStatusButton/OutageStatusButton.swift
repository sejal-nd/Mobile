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
    @IBOutlet weak private var outerCircleView: UIView! {
        didSet {
            outerCircleView.layer.cornerRadius = outerCircleView.bounds.size.width / 2
            outerCircleView.layer.borderWidth = 6
        }
    }
    @IBOutlet weak private var innerCircleView: UIView! {
        didSet {
            innerCircleView.layer.cornerRadius = innerCircleView.bounds.size.width / 2
            innerCircleView.layer.borderWidth = 6
            innerCircleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onBigButtonTap)))
        }
    }
    
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet weak var statusTitleLabel: UILabel! {
        didSet {
            statusTitleLabel.font = OpenSans.regular.of(size: 14)
        }
    }
    @IBOutlet weak var statusDetailLabel: UILabel! {
        didSet {
            statusDetailLabel.font = OpenSans.bold.of(size: 22)
        }
    }

    @IBOutlet weak var statusETRView: UIView!
    @IBOutlet weak var statusETRImageView: UIImageView!
    @IBOutlet weak var statusETRLabel: UILabel! {
        didSet {
            statusETRLabel.font = OpenSans.regular.of(size: 16)
        }
    }
    @IBOutlet weak var reportedDetailLabel: UILabel! {
        didSet {
            reportedDetailLabel.font = OpenSans.bold.of(size: 22)
        }
    }
    @IBOutlet weak var reportedETRTitleLabel: UILabel! {
        didSet {
            reportedETRTitleLabel.font = OpenSans.regular.of(size: 12)
        }
    }
    @IBOutlet weak var reportedETRLabel: UILabel! {
        didSet {
            reportedETRLabel.font = OpenSans.bold.of(size: 15)
            reportedETRLabel.adjustsFontSizeToFitWidth = true
            reportedETRLabel.minimumScaleFactor = 0.5
        }
    }
    
    @IBOutlet weak var inelligableView: UIView!
    @IBOutlet weak var inelligableDescriptionTextView: DataDetectorTextView! {
        didSet {
            inelligableDescriptionTextView.textContainerInset = .zero
            inelligableDescriptionTextView.font = SystemFont.light.of(size: 14)
        }
    }
    @IBOutlet weak var inelligablePayBillLabel: UILabel! {
        didSet {
            inelligablePayBillLabel.font = SystemFont.semibold.of(size: 16)
        }
    }

    private var innerBorderColor: UIColor {
        let color: UIColor
        switch Environment.shared.opco {
        case .bge:
            color = .primaryColor
        case .comEd:
            color = .primaryColor
        case .peco:
            color = isStormMode ? UIColor(red:0/255.0, green:162/255.0, blue:255/255.0,  alpha:1) : .primaryColor
        }
        return color
    }
    
    private var outterBorderColor: UIColor {
        let color: UIColor
        switch Environment.shared.opco {
        case .bge:
            color = isStormMode ? .clear : UIColor(red: 61/255, green: 132/255, blue: 48/255, alpha:0.6)
        case .comEd:
            color = isStormMode ? .clear : UIColor(red: 206/255, green: 17/255, blue: 65/255, alpha:0.6)
        case .peco:
            color = isStormMode ? .clear : UIColor(red: 0/255, green: 119/255, blue: 187/255, alpha:0.6)
        }
        return color
    }

    var onLottieAnimation: LOTAnimationView?
    
    @IBInspectable
    public var isStormMode: Bool = false {
        didSet {
            onLottieAnimation?.removeFromSuperview()
            
            if isStormMode {
                onLottieAnimation = LOTAnimationView(name: "sm_outage")
                
                outerCircleView.isHidden = true
                
                statusTitleLabel.textColor = .white
                statusDetailLabel.textColor = .white
                
                statusETRLabel.textColor = .white
                reportedDetailLabel.textColor = .white
                reportedETRTitleLabel.textColor = .white
                reportedETRLabel.textColor = .white
                
                inelligablePayBillLabel.textColor = .white
                inelligableDescriptionTextView.tintColor = .white // For the phone numbers
                inelligableDescriptionTextView.textColor = .white
            } else {
                onLottieAnimation = LOTAnimationView(name: "outage")
                
                outerCircleView.isHidden = false
                outerCircleView.layer.borderColor = UIColor.red.cgColor // CHANGE
                
                statusTitleLabel.textColor = .actionBlue
                statusDetailLabel.textColor = .actionBlue
                
                statusETRLabel.textColor = .actionBlue
                reportedDetailLabel.textColor = .actionBlue
                reportedETRTitleLabel.textColor = .deepGray
                reportedETRLabel.textColor = .deepGray
                
                inelligablePayBillLabel.textColor = .actionBlue
                inelligableDescriptionTextView.tintColor = .actionBlue // For the phone numbers
                inelligableDescriptionTextView.textColor = .middleGray
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

        // Triggers Initial DidSet
        isStormMode = false
    }

    private func setStateColors(innerBackground: UIColor, innerStroke: UIColor, outerStroke: UIColor = .clear) {
        innerCircleView.backgroundColor = innerBackground
        innerCircleView.layer.borderColor = innerStroke.cgColor
        outerCircleView.layer.borderColor = outerStroke.cgColor
    }
    
    func setReportedState(estimatedRestorationDateString: String) {
        animationView.isHidden = true
        outerCircleView.isHidden = false
        
        statusView.isHidden = true
        inelligableView.isHidden = true
        statusETRView.isHidden = false
        
        // Styling
        
        if isStormMode {
            statusETRImageView.image = #imageLiteral(resourceName: "ic_reportoutage")
            setStateColors(innerBackground: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.1),
                           innerStroke: innerBorderColor)
        } else {
            setStateColors(innerBackground: .white,
                           innerStroke: innerBorderColor,
                           outerStroke: outterBorderColor)
            statusETRImageView.image = #imageLiteral(resourceName: "ic_outagestatus_reported")
        }
        
        // Set Values
        
        statusETRLabel.text = NSLocalizedString("Your outage is", comment: "")
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
        statusETRView.isHidden = false

        // Styling
        
        if isStormMode {
            setStateColors(innerBackground: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.1),
                           innerStroke: UIColor(red:255/255.0, green:255/255.0, blue:255/255.0,  alpha:0.3))
            statusETRImageView.image = #imageLiteral(resourceName: "ic_outagestatus_out_white")
        } else {
            setStateColors(innerBackground: .white,
                           innerStroke: .middleGray,
                           outerStroke: UIColor(red:187/255.0, green:187/255.0, blue:187/255.0,  alpha:1))
            statusETRImageView.image = #imageLiteral(resourceName: "ic_outagestatus_out")
        }
        
        // Set Values
        
        statusETRLabel.text = NSLocalizedString("Our records indicate", comment: "")
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
        statusETRView.isHidden = true

        // Set Values
        
        if isStormMode {
            setStateColors(innerBackground: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.1),
                           innerStroke: UIColor(red:255/255.0, green:255/255.0, blue:255/255.0,  alpha:0.3))
        } else {
            setStateColors(innerBackground: .white,
                           innerStroke: .middleGray,
                           outerStroke: UIColor(red:187/255.0, green:187/255.0, blue:187/255.0,  alpha:1))
        }
        
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
        statusETRView.isHidden = true

        // Styling
        
        if isStormMode {
            setStateColors(innerBackground: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.1),
                           innerStroke: UIColor.clear)
            statusImageView.image = #imageLiteral(resourceName: "ic_lightbulb_on_white")
        } else {
            setStateColors(innerBackground: .white,
                           innerStroke: .white,
                           outerStroke: .clear)
            statusImageView.image = #imageLiteral(resourceName: "ic_outagestatus_on")
        }
        
        // Set Values
        
        statusTitleLabel.text = NSLocalizedString("Our records indicate", comment: "")
        statusDetailLabel.text = NSLocalizedString("POWER IS ON", comment: "")

        innerCircleView.accessibilityLabel = NSLocalizedString("Outage status, Button. Our records indicate your power is on.", comment: "")
    }

    @objc func onBigButtonTap() {
        delegate?.outageStatusButtonWasTapped(self)
    }
    
}
