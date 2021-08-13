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
        titleLabel.text = NSLocalizedString("You’re almost done! Please check your email.", comment: "")

        bodyLabel.textColor = .deepGray
        bodyLabel.font = SystemFont.regular.of(textStyle: .body)
        
        iconImageView.image = #imageLiteral(resourceName: "ic_registration_confirmation")
        
        let fullString = NSLocalizedString("A verification email has been sent to \(registeredUsername ?? "").\n\nClick on the link in the email from \(Configuration.shared.opco.displayString) within 48 hours. Once the link expires, you’ll be required to start the registration process from the beginning.\n\n", comment: "")
        let attrString = NSMutableAttributedString(string: fullString)
        
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = 24
        attrString.addAttribute(.paragraphStyle, value: style, range: NSMakeRange(0, fullString.count))
        
        let boldString = NSLocalizedString("\nHaving trouble?\n\n", comment: "")
        let secondaryAttrString = NSMutableAttributedString(string: boldString)
        secondaryAttrString.addAttribute(.font, value: SystemFont.bold.of(textStyle: .body), range: (boldString as NSString).range(of: boldString))
        
        let secondaryStyle = NSMutableParagraphStyle()
        secondaryStyle.minimumLineHeight = 15
        secondaryStyle.maximumLineHeight = 15
        secondaryAttrString.addAttribute(.paragraphStyle, value: secondaryStyle, range: NSMakeRange(0, boldString.count))
        
        let tertiaryString = "Check your spam/junk mail folder and add \n\(emailAddress) to your safe sender list or send the verification email again."
        let tertiaryAttributedString = NSMutableAttributedString(string: tertiaryString)
        let tertiaryStyle = NSMutableParagraphStyle()
        tertiaryStyle.minimumLineHeight = 24
        tertiaryAttributedString.addAttribute(.paragraphStyle, value: tertiaryStyle, range: NSMakeRange(0, tertiaryString.count))
        
        attrString.append(secondaryAttrString)
        attrString.append(tertiaryAttributedString)
        
        bodyLabel.attributedText = attrString
    }
    
    override func viewDidAppear(_ animated: Bool) {
        GoogleAnalytics.log(event: .registerAccountComplete)
    }
    
    private var emailAddress: String {
        switch Configuration.shared.opco {
        case .comEd:
            return "no-reply@comed.com"
        case .peco:
            return "no-reply@peco.com"
        case .bge:
            return "no-reply@bge.com"
        case .pepco:
            return "no-reply@pepco.com"
        case .ace:
            return "no-reply@ace.com"
        case .delmarva:
            return "no-reply@dpl.com"
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
        guard let username = registeredUsername else { return }
        LoadingView.show()
        
        let usernameRequest = UsernameRequest(username: username)
        RegistrationService.sendConfirmationEmail(request: usernameRequest) { [weak self] result in
            switch result {
            case .success:
                FirebaseUtility.logEvent(.register(parameters: [.resend_email]))
                self?.view.showToast(NSLocalizedString("Verification email sent", comment: ""))
                GoogleAnalytics.log(event: .registerResendEmail)
            case .failure(let error):
                let alertVc = UIAlertController(title: error.title, message: error.description, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alertVc, animated: true, completion: nil)
            }
            
            LoadingView.hide()
        }
    }
    
}
