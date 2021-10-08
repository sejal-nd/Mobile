//
//  GeneralSubmitErrorViewController.swift
//  EUMobile
//
//  Created by Aman Vij on 07/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

class GeneralSubmitErrorViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var helplineDescriptionLabel: UILabel!

    var tapgesture: UITapGestureRecognizer!
    let helplineDescription = "Please call our Customer Care Center at 1-800-685-0123 Monday-Friday from 7 a.m. to 7 p.m. for more information."
    let contactNumber = "1-800-685-0123"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialSetup()
    }
    
    func initialSetup() {
        
        navigationSetup()
        setUIFontStyle()
        dataBinding()
    }
    
    private func navigationSetup() {
        
        navigationItem.hidesBackButton = false
        let newBackButton = UIBarButtonItem(image: UIImage(named: "ic_close"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(GeneralSubmitErrorViewController.back(sender:)))
        navigationItem.leftBarButtonItem = newBackButton
    }
    
    private func setUIFontStyle() {
        
        statusLabel.font = OpenSans.semibold.of(textStyle: .title3)
        helplineDescriptionLabel.font = SystemFont.regular.of(textStyle: .subheadline)
    }
    
    private func dataBinding() {
        
        let range = (helplineDescription as NSString).range(of: contactNumber)
        let attributedString = NSMutableAttributedString(string: helplineDescription)
        attributedString.addAttributes([ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15, weight: .semibold), NSAttributedString.Key.foregroundColor: UIColor.actionBlue], range: range)
        helplineDescriptionLabel.attributedText = attributedString
        helplineDescriptionLabel.isUserInteractionEnabled = true
        
        tapgesture = UITapGestureRecognizer(target: self, action: #selector(tappedOnLabel(_ :)))
        tapgesture.numberOfTapsRequired = 1
        helplineDescriptionLabel.addGestureRecognizer(tapgesture)
    }
    
    @objc func tappedOnLabel(_ gesture: UITapGestureRecognizer) {
        
        let range = (helplineDescription as NSString).range(of: contactNumber)
        if tapgesture.didTapAttributedTextInLabel(label: helplineDescriptionLabel, inRange: range) {
            
            UIApplication.shared.openPhoneNumberIfCan(contactNumber)
        }
    }
    
    @objc func back(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}
