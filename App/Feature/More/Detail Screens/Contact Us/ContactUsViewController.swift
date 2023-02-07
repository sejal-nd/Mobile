//
//  ContactUsViewController.swift
//  Mobile
//
//  Created by Wesley Weitzel on 4/5/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt
import SafariServices

class ContactUsViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var containerStack: UIStackView!
    
    @IBOutlet weak var emergencyNumberTextView: ZeroInsetDataDetectorTextView!
    @IBOutlet weak var emergencyDescriptionLabel: UILabel!
    @IBOutlet weak var bgeOnlySpacer: UIView!
    @IBOutlet weak var bgeOnlyStackView: UIStackView!
    @IBOutlet weak var bgeGasNumberLabel: UILabel!
    @IBOutlet weak var bgeGasNumber1TextView: ZeroInsetDataDetectorTextView!
    @IBOutlet weak var bgeGasNumber2TextView: ZeroInsetDataDetectorTextView!
    @IBOutlet weak var bgePowerLineLabel: UILabel!
    @IBOutlet weak var bgePowerLineNumber1TextView: ZeroInsetDataDetectorTextView!
    @IBOutlet weak var bgePowerLineNumber2TextView: ZeroInsetDataDetectorTextView!
    
    @IBOutlet weak var submitFormButton: UIButton!
    @IBOutlet weak var onlineDescriptionLabel: UILabel!
    
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var firstNumberTextView: ZeroInsetDataDetectorTextView!
    @IBOutlet weak var secondStack: UIStackView!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var secondNumberTextView: ZeroInsetDataDetectorTextView!
    @IBOutlet weak var thirdStack: UIStackView!
    @IBOutlet weak var thirdLabel: UILabel!
    @IBOutlet weak var thirdNumberTextView: ZeroInsetDataDetectorTextView!
    
    @IBOutlet weak var contactServiceTimingsLabel: UILabel!
    @IBOutlet var dividerLines: [UIView]!
    @IBOutlet var dividerLineConstraints: [NSLayoutConstraint]!
    
    let viewModel = ContactUsViewModel()
    
    let bag = DisposeBag()
    
    var unauthenticatedExperience = false
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return StormModeStatus.shared.isOn ? .lightContent : .default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for line in dividerLines {
            line.backgroundColor = .accentGray
        }

        emergencySetup()
        onlineSetup()
        customerServiceSetup()
        socialMediaButtonsSetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func updateViewConstraints() {
        for constraint in dividerLineConstraints {
            constraint.constant = 1.0 / UIScreen.main.scale
        }
        super.updateViewConstraints()
    }
    
    func emergencySetup() {
        emergencyNumberTextView.text = viewModel.phoneNumber1
        emergencyNumberTextView.tintColor = .actionBrand // Color of the phone numbers
        emergencyNumberTextView.linkTapDelegate = self
        
        if Configuration.shared.opco == .bge {
            emergencyNumberTextView.isHidden = true
            bgeOnlySpacer.isHidden = true
            bgeGasNumberLabel.text = NSLocalizedString("Gas Emergency", comment: "")
            bgeGasNumber1TextView.text = viewModel.bgeGasNumber1
        } else if Configuration.shared.opco == .peco {
            emergencyNumberTextView.isHidden = true
            bgeOnlySpacer.isHidden = true
            bgeGasNumberLabel.text = NSLocalizedString("Gas Emergency", comment: "")
            bgeGasNumber1TextView.text = viewModel.bgeGasNumber1
            bgePowerLineNumber2TextView.superview?.isHidden = true
        } else if Configuration.shared.opco == .delmarva {
            // Only the first row is needed, rest needs to be hidden
            bgeOnlyStackView.isHidden = false
            bgePowerLineNumber1TextView.isHidden = true
            bgePowerLineNumber2TextView.isHidden = true
            bgeGasNumber2TextView.isHidden = true
            bgePowerLineLabel.isHidden = true
            bgeGasNumberLabel.text = NSLocalizedString("Natural Gas Emergency", comment: "")
            bgeGasNumber1TextView.text = viewModel.delmarvaGasNumber
            // Change the height as the stack view needs to be shrinked to a smaller height
            bgeOnlyStackView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        } else {
            bgeOnlyStackView.isHidden = true
        }
        
        bgeGasNumberLabel.font = .subheadline
        bgeGasNumber1TextView.tintColor = .actionBrand // Color of the phone numbers
        bgeGasNumber1TextView.linkTapDelegate = self
        bgeGasNumber2TextView.text = viewModel.bgeGasNumber2
        bgeGasNumber2TextView.tintColor = .actionBrand // Color of the phone numbers
        bgeGasNumber2TextView.linkTapDelegate = self
        bgePowerLineLabel.font = .subheadline
        bgePowerLineNumber1TextView.text = viewModel.bgePowerLineNumber1
        bgePowerLineNumber1TextView.tintColor = .actionBrand // Color of the phone numbers
        bgePowerLineNumber1TextView.linkTapDelegate = self
        bgePowerLineNumber2TextView.text = viewModel.bgePowerLineNumber2
        bgePowerLineNumber2TextView.tintColor = .actionBrand // Color of the phone numbers
        bgePowerLineNumber2TextView.linkTapDelegate = self

        emergencyDescriptionLabel.font = .footnote
        emergencyDescriptionLabel.attributedText = viewModel.emergencyAttrString
    }
    
    func onlineSetup() {
        submitFormButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                
                GoogleAnalytics.log(event: self.unauthenticatedExperience ? .unAuthContactUsForm : .contactUsForm)
                FirebaseUtility.logEvent(.contactUs(parameters: [.online_form]))
                
                let safariVC = SFSafariViewController.createWithCustomStyle(url: self.viewModel.onlineFormUrl)
                self.present(safariVC, animated: true, completion: nil)
            })
            .disposed(by: bag)
        
        onlineDescriptionLabel.font = .footnote
    }
    
    func customerServiceSetup() {
        firstLabel.font = .subheadline
        firstLabel.text = viewModel.label1
        contactServiceTimingsLabel.text = viewModel.contactServiceTimings
        firstNumberTextView.text = viewModel.phoneNumber2
        firstNumberTextView.tintColor = .actionBrand // Color of the phone numbers
        firstNumberTextView.linkTapDelegate = self
        
        if let label2 = viewModel.label2,
            let phoneNumber3 = viewModel.phoneNumber3 {
            secondLabel.font = .subheadline
            secondLabel.text = label2
            secondNumberTextView.text = phoneNumber3
            secondNumberTextView.tintColor = .actionBrand // Color of the phone numbers
            secondNumberTextView.linkTapDelegate = self
        } else {
            secondStack.isHidden = true
        }
        
        if let label3 = viewModel.label3,
            let phoneNumber4 = viewModel.phoneNumber4 {
            thirdLabel.font = .subheadline
            thirdLabel.text = label3
            thirdNumberTextView.text = phoneNumber4
            thirdNumberTextView.tintColor = .actionBrand // Color of the phone numbers
            thirdNumberTextView.linkTapDelegate = self
        } else {
            thirdStack.isHidden = true
        }
    }
    
    func socialMediaButtonsSetup() {
        // create buttons
        var buttons: [UIView] = viewModel.buttonInfoList
            .map { (urlString, image, accessibilityLabel, analyticParam) -> UIButton in
                let button = UIButton(type: .custom)
                button.accessibilityLabel = accessibilityLabel
                button.setImage(image, for: .normal)
                button.rx.tap.asDriver()
                    .drive(onNext: {
                        FirebaseUtility.logEvent(.contactUs(parameters: [analyticParam]))
                        guard let urlString = urlString else { return }
                        UIApplication.shared.openUrlIfCan(string: urlString)
                    })
                    .disposed(by: bag)
                return button
        }
        
        let rowCount = 5
        
        // add spacer buttons to fill the last row
        // PHI has a different design hence not adding spacerButtons to the main stack
          while buttons.count % rowCount != 0 && Configuration.shared.opco == .bge {
            let spacerButton = UIButton(type: .custom)
            spacerButton.isAccessibilityElement = false
            buttons.append(spacerButton)
        }
        
        // create stack views for each row of buttons
        let socialMediaButtonRows: [UIStackView] = stride(from: 0, to: buttons.count, by: rowCount)
            .map { Array(buttons[$0..<Swift.min($0 + rowCount, buttons.count)]) }
            .map(UIStackView.init)
        
        socialMediaButtonRows.forEach {
            $0.axis = .horizontal
            $0.alignment = .fill
            $0.distribution = .equalCentering
        }
        
        // stack the rows and add them to the view
        let socialMediaButtonsStack = UIStackView(arrangedSubviews: socialMediaButtonRows)
        socialMediaButtonsStack.axis = .vertical
        socialMediaButtonsStack.alignment = .fill
        socialMediaButtonsStack.distribution = .fill
        socialMediaButtonsStack.spacing = 22
        containerStack.addArrangedSubview(socialMediaButtonsStack)
        
        let leadingConstraint = socialMediaButtonsStack.leadingAnchor.constraint(equalTo: containerStack.leadingAnchor, constant: 22)
        leadingConstraint.priority = UILayoutPriority(rawValue: 999)
        let trailingConstraint = socialMediaButtonsStack.trailingAnchor.constraint(equalTo: containerStack.trailingAnchor, constant: -22)
        trailingConstraint.priority = UILayoutPriority(rawValue: 999)
        // For PHI opcos, the placement of the social media icons is little different hence using custom width per opco
        var width: CGFloat = .zero
        switch Configuration.shared.opco {
        case .bge, .comEd, .pepco, .peco:
            width = 430
        case .ace, .delmarva:
            width = 200
        }
        let widthConstraint = socialMediaButtonsStack.widthAnchor.constraint(lessThanOrEqualToConstant: width)
        NSLayoutConstraint.activate([leadingConstraint, trailingConstraint, widthConstraint])
    }
    
}

extension ContactUsViewController: DataDetectorTextViewLinkTapDelegate {
    
    func dataDetectorTextView(_ textView: DataDetectorTextView, didInteractWith URL: URL) {
        var dimensionValue: String?
        switch textView {
        case emergencyNumberTextView, bgeGasNumber1TextView,
             bgeGasNumber2TextView, bgePowerLineNumber1TextView,
             bgePowerLineNumber2TextView:
            dimensionValue = "Emergency"
        case firstNumberTextView:
            dimensionValue = "Residential"
        case secondNumberTextView:
            dimensionValue = "Business"
        case thirdNumberTextView:
            dimensionValue = "TTY/TTD"
        default:
            dimensionValue = nil
        }

        if let value = dimensionValue {
            let screenName: GoogleAnalyticsEvent = unauthenticatedExperience ? .contactUsUnAuthCall : .contactUsAuthCall
            GoogleAnalytics.log(event: screenName, dimensions: [.link: value])
        }
        
        let paramValue: ContactUsParameter?
        switch textView {
        case emergencyNumberTextView:
            paramValue = .emergency_number
        case bgeGasNumber1TextView:
            paramValue = .phone_number_main
        case bgeGasNumber2TextView:
            paramValue = .phone_number_emergency_gas
        case bgePowerLineNumber1TextView:
            paramValue = .phone_number_main
        case bgePowerLineNumber2TextView:
            paramValue = .phone_number_emergency_electric
        case firstNumberTextView:
            paramValue = .customer_service_residential
        case secondNumberTextView:
            paramValue = .customer_service_business
        case thirdNumberTextView:
            paramValue = .customer_service_tty_ttd
        default:
            paramValue = nil
        }
        
        if let paramVal = paramValue {
            FirebaseUtility.logEvent(.contactUs(parameters: [paramVal]))
        }
    }
}
