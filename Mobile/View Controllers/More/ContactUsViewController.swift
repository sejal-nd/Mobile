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
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var containerStack: UIStackView!
    
    @IBOutlet weak var emergencyNumberTextView: DataDetectorTextView!
    @IBOutlet weak var emergencyDescriptionLabel: UILabel!
    
    @IBOutlet weak var submitFormButton: UIButton!
    @IBOutlet weak var onlineDescriptionLabel: UILabel!
    
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var firstNumberTextView: DataDetectorTextView!
    @IBOutlet weak var secondStack: UIStackView!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var secondNumberTextView: DataDetectorTextView!
    @IBOutlet weak var thirdStack: UIStackView!
    @IBOutlet weak var thirdLabel: UILabel!
    @IBOutlet weak var thirdNumberTextView: DataDetectorTextView!
    
    @IBOutlet var dividerLines: [UIView]!
    @IBOutlet var dividerLineConstraints: [NSLayoutConstraint]!
    
    let contactUsViewModel = ContactUsViewModel()
    
    let bag = DisposeBag()
    
    var unauthenticatedExperience = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = StormModeStatus.shared.isOn ? .stormModeBlack : .primaryColor
        
        cardView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        cardView.layer.cornerRadius = 10.0
        
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
        navigationController?.setColoredNavBar(hidesBottomBorder: true)
    }
    
    override func updateViewConstraints() {
        for constraint in dividerLineConstraints {
            constraint.constant = 1.0 / UIScreen.main.scale
        }
        super.updateViewConstraints()
    }
    
    func emergencySetup() {
        emergencyNumberTextView.text = contactUsViewModel.phoneNumber1
        emergencyNumberTextView.textContainerInset = .zero
        emergencyNumberTextView.tintColor = .actionBlue // Color of the phone numbers
        emergencyNumberTextView.linkTapDelegate = self
        
        emergencyDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        emergencyDescriptionLabel.attributedText = contactUsViewModel.emergencyAttrString
    }
    
    func onlineSetup() {
        submitFormButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                
                Analytics.log(event: self.unauthenticatedExperience ? .unAuthContactUsForm : .contactUsForm)
                
                let safariVC = SFSafariViewController.createWithCustomStyle(url: self.contactUsViewModel.onlineFormUrl)
                self.present(safariVC, animated: true, completion: nil)
            })
            .disposed(by: bag)
        
        onlineDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
    }
    
    func customerServiceSetup() {
        firstLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        firstLabel.text = contactUsViewModel.label1
        firstNumberTextView.text = contactUsViewModel.phoneNumber2
        firstNumberTextView.textContainerInset = .zero
        firstNumberTextView.tintColor = .actionBlue // Color of the phone numbers
        firstNumberTextView.linkTapDelegate = self
        
        if let label2 = contactUsViewModel.label2,
            let phoneNumber3 = contactUsViewModel.phoneNumber3 {
            secondLabel.font = OpenSans.regular.of(textStyle: .subheadline)
            secondLabel.text = label2
            secondNumberTextView.text = phoneNumber3
            secondNumberTextView.textContainerInset = .zero
            secondNumberTextView.tintColor = .actionBlue // Color of the phone numbers
            secondNumberTextView.linkTapDelegate = self
        } else {
            secondStack.isHidden = true
        }
        
        if let label3 = contactUsViewModel.label3,
            let phoneNumber4 = contactUsViewModel.phoneNumber4 {
            thirdLabel.font = OpenSans.regular.of(textStyle: .subheadline)
            thirdLabel.text = label3
            thirdNumberTextView.text = phoneNumber4
            thirdNumberTextView.textContainerInset = .zero
            thirdNumberTextView.tintColor = .actionBlue // Color of the phone numbers
            thirdNumberTextView.linkTapDelegate = self
        } else {
            thirdStack.isHidden = true
        }
    }
    
    func socialMediaButtonsSetup() {
        // create buttons
        var buttons: [UIView] = contactUsViewModel.buttonInfoList
            .map { (urlString, image, accessibilityLabel) -> UIButton in
                let button = UIButton(type: .custom)
                button.accessibilityLabel = accessibilityLabel
                button.setImage(image, for: .normal)
                button.rx.tap.asDriver()
                    .drive(onNext: {
                        guard let urlString = urlString else { return }
                        UIApplication.shared.openUrlIfCan(string: urlString)
                    })
                    .disposed(by: bag)
                return button
        }
        
        let rowCount = 5
        
        // add spacer buttons to fill the last row
        while buttons.count % rowCount != 0 {
            buttons.append(UIButton(type: .custom))
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
        socialMediaButtonsStack.leadingAnchor.constraint(equalTo: containerStack.leadingAnchor, constant: 22).isActive = true
        socialMediaButtonsStack.trailingAnchor.constraint(equalTo: containerStack.trailingAnchor, constant: -22).isActive = true
    }
    
    // Prevents status bar color flash when pushed from MoreViewController
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}

extension ContactUsViewController: DataDetectorTextViewLinkTapDelegate {
    
    func dataDetectorTextView(_ textView: DataDetectorTextView, didInteractWith URL: URL) {
        let screenName: AnalyticsEvent = unauthenticatedExperience ? .contactUsUnAuthCall : .contactUsAuthCall
        var dimensionValue: String?
        
        if textView == emergencyNumberTextView {
            dimensionValue = "Emergency"
        } else if textView == firstNumberTextView {
            dimensionValue = "Residential"
        } else if textView == secondNumberTextView {
            dimensionValue = "Business"
        } else if textView == thirdNumberTextView {
            dimensionValue = "TTY/TTD"
        }
        
        if let value = dimensionValue {
            Analytics.log(event: screenName, dimensions: [.link: value])
        }
    }
}
