//
//  ForgotUsernameResultViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

protocol ForgotUsernameResultViewControllerDelegate: class {
    func forgotUsernameResultViewController(_ forgotUsernameResultViewController: UIViewController, didUnmaskUsername username: String)
}

class ForgotUsernameResultViewController: UIViewController {
    
    @IBOutlet weak var topLabel1: UILabel!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var topLabel2: UILabel!
    @IBOutlet weak var topLabel3: UILabel!
    
    @IBOutlet weak var singleAccountView: UIView!
    @IBOutlet weak var usernameEmailLabel: UILabel!
    @IBOutlet weak var singleAccountValueLabel: UILabel!
    
    @IBOutlet weak var selectLabel: UILabel!
    @IBOutlet weak var tableView: IntrinsicHeightTableView!
    
    @IBOutlet weak var answerSecurityQuestionButton: PrimaryButton!
    
    weak var delegate: ForgotUsernameResultViewControllerDelegate?
    
    var viewModel: ForgotUsernameViewModel!
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navigationTitle: String
        if Configuration.shared.opco != .bge {
            navigationTitle = Configuration.shared.opco.isPHI ? "Forgot Username" : "Forgot Email"
        } else {
            navigationTitle = "Forgot Username"
        }
        title = navigationTitle
        
        styleTopLabels()
        
        selectLabel.textColor = .neutralDark
        selectLabel.text = NSLocalizedString("Select Username / Email Address", comment: "")
        selectLabel.font = .headline
        
        if viewModel.maskedUsernames.count > 1 {
            singleAccountView.isHidden = true
        } else {
            selectLabel.isHidden = true
            tableView.isHidden = true
        }
        
        singleAccountView.layer.borderWidth = 1
        singleAccountView.layer.borderColor = UIColor.accentGray.cgColor
        usernameEmailLabel.textColor = .neutralDark
        usernameEmailLabel.font = .footnoteSemibold
        singleAccountValueLabel.textColor = .neutralDark
        
        let usernameEmailLabelText: String
        if Configuration.shared.opco != .bge {
            usernameEmailLabelText = Configuration.shared.opco.isPHI ? "Username / Email Address" : "Email"
        } else {
            usernameEmailLabelText = "Username / Email Address"
        }
        
        usernameEmailLabel.text = usernameEmailLabelText
        singleAccountValueLabel.font = .headline
        singleAccountValueLabel.text = viewModel.maskedUsernames.first?.email
        
        tableView.register(UINib(nibName: "RadioSelectionTableViewCell", bundle: nil), forCellReuseIdentifier: "ForgotUsernameCell")
        tableView.estimatedRowHeight = 51
        
        if viewModel.maskedUsernames.count > 1 {
            answerSecurityQuestionButton.isEnabled = false
        }
        
        answerSecurityQuestionButton.setTitle(FeatureFlagUtility.shared.bool(forKey: .isB2CAuthentication) ? "Done" : "Answer Security Question", for: .normal)
        
        if FeatureFlagUtility.shared.bool(forKey: .isB2CAuthentication) {
            selectLabel.text = ""
            topLabel1.text = ""
            topLabel2.text = ""
            topLabel3.text = NSLocalizedString("We found multiple accounts based on the information you gave us.", comment: "")
            signInButton.isHidden = true
        }
    }
    
    func styleTopLabels() {
        topLabel1.textColor = .neutralDark
        topLabel1.font = .headline
        
        signInButton.tintColor = .actionBrand
        signInButton.titleLabel?.font = .headlineSemibold
        
        topLabel2.textColor = .neutralDark
        topLabel2.font = .headline
        
        topLabel3.textColor = .neutralDark
        topLabel3.font = .headline
        
        if UIScreen.main.bounds.width <= 375 {
            // Prevent text from getting cut off on iPhone 5/SE with dynamic font all the way up
            topLabel2.text = NSLocalizedString("if you remember", comment: "")
            topLabel3.text = Configuration.shared.opco != .bge
                ? NSLocalizedString("your email or you can answer a security question to view your full email", comment: "")
                : NSLocalizedString("your username or you can answer a security question to view your full username", comment: "")
        }
    }
    
    @IBAction func onSignInPress() {
        FirebaseUtility.logEvent(.forgotUsername(parameters: [.return_to_signin]))
        
        dismissModal()
    }
    
    @IBAction func onAnswerSecurityQuestionsPress(_ sender: Any) {
        if FeatureFlagUtility.shared.bool(forKey: .isB2CAuthentication) {
            if FeatureFlagUtility.shared.bool(forKey: .isPkceAuthentication) {
                guard let rootNavVc = self.presentingViewController as? LargeTitleNavigationController else { return }
                
                for vc in rootNavVc.viewControllers {
                    guard let dest = vc as? LandingViewController else {
                        continue
                    }
                    self.delegate = dest
                    FirebaseUtility.logEvent(.forgotUsername(parameters: [.answer_question_complete]))

                    self.delegate?.forgotUsernameResultViewController(self, didUnmaskUsername: viewModel.maskedUsernames[viewModel.selectedUsernameIndex].email ?? "")
                    self.dismissModal()
                }
            } else {
                guard let rootNavVc = self.navigationController?.presentingViewController as? LargeTitleNavigationController else { return }
                for vc in rootNavVc.viewControllers {
                    guard let dest = vc as? LoginViewController else {
                        continue
                    }

                    self.delegate = dest

                    FirebaseUtility.logEvent(.forgotUsername(parameters: [.answer_question_complete]))

                    self.delegate?.forgotUsernameResultViewController(self, didUnmaskUsername: viewModel.maskedUsernames[viewModel.selectedUsernameIndex].email ?? "")
                    self.dismissModal()
                }
            }
        } else {
            performSegue(withIdentifier: "securityQuestionSegue", sender: nil)
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ForgotUsernameSecurityQuestionViewController {
            vc.viewModel = viewModel
        }
    }

}

extension ForgotUsernameResultViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.maskedUsernames.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ForgotUsernameCell", for: indexPath) as! RadioSelectionTableViewCell
        
        let maskedUsername = viewModel.maskedUsernames[indexPath.row]
        
        cell.label.text = maskedUsername.email
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectedUsernameIndex = indexPath.row
        answerSecurityQuestionButton.isEnabled = true
    }
}
