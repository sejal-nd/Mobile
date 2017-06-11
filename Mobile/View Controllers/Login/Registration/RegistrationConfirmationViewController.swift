//
//  RegistrationConfirmationViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 6/9/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class RegistrationConfirmationViewController: DismissableFormSheetViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var xButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    
    var registeredUsername: String? // TODO - Pass this from the previous screen's prepareForSegue

    override func viewDidLoad() {
        super.viewDidLoad()

        xButton.tintColor = .actionBlue
        
        titleLabel.textColor = .blackText
        titleLabel.text = NSLocalizedString("Registration Confirmation", comment: "")
        
        bodyLabel.textColor = .blackText
        bodyLabel.font = OpenSans.regular.of(textStyle: .body)
        
        let boldString = NSLocalizedString("If you do not verify your registration within 48 hours, you will be requested to register again.", comment: "")
        let fullString = NSLocalizedString("Please check your email for a confirmation message to verify your registration. That email will contain a link. Please complete your registration and validate your email address by clicking the link.\n\nIf your email address is not verified, your Paperless eBill enrollment will not be completed.\n\n\(boldString)\n\nPlease be sure to check your spam/junk mail folders and add \(emailAddress) to your safe sender list. Did not receive the confirmation email?", comment: "")
        let attrString = NSMutableAttributedString(string: fullString)
        attrString.addAttribute(NSFontAttributeName, value: OpenSans.bold.of(textStyle: .body), range: (fullString as NSString).range(of: boldString))
        
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = 25
        attrString.addAttribute(NSParagraphStyleAttributeName, value: style, range: NSMakeRange(0, fullString.characters.count))
        
        bodyLabel.attributedText = attrString
    }
    
    private var emailAddress: String {
        switch Environment.sharedInstance.opco {
        case .comEd:
            return "no-reply@comed.com"
        case .peco:
            return "no-reply@peco.com"
        case .bge:
            return "no-reply@bge.com"
        }
    }
    
    @IBAction func onXPress(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let landingVC = storyboard.instantiateViewController(withIdentifier: "landingViewController")
        let loginVC = storyboard.instantiateViewController(withIdentifier: "loginViewController")
        
        if let presentingNav = presentingViewController as? UINavigationController {
            // Reset the underlying navigation to the login screen, then dismiss the confirmation modal
            presentingNav.setViewControllers([landingVC, loginVC], animated: false)
            presentingNav.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func onResendEmailPress() {
        registeredUsername = "mardun@test.com"
        if let username = registeredUsername {
            let registrationService = ServiceFactory.createRegistrationService()
            
            LoadingView.show()
            registrationService.resendConfirmationEmail(username)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: {
                    LoadingView.hide()
                    self.view.makeToast(NSLocalizedString("Verification email sent", comment: ""), duration: 5.0, position: CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height - 50))
                }, onError: { err in
                    LoadingView.hide()
                    let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: err.localizedDescription, preferredStyle: .alert)
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self.present(alertVc, animated: true, completion: nil)
                })
                .addDisposableTo(disposeBag)
        }
    }

}
