//
//  ContactUsViewController.swift
//  Mobile
//
//  Created by Wesley Weitzel on 4/5/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class ContactUsViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var cardView: UIView!
    
    @IBOutlet weak var emergencyNumberTextView: DataDetectorTextView!
    @IBOutlet weak var emergencyDescriptionLabel: UILabel!
    
    @IBOutlet weak var customerServiceLabel: UILabel!
    
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
    
    @IBOutlet weak var socialMediaButtonStack: UIStackView!
    @IBOutlet weak var firstButtonRow: UIStackView!
    
    let contactUsViewModel = ContactUsViewModel()
    
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Contact Us", comment: "")
        
        view.backgroundColor = .primaryColor
        
        cardView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        cardView.layer.cornerRadius = 2
        
        emergencyDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        emergencyDescriptionLabel.attributedText = contactUsViewModel.emergencyAttrString
        
        emergencyNumberTextView.text = contactUsViewModel.phoneNumber1
        emergencyNumberTextView.textContainerInset = .zero
        emergencyNumberTextView.tintColor = .actionBlue // Color of the phone numbers
        firstNumberTextView.text = contactUsViewModel.phoneNumber2
        firstNumberTextView.textContainerInset = .zero
        firstNumberTextView.tintColor = .actionBlue // Color of the phone numbers
        secondNumberTextView?.text = contactUsViewModel.phoneNumber3
        secondNumberTextView?.textContainerInset = .zero
        secondNumberTextView?.tintColor = .actionBlue // Color of the phone numbers
        thirdNumberTextView?.text = contactUsViewModel.phoneNumber4
        thirdNumberTextView?.textContainerInset = .zero
        thirdNumberTextView?.tintColor = .actionBlue // Color of the phone numbers
        
        customerServiceLabel.text = NSLocalizedString("Customer Service", comment: "")
        
        firstLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        secondLabel?.font = OpenSans.regular.of(textStyle: .subheadline)
        thirdLabel?.font = OpenSans.regular.of(textStyle: .subheadline)
        
        firstLabel.text = contactUsViewModel.label1
        secondLabel?.text = contactUsViewModel.label2
        thirdLabel?.text = contactUsViewModel.label3
        
        switch Environment.sharedInstance.opco {
        case .bge:
            break
        case .comEd:
            break
        case .peco:
            secondStack.isHidden = true
            thirdStack.isHidden = true
        }
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            extendedLayoutIncludesOpaqueBars = true
        }
        
        let openUrl: (String) -> Void = { UIApplication.shared.openURL(URL(string: $0)!) }
        
        let buttonInfoList: [(url: String, image: UIImage)] = [(contactUsViewModel.facebookURL, #imageLiteral(resourceName: "ic_facebook"))]
        
        for (url, image) in buttonInfoList.prefix(5) {
            let facebookButton = UIButton(type: .custom)
            facebookButton.setImage(image, for: .normal)
            facebookButton.rx.tap.asDriver()
                .drive(onNext: { openUrl(url) })
                .addDisposableTo(bag)
            firstButtonRow.addArrangedSubview(facebookButton)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            tabBarController?.tabBar.isHidden = true
        }
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.isTranslucent = true
        
        let titleDict: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: OpenSans.bold.of(size: 18)
        ]
        navigationController?.navigationBar.titleTextAttributes = titleDict
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            if let splitView = splitViewController as? MoreSplitViewController {
                splitView.setStatusBarStyle(style: .lightContent)
            }
            splitViewController?.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    @IBAction func facebookButtonTapped(_ sender: UIButton) {
        UIApplication.shared.openURL(URL(string: contactUsViewModel.facebookURL)!)
    }

    @IBAction func twitterButtonTapped(_ sender: UIButton) {
        UIApplication.shared.openURL(NSURL(string: contactUsViewModel.twitterURL)! as URL)
    }
    
    @IBAction func youtubeButtonTapped(_ sender: UIButton) {
        UIApplication.shared.openURL(NSURL(string: contactUsViewModel.youtubeURL)! as URL)
    }
    
    @IBAction func linkedinButtonTapped(_ sender: UIButton) {
        UIApplication.shared.openURL(NSURL(string: contactUsViewModel.linkedinURL)! as URL)
    }
    
    @IBAction func flickrButtonTapped(_ sender: UIButton) {
        UIApplication.shared.openURL(NSURL(string: contactUsViewModel.flickrURL)! as URL)
    }
    
    @IBAction func pinterestButtonTapped(_ sender: UIButton) {
        UIApplication.shared.openURL(NSURL(string: contactUsViewModel.pinterestURL)! as URL)
    }
    
    @IBAction func instagramButtonTapped(_ sender: UIButton) {
        UIApplication.shared.openURL(NSURL(string: contactUsViewModel.instagramURL)! as URL)
    }
    
}

