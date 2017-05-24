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

class ContactUsViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var containerStack: UIStackView!
    
    @IBOutlet weak var emergencyNumberTextView: DataDetectorTextView!
    @IBOutlet weak var emergencyDescriptionLabel: UILabel!
    
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var firstNumberTextView: DataDetectorTextView!
    @IBOutlet weak var firstNumberSeparator: UIView!
    @IBOutlet weak var secondStack: UIStackView!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var secondNumberTextView: DataDetectorTextView!
    @IBOutlet weak var secondNumberSeparator: UIView!
    @IBOutlet weak var thirdStack: UIStackView!
    @IBOutlet weak var thirdLabel: UILabel!
    @IBOutlet weak var thirdNumberTextView: DataDetectorTextView!
    
    let contactUsViewModel = ContactUsViewModel()
    
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .primaryColor
        
        cardView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        cardView.layer.cornerRadius = 2
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            extendedLayoutIncludesOpaqueBars = true
        }
        
        emergencySetup()
        customerServiceSetup()
        socialMediaButtonsSetup()
    }
    
    func emergencySetup() {
        emergencyNumberTextView.text = contactUsViewModel.phoneNumber1
        emergencyNumberTextView.textContainerInset = .zero
        emergencyNumberTextView.tintColor = .actionBlue // Color of the phone numbers
        
        emergencyDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        emergencyDescriptionLabel.attributedText = contactUsViewModel.emergencyAttrString
    }
    
    func customerServiceSetup() {
        firstLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        firstLabel.text = contactUsViewModel.label1
        firstNumberTextView.text = contactUsViewModel.phoneNumber2
        firstNumberTextView.textContainerInset = .zero
        firstNumberTextView.tintColor = .actionBlue // Color of the phone numbers
        
        if let label2 = contactUsViewModel.label2,
            let phoneNumber3 = contactUsViewModel.phoneNumber3 {
            secondLabel.font = OpenSans.regular.of(textStyle: .subheadline)
            secondLabel.text = label2
            secondNumberTextView.text = phoneNumber3
            secondNumberTextView.textContainerInset = .zero
            secondNumberTextView.tintColor = .actionBlue // Color of the phone numbers
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
        } else {
            thirdStack.isHidden = true
        }
    }
    
    func socialMediaButtonsSetup() {
        // create buttons
        var buttons: [UIView] = contactUsViewModel.buttonInfoList
            .map { (urlString, image) -> UIButton in
                let button = UIButton(type: .custom)
                button.setImage(image, for: .normal)
                button.rx.tap.asDriver()
                    .drive(onNext: {
                        guard let urlString = urlString,
                            let url = URL(string: urlString),
                            UIApplication.shared.canOpenURL(url) else { return }
                        
                        UIApplication.shared.openURL(url)
                    })
                    .addDisposableTo(bag)
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            tabBarController?.tabBar.isHidden = true
        }
        
        if UIDevice.current.userInterfaceIdiom == .phone,
            let splitView = splitViewController as? MoreSplitViewController {
            splitView.setStatusBarStyle(style: .lightContent)
        }
        splitViewController?.setNeedsStatusBarAppearanceUpdate()
        
        guard let navController = navigationController else { return }
        
        navController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navController.navigationBar.shadowImage = UIImage()
        navController.navigationBar.backgroundColor = .clear
        navController.navigationBar.tintColor = .white
        navController.navigationBar.isTranslucent = true
        
        let titleDict: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: OpenSans.bold.of(size: 18)
        ]
        navController.navigationBar.titleTextAttributes = titleDict
        
        navController.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
}

