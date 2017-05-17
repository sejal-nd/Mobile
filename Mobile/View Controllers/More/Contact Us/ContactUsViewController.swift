//
//  ContactUsViewController.swift
//  Mobile
//
//  Created by Wesley Weitzel on 4/5/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

class ContactUsViewController: UIViewController {

    @IBOutlet weak var whiteView: UIView!
    @IBOutlet weak var emergencyNumberTextView: DataDetectorTextView!
    @IBOutlet weak var residentialNumberTextView: DataDetectorTextView!
    @IBOutlet weak var businessNumberTextView: DataDetectorTextView?
    @IBOutlet weak var ttyttdNumberTextView: DataDetectorTextView?
    @IBOutlet weak var emergencyDescriptionLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel?
    @IBOutlet weak var thirdLabel: UILabel?
    @IBOutlet weak var customerServiceLabel: UILabel!
    
    let contactUsViewModel = ContactUsViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Contact Us", comment: "")
        
        view.backgroundColor = .primaryColor
        
        whiteView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        whiteView.layer.cornerRadius = 2
        
        emergencyDescriptionLabel.attributedText = contactUsViewModel.emergencyAttrString
        
        emergencyNumberTextView.text = contactUsViewModel.phoneNumber1
        emergencyNumberTextView.textContainerInset = .zero
        emergencyNumberTextView.tintColor = .actionBlue // Color of the phone numbers
        residentialNumberTextView.text = contactUsViewModel.phoneNumber2
        residentialNumberTextView.textContainerInset = .zero
        residentialNumberTextView.tintColor = .actionBlue // Color of the phone numbers
        businessNumberTextView?.text = contactUsViewModel.phoneNumber3
        businessNumberTextView?.textContainerInset = .zero
        businessNumberTextView?.tintColor = .actionBlue // Color of the phone numbers
        ttyttdNumberTextView?.text = contactUsViewModel.phoneNumber4
        ttyttdNumberTextView?.textContainerInset = .zero
        ttyttdNumberTextView?.tintColor = .actionBlue // Color of the phone numbers
        
        customerServiceLabel.text = NSLocalizedString("Customer Service", comment: "")
        firstLabel.text = contactUsViewModel.label1
        secondLabel?.text = contactUsViewModel.label2
        thirdLabel?.text = contactUsViewModel.label3
        
        extendedLayoutIncludesOpaqueBars = true
        
        automaticallyAdjustsScrollViewInsets = false
     
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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func facebookButtonTapped(_ sender: UIButton) {
        UIApplication.shared.openURL(NSURL(string: contactUsViewModel.facebookURL)! as URL)
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

