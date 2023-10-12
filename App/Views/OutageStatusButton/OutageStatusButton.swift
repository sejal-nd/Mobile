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
            outerCircleView.layer.borderWidth = 2
        }
    }
    @IBOutlet weak private var innerCircleView: UIView! {
        didSet {
            innerCircleView.layer.borderWidth = 2
            innerCircleView.isAccessibilityElement = true
            innerCircleView.accessibilityTraits = .button
            innerCircleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onBigButtonTap)))
        }
    }
    
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet weak var statusTitleLabel: UILabel! {
        didSet {
            statusTitleLabel.font = .subheadlineSemibold
        }
    }
    @IBOutlet weak var statusDetailLabel: UILabel! {
        didSet {
            statusDetailLabel.font = .title2
        }
    }

    @IBOutlet weak var statusETRView: UIView!
    @IBOutlet weak var statusETRImageView: UIImageView!
    @IBOutlet weak var statusETRLabel: UILabel! {
        didSet {
            statusETRLabel.font = .subheadlineSemibold
        }
    }
    @IBOutlet weak var reportedDetailLabel: UILabel! {
        didSet {
            reportedDetailLabel.font = .title2
        }
    }
    @IBOutlet weak var reportedETRTitleLabel: UILabel! {
        didSet {
            reportedETRTitleLabel.font = .caption1
        }
    }
    @IBOutlet weak var reportedETRLabel: UILabel! {
        didSet {
            reportedETRLabel.font = .footnoteSemibold
            reportedETRLabel.adjustsFontSizeToFitWidth = true
            reportedETRLabel.minimumScaleFactor = 0.5
        }
    }

    private var innerBorderColor: UIColor {
        return isStormMode ? .secondaryGreen : .primaryColor
    }
    
    private var outterBorderColor: UIColor {
        return isStormMode ? .clear : UIColor.primaryColor.withAlphaComponent(0.6)
    }

    var onLottieAnimation: LottieAnimationView?
    
    @IBInspectable
    public var isStormMode: Bool = false {
        didSet {
            onLottieAnimation?.removeFromSuperview()
            
            if isStormMode {
                onLottieAnimation = LottieAnimationView(animation: .named("outage_power_on"))
                
                outerCircleView.isHidden = true
                
                statusTitleLabel.textColor = .white
                statusDetailLabel.textColor = .white
                
                statusETRLabel.textColor = .white
                reportedDetailLabel.textColor = .white
                reportedETRTitleLabel.textColor = .white
                reportedETRLabel.textColor = .white
            } else {
                onLottieAnimation = LottieAnimationView(name: "outage_power_on")
                
                outerCircleView.isHidden = false
                
                statusTitleLabel.textColor = .primaryBlue
                statusDetailLabel.textColor = .primaryBlue
                
                statusETRLabel.textColor = .primaryBlue
                reportedDetailLabel.textColor = .primaryBlue
                reportedETRTitleLabel.textColor = .neutralDark
                reportedETRLabel.textColor = .neutralDark
            }
            
            onLottieAnimation?.frame = CGRect(x: 0, y: 1, width: animationView.frame.size.width, height: animationView.frame.size.height)
            onLottieAnimation?.loopMode = .loop
            onLottieAnimation?.backgroundBehavior = .pauseAndRestore
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        innerCircleView.layer.cornerRadius = innerCircleView.bounds.width / 2
        outerCircleView.layer.cornerRadius = outerCircleView.bounds.size.width / 2
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
        statusETRView.isHidden = false
        
        // Styling
        
        innerCircleView.removeShadow()
        
        if isStormMode {
            statusETRImageView.image = UIImage(named: "ic_reportoutagewhite")
            setStateColors(innerBackground: .clear,
                           innerStroke: innerBorderColor)
        } else {
            setStateColors(innerBackground: .white,
                           innerStroke: innerBorderColor,
                           outerStroke: outterBorderColor)
            statusETRImageView.image = UIImage(named: "ic_reportoutage")
        }
        
        // Set Values
        
        statusETRLabel.text = NSLocalizedString("Your outage is", comment: "")
        reportedDetailLabel.text = NSLocalizedString("REPORTED", comment: "")
        reportedETRTitleLabel.text = NSLocalizedString("Estimated Restoration", comment: "")
        reportedETRLabel.text = estimatedRestorationDateString

        innerCircleView.accessibilityLabel = NSLocalizedString("Outage status button. Your outage is reported. Estimated restoration \(estimatedRestorationDateString).", comment: "")
    }
    
    func setOutageState(estimatedRestorationDateString: String) {
        animationView.isHidden = true
        outerCircleView.isHidden = false
        
        statusView.isHidden = true
        statusETRView.isHidden = false

        // Styling
        
        innerCircleView.removeShadow()
        
        if isStormMode {
            setStateColors(innerBackground: .clear,
                           innerStroke: .white.withAlphaComponent(0.5))
            statusETRImageView.image = UIImage(named: "ic_outagestatus_out_white")
        } else {
            setStateColors(innerBackground: .white,
                           innerStroke: .middleGray,
                           outerStroke: UIColor(red: 216/255, green: 216/255, blue: 216/255,  alpha: 1))
            statusETRImageView.image = UIImage(named: "ic_outagestatus_out")
        }
        
        // Set Values
        
        statusETRLabel.text = NSLocalizedString("Our records indicate", comment: "")
        reportedDetailLabel.text = NSLocalizedString("POWER IS OUT", comment: "")
        reportedETRTitleLabel.text = NSLocalizedString("Estimated Restoration", comment: "")
        reportedETRLabel.text = estimatedRestorationDateString

        innerCircleView.accessibilityLabel = NSLocalizedString("Outage status button. Our records indicate your power is out. Estimated restoration \(estimatedRestorationDateString).", comment: "")
    }
    
    func setPowerOnState() {
        animationView.isHidden = false
        outerCircleView.isHidden = true
        
        statusView.isHidden = false
        statusETRView.isHidden = true

        // Styling
        
        innerCircleView.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 4), radius: 5)

        if isStormMode {
            setStateColors(innerBackground: .clear,
                           innerStroke: .clear,
                           outerStroke: .clear)
            statusImageView.image = UIImage(named: "ic_lightbulb_on_white")
        } else {
            setStateColors(innerBackground: .white,
                           innerStroke: .white,
                           outerStroke: .clear)
            statusImageView.image = UIImage(named: "ic_lightbulb_on")
        }
        
        // Set Values
        
        statusTitleLabel.text = NSLocalizedString("Our records indicate your", comment: "")
        statusDetailLabel.text = NSLocalizedString("POWER IS ON", comment: "")

        innerCircleView.accessibilityLabel = NSLocalizedString("Outage status button. Our records indicate your power is on.", comment: "")
    }

    @objc func onBigButtonTap() {
        delegate?.outageStatusButtonWasTapped(self)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 267, height: 267)
    }
    
}
