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

        // Triggers Initial DidSet
        isStormMode = false
        
        
        outerCircleView.layer.cornerRadius = outerCircleView.bounds.size.width / 2
        innerCircleView.layer.cornerRadius = innerCircleView.bounds.size.width / 2
        
//        let radius = bigButtonImageView.bounds.size.width / 2
//        bigButtonImageView.layer.cornerRadius = radius
//        bigButtonImageView.clipsToBounds = true // So text doesn't overflow
//        bigButtonImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onBigButtonTap)))
//        bigButtonImageView.isAccessibilityElement = true
//        bigButtonImageView.accessibilityTraits = UIAccessibilityTraitButton

    }
    
//    func setPowerIsOn(_ powerIsOn: Bool = true) {
//        animationView.isHidden = !powerIsOn
//        outerCircleView.isHidden = powerIsOn
//        innerCircleView.isHidden = powerIsOn
//    }
    
    private func setGrayCircles() {
        outerCircleView.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.3)
        innerCircleView.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.9)
    }
    
//    private func setColoredCircles() {
//        outerCircleView.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.3)
//        innerCircleView.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.9)
//    }
    
    func setReportedState(estimatedRestorationDateString: String) {
        clearSubviews()
        
        animationView.isHidden = true
        outerCircleView.isHidden = false
        innerCircleView.isHidden = false
        setGrayCircles()
        
        let bigButtonWidth = innerCircleView.frame.size.width
        
        let icon = UIImageView(frame: CGRect(x: bigButtonWidth / 2 - 19, y: 80, width: 38, height: 31))
        icon.image = #imageLiteral(resourceName: "ic_outagestatus_reported")
        
        let yourOutageIsLabel = UILabel(frame: CGRect(x: 30, y: 114, width: bigButtonWidth - 60, height: 20))
        yourOutageIsLabel.font = OpenSans.regular.of(size: 16)
        yourOutageIsLabel.textColor = .actionBlue
        yourOutageIsLabel.textAlignment = .center
        yourOutageIsLabel.text = NSLocalizedString("Your outage is", comment: "")
        
        let reportedLabel = UILabel(frame: CGRect(x: 30, y: 134, width: bigButtonWidth - 60, height: 25))
        reportedLabel.font = OpenSans.bold.of(size: 22)
        reportedLabel.textColor = .actionBlue
        reportedLabel.textAlignment = .center
        reportedLabel.text = NSLocalizedString("REPORTED", comment: "")
        
        let restRestorationLabel = UILabel(frame: CGRect(x: 30, y: 170, width: bigButtonWidth - 60, height: 14))
        restRestorationLabel.font = OpenSans.regular.of(size: 12)
        restRestorationLabel.textColor = .deepGray
        restRestorationLabel.textAlignment = .center
        restRestorationLabel.text = NSLocalizedString("Estimated Restoration", comment: "")
        
        let timeLabel = UILabel(frame: CGRect(x: 22, y: 184, width: bigButtonWidth - 44, height: 20))
        timeLabel.font = OpenSans.bold.of(size: 15)
        timeLabel.textColor = .deepGray
        timeLabel.textAlignment = .center
        timeLabel.adjustsFontSizeToFitWidth = true
        timeLabel.minimumScaleFactor = 0.5
        timeLabel.text = estimatedRestorationDateString
        
        innerCircleView.addSubview(icon)
        innerCircleView.addSubview(yourOutageIsLabel)
        innerCircleView.addSubview(reportedLabel)
        innerCircleView.addSubview(restRestorationLabel)
        innerCircleView.addSubview(timeLabel)
        innerCircleView.accessibilityLabel = NSLocalizedString("Outage status, button. Your outage is reported. Estimated restoration \(estimatedRestorationDateString).", comment: "")
    }
    
    func setOutageState(estimatedRestorationDateString: String) {
        clearSubviews()
        
        animationView.isHidden = true
        outerCircleView.isHidden = false
        innerCircleView.isHidden = false
        setGrayCircles()
        
        let bigButtonWidth = innerCircleView.frame.size.width
        
        let icon = UIImageView(frame: CGRect(x: bigButtonWidth / 2 - 11, y: 84, width: 22, height: 28))
        icon.image = #imageLiteral(resourceName: "ic_outagestatus_out")
        
        let yourPowerIsLabel = UILabel(frame: CGRect(x: 30, y: 115, width: bigButtonWidth - 60, height: 20))
        yourPowerIsLabel.font = OpenSans.regular.of(size: 14)
        yourPowerIsLabel.textColor = .actionBlue
        yourPowerIsLabel.textAlignment = .center
        yourPowerIsLabel.text = NSLocalizedString("Our records indicate your", comment: "")
        
        let outLabel = UILabel(frame: CGRect(x: 44, y: 135, width: bigButtonWidth - 88, height: 25))
        outLabel.font = OpenSans.bold.of(size: 22)
        outLabel.textColor = .actionBlue
        outLabel.textAlignment = .center
        outLabel.text = NSLocalizedString("POWER IS OUT", comment: "")
        
        let restRestorationLabel = UILabel(frame: CGRect(x: 30, y: 170, width: bigButtonWidth - 60, height: 14))
        restRestorationLabel.font = OpenSans.regular.of(size: 12)
        restRestorationLabel.textColor = .deepGray
        restRestorationLabel.textAlignment = .center
        restRestorationLabel.text = NSLocalizedString("Estimated Restoration", comment: "")
        
        let timeLabel = UILabel(frame: CGRect(x: 22, y: 184, width: bigButtonWidth - 44, height: 20))
        timeLabel.font = OpenSans.bold.of(size: 15)
        timeLabel.textColor = .deepGray
        timeLabel.textAlignment = .center
        timeLabel.adjustsFontSizeToFitWidth = true
        timeLabel.minimumScaleFactor = 0.5
        timeLabel.text = estimatedRestorationDateString
        
        innerCircleView.addSubview(icon)
        innerCircleView.addSubview(yourPowerIsLabel)
        innerCircleView.addSubview(outLabel)
        innerCircleView.addSubview(restRestorationLabel)
        innerCircleView.addSubview(timeLabel)
        innerCircleView.accessibilityLabel = NSLocalizedString("Outage status, button. Our records indicate your power is out. Estimated restoration \(estimatedRestorationDateString).", comment: "")
    }
    
    func setIneligibleState(flagFinaled: Bool, nonPayFinaledMessage: String) {
        clearSubviews()
        
        animationView.isHidden = true
        outerCircleView.isHidden = false
        innerCircleView.isHidden = false
        setGrayCircles()
        
        let bigButtonWidth = 194 // The old width of the button prior to the redesign
        
        let nonPayFinaledTextView = DataDetectorTextView(frame: CGRect(x: 67, y: 91, width: bigButtonWidth - 28, height: 120))
        nonPayFinaledTextView.backgroundColor = .clear
        
        let payBillLabel = UILabel(frame: .zero)
        if Environment.shared.opco != .bge {
            if flagFinaled {
                nonPayFinaledTextView.frame = CGRect(x: 67, y: 121, width: bigButtonWidth - 28, height: 84)
            } else { // accountPaid = false
                payBillLabel.frame = CGRect(x: 76, y: 203, width: bigButtonWidth - 46, height: 19)
                payBillLabel.font = SystemFont.semibold.of(size: 16)
                payBillLabel.textColor = .actionBlue
                payBillLabel.textAlignment = .center
                payBillLabel.text = NSLocalizedString("Pay Bill", comment: "")
                innerCircleView.addSubview(payBillLabel)
            }
        }
        nonPayFinaledTextView.textContainerInset = .zero
        nonPayFinaledTextView.font = SystemFont.light.of(size: 14)
        nonPayFinaledTextView.tintColor = .actionBlue // For the phone numbers
        nonPayFinaledTextView.textColor = .middleGray
        nonPayFinaledTextView.textAlignment = .center
        nonPayFinaledTextView.text = nonPayFinaledMessage
        
        innerCircleView.addSubview(nonPayFinaledTextView)
        innerCircleView.bringSubview(toFront: payBillLabel)
        innerCircleView.accessibilityLabel = NSLocalizedString("Outage status, button. \(nonPayFinaledMessage).", comment: "")
    }
    
    func setPowerOnState() {
        clearSubviews()
        
        animationView.isHidden = false
        outerCircleView.isHidden = true
        innerCircleView.isHidden = true
        
        let bigButtonWidth = innerCircleView.frame.size.width
        
        let icon = UIImageView(frame: CGRect(x: bigButtonWidth / 2 - 15, y: 102, width: 30, height: 38))
        icon.image = #imageLiteral(resourceName: "ic_outagestatus_on")
        
        let yourPowerIsLabel = UILabel(frame: CGRect(x: 40, y: 142, width: bigButtonWidth - 80, height: 20))
        yourPowerIsLabel.font = OpenSans.regular.of(size: 14)
        yourPowerIsLabel.textColor = .actionBlue
        yourPowerIsLabel.textAlignment = .center
        yourPowerIsLabel.text = NSLocalizedString("Our records indicate your", comment: "")
        
        let onLabel = UILabel(frame: CGRect(x: 40, y: 162, width: bigButtonWidth - 80, height: 25))
        onLabel.font = OpenSans.bold.of(size: 22)
        onLabel.textColor = .actionBlue
        onLabel.textAlignment = .center
        onLabel.text = NSLocalizedString("POWER IS ON", comment: "")
        
        innerCircleView.addSubview(icon)
        innerCircleView.addSubview(yourPowerIsLabel)
        innerCircleView.addSubview(onLabel)
        innerCircleView.accessibilityLabel = NSLocalizedString("Outage status, Button. Our records indicate your power is on.", comment: "")
    }
    
    private func clearSubviews() {
        for subview in innerCircleView.subviews {
            subview.removeFromSuperview()
        }
    }
    
    @objc func onBigButtonTap() {
        delegate?.outageStatusButtonWasTapped(self)
    }
}
