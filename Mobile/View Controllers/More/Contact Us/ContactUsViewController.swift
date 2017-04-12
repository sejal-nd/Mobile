//
//  ContactUsViewController.swift
//  Mobile
//
//  Created by Wesley Weitzel on 4/5/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class ContactUsViewController: UIViewController, UIScrollViewDelegate {

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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .primaryColor
        
        let contactUsViewModel = ContactUsViewModel()
        emergencyDescriptionLabel.attributedText = contactUsViewModel.makeAttributedString()
        
        emergencyNumberTextView.textContainerInset = .zero
        emergencyNumberTextView.tintColor = .mediumPersianBlue // Color of the phone numbers
        residentialNumberTextView.textContainerInset = .zero
        residentialNumberTextView.tintColor = .mediumPersianBlue // Color of the phone numbers
        businessNumberTextView?.textContainerInset = .zero
        businessNumberTextView?.tintColor = .mediumPersianBlue // Color of the phone numbers
        ttyttdNumberTextView?.textContainerInset = .zero
        ttyttdNumberTextView?.tintColor = .mediumPersianBlue // Color of the phone numbers
        title = "Contact Us"
        
        customerServiceLabel.text = NSLocalizedString("Customer Service", comment: "")
        firstLabel.text = contactUsViewModel.makeLabel1()
        secondLabel?.text = contactUsViewModel.makeLabel2()
        thirdLabel?.text = contactUsViewModel.makeLabel3()
        
        extendedLayoutIncludesOpaqueBars = true
        
        automaticallyAdjustsScrollViewInsets = false
     
    }
    
    func boldText(text: NSMutableAttributedString) -> NSMutableAttributedString {
        let range = NSMakeRange(0, text.length)
        text.addAttribute(NSFontAttributeName, value: UIFont(name: "OpenSans-BoldItalic", size: 12)!, range: range)
        return text
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            tabBarController?.tabBar.isHidden = true
        }
        
        //navigationController?.navigationBar.barStyle = .black // Needed for white status bar
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.isTranslucent = true
        //navigationController?.setNavigationBarHidden(false, animated: true)
        
        let titleDict: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: UIFont(name: "OpenSans-Bold", size: 18)!
        ]
        navigationController?.navigationBar.titleTextAttributes = titleDict
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            if let splitView = splitViewController as? MoreSplitViewController {
                splitView.setStatusBarStyle(style: .lightContent)
            }
            splitViewController?.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func facebookButtonTapped(_ sender: UIButton) {
        UIApplication.shared.openURL(NSURL(string: "https://www.facebook.com/ComEd")! as URL)
    }

    @IBAction func twitterButtonTapped(_ sender: UIButton) {
        UIApplication.shared.openURL(NSURL(string: "https://twitter.com/ComEd")! as URL)
    }
    
    @IBAction func youtubeButtonTapped(_ sender: UIButton) {
        UIApplication.shared.openURL(NSURL(string: "https://www.youtube.com/user/CommonwealthEdison/ComEd")! as URL)
    }
    
    @IBAction func linkedinButtonTapped(_ sender: UIButton) {
        UIApplication.shared.openURL(NSURL(string: "https://www.linkedin.com/company/comed")! as URL)
    }
    
    @IBAction func flickrButtonTapped(_ sender: UIButton) {
        UIApplication.shared.openURL(NSURL(string: "https://www.flickr.com/photos/commonwealthedison")! as URL)
    }
    
    @IBAction func pinterestButtonTapped(_ sender: UIButton) {
        UIApplication.shared.openURL(NSURL(string: "https://www.pinterest.com/comedil/")! as URL)
    }
    
    @IBAction func instagramButtonTapped(_ sender: UIButton) {
        UIApplication.shared.openURL(NSURL(string: "https://www.instagram.com/commonwealthedison/")! as URL)
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

