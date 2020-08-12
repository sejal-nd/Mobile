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
    @IBOutlet weak var iconImageView: UIImageView!
    
    var registeredUsername: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        xButton.tintColor = .actionBlue
        xButton.accessibilityLabel = NSLocalizedString("Close", comment: "")
        
        titleLabel.textColor = .deepGray
        titleLabel.font = OpenSans.semibold.of(textStyle: .title3)
        if RemoteConfigUtility.shared.bool(forKey: .hasNewRegistration) {
            titleLabel.text = NSLocalizedString("You’re almost done! Please check your email.", comment: "")
        } else {
            titleLabel.text = NSLocalizedString("Thank you for your registration", comment: "")
        }
        bodyLabel.textColor = .deepGray
        bodyLabel.font = SystemFont.regular.of(textStyle: .body)
        if RemoteConfigUtility.shared.bool(forKey: .hasNewRegistration) {
            iconImageView.image = #imageLiteral(resourceName: "ic_registration_confirmation")
            let boldString = NSLocalizedString("Having trouble?", comment: "")
            let fullString = NSLocalizedString("A verification email has been sent to \(registeredUsername ?? "").\n\nClick on the link in the email from \(Environment.shared.opco.displayString) within 48 hours. Once the link expires, you’ll be required to start the registration process from the beginning.\n\n\(boldString)", comment: "")
            let attrString = NSMutableAttributedString(string: fullString)
            attrString.addAttribute(.font, value: SystemFont.bold.of(textStyle: .body), range: (fullString as NSString).range(of: boldString))
            
            let style = NSMutableParagraphStyle()
            style.minimumLineHeight = 25
            attrString.addAttribute(.paragraphStyle, value: style, range: NSMakeRange(0, fullString.count))
            
            let secondaryString = "\n\nCheck your spam/junk mail folder and add \(emailAddress) to your safe sender list or send the verification email again."
            let secondaryAttrString = NSMutableAttributedString(string: secondaryString)
            secondaryAttrString.addAttribute(.font, value: SystemFont.semibold.of(textStyle: .body), range: (secondaryString as NSString).range(of: boldString))
            
            let secondaryStyle = NSMutableParagraphStyle()
            secondaryStyle.minimumLineHeight = 15
            secondaryAttrString.addAttribute(.paragraphStyle, value: secondaryStyle, range: NSMakeRange(0, secondaryString.count))
            attrString.append(secondaryAttrString)
            bodyLabel.attributedText = attrString
        } else {
            iconImageView.image = #imageLiteral(resourceName: "ic_confirmation_mini")
            let boldString = NSLocalizedString("If you do not verify your registration within 48 hours, you will be requested to register again.", comment: "")
            let fullString = NSLocalizedString("Please check your email for a confirmation message to verify your registration. That email will contain a link. Please complete your registration and validate your email address by clicking the link.\n\nIf your email address is not verified, your Paperless eBill enrollment will not be completed.\n\n\(boldString)\n\nPlease be sure to check your spam/junk mail folders and add \(emailAddress) to your safe sender list. Did not receive the confirmation email?", comment: "")
            let attrString = NSMutableAttributedString(string: fullString)
            attrString.addAttribute(.font, value: SystemFont.semibold.of(textStyle: .body), range: (fullString as NSString).range(of: boldString))
            
            let style = NSMutableParagraphStyle()
            style.minimumLineHeight = 25
            attrString.addAttribute(.paragraphStyle, value: style, range: NSMakeRange(0, fullString.count))
            
            bodyLabel.attributedText = attrString
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        GoogleAnalytics.log(event: .registerAccountComplete)
    }
    
    private var emailAddress: String {
        switch Environment.shared.opco {
        case .comEd:
            return "no-reply@comed.com"
        case .peco:
            return "no-reply@peco.com"
        case .bge:
            return "no-reply@bge.com"
        case .pepco:
            return "todo"
        case .ace:
            return "todo"
        case .delmarva:
            return "todo"
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
        if let username = registeredUsername {
            let registrationService = ServiceFactory.createRegistrationService()
            
            LoadingView.show()
            registrationService.resendConfirmationEmail(username)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    LoadingView.hide()
                    FirebaseUtility.logEvent(.register, parameters: [EventParameter(parameterName: .action, value: .resend_email)])
                    if RemoteConfigUtility.shared.bool(forKey: .hasNewRegistration) {
                        self?.view.showToast(NSLocalizedString("A new verification email has been sent.", comment: ""))
                    } else {
                        self?.view.showToast(NSLocalizedString("Verification email sent", comment: ""))
                    }
                    GoogleAnalytics.log(event: .registerResendEmail)
                    }, onError: { [weak self] err in
                        LoadingView.hide()
                        let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: err.localizedDescription, preferredStyle: .alert)
                        alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                        self?.present(alertVc, animated: true, completion: nil)
                })
                .disposed(by: disposeBag)
        }
    }
    
}
