//
//  GeneralSubmitErrorViewController.swift
//  EUMobile
//
//  Created by Aman Vij on 07/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

class GeneralSubmitErrorViewController: UIViewController {
    @IBOutlet weak var helplineDescriptionLabel: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialSetup()
    }
    
    func initialSetup() {
        navigationItem.hidesBackButton = false
        let newBackButton = UIBarButtonItem(image: UIImage(named: "ic_close"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(GeneralSubmitErrorViewController.back(sender:)))
        navigationItem.leftBarButtonItem = newBackButton
        
        let helplineDescription = "Please call our Customer Care Center at 1-800-685-0123 Monday-Friday from 7 a.m. to 7 p.m. for more information."
        let range = (helplineDescription as NSString).range(of: "1-800-685-0123")
        let attributedString = NSMutableAttributedString(string: helplineDescription)
        attributedString.addAttributes([ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .semibold), NSAttributedString.Key.foregroundColor: UIColor.actionBlue], range: range)
        helplineDescriptionLabel.attributedText = attributedString
        
        attributedString.addAttribute(.link, value: "1-800-685-0123", range: range)

        
        if let url = URL(string: "tel://\(1-800-685-0123)"), UIApplication.shared.canOpenURL(url) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    private func callNumber(phoneNumber:String) {

      if let phoneCallURL = URL(string: "tel://\(phoneNumber)") {

        let application:UIApplication = UIApplication.shared
        if (application.canOpenURL(phoneCallURL)) {
            application.open(phoneCallURL, options: [:], completionHandler: nil)
        }
      }
    }
    
    @objc func back(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}
