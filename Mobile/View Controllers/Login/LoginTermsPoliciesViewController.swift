//
//  LoginTermsPoliciesViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class LoginTermsPoliciesViewController: UIViewController {
    
    @IBOutlet weak var agreeSwitch: UISwitch!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var agreeView: UIView!
    @IBOutlet weak var agreeLabel: UILabel!
    
    let viewModel = TermsPoliciesViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.textContainerInset = UIEdgeInsetsMake(0, 12, 8, 16)
        textView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 8, 4)
        textView.attributedText = viewModel.attributedTermsString

        agreeView.layer.shadowColor = UIColor.black.cgColor
        agreeView.layer.shadowOffset = CGSize(width: 0, height: -1)
        agreeView.layer.shadowOpacity = 0.1
        agreeView.layer.shadowRadius = 2
        agreeView.layer.masksToBounds = false

        agreeSwitch.tintColor = UIColor(red: 193/255, green: 193/255, blue: 193/255, alpha: 1)
        agreeSwitch.onTintColor = .primaryColor
        agreeSwitch.backgroundColor = .switchOffColor
        agreeSwitch.layer.cornerRadius = 16
        _ = agreeSwitch.rx.isOn.bindTo(continueButton.rx.isEnabled)
        
        agreeLabel.text = viewModel.agreeLabelText;
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onContinuePress() {
        UserDefaults.standard.set(true, forKey: UserDefaultKeys.HasAcceptedTerms)
        dismiss(animated: true, completion: nil)
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
