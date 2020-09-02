//
//  ForgotUsernameResultViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

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
    
    var viewModel: ForgotUsernameViewModel!
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = RemoteConfigUtility.shared.bool(forKey: .hasNewRegistration)
            ? NSLocalizedString("Forgot Email", comment: "")
            : NSLocalizedString("Forgot Username", comment: "")
        
        styleTopLabels()
        
        selectLabel.textColor = .deepGray
        selectLabel.text = NSLocalizedString("Select Username / Email Address", comment: "")
        selectLabel.font = SystemFont.regular.of(textStyle: .headline)
        
        if viewModel.maskedUsernames.count > 1 {
            singleAccountView.isHidden = true
        } else {
            selectLabel.isHidden = true
            tableView.isHidden = true
        }
        
        singleAccountView.layer.borderWidth = 1
        singleAccountView.layer.borderColor = UIColor.accentGray.cgColor
        usernameEmailLabel.textColor = .deepGray
        usernameEmailLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        singleAccountValueLabel.textColor = .deepGray
        usernameEmailLabel.text = RemoteConfigUtility.shared.bool(forKey: .hasNewRegistration)
               ? NSLocalizedString("Email", comment: "")
               : NSLocalizedString("Username / Email Address", comment: "")
        singleAccountValueLabel.font = OpenSans.regular.of(textStyle: .headline)
        singleAccountValueLabel.text = viewModel.maskedUsernames.first?.email
        
        tableView.register(UINib(nibName: "RadioSelectionTableViewCell", bundle: nil), forCellReuseIdentifier: "ForgotUsernameCell")
        tableView.estimatedRowHeight = 51
        
        if viewModel.maskedUsernames.count > 1 {
            answerSecurityQuestionButton.isEnabled = false
        }
    }
    
    func styleTopLabels() {
        topLabel1.textColor = .deepGray
        topLabel1.font = SystemFont.regular.of(textStyle: .headline)
        
        signInButton.tintColor = .actionBlue
        signInButton.titleLabel?.font = SystemFont.bold.of(textStyle: .headline)
        
        topLabel2.textColor = .deepGray
        topLabel2.font = SystemFont.regular.of(textStyle: .headline)
        
        topLabel3.textColor = .deepGray
        topLabel3.font = SystemFont.regular.of(textStyle: .headline)
        
        if UIScreen.main.bounds.width <= 375 {
            // Prevent text from getting cut off on iPhone 5/SE with dynamic font all the way up
            topLabel2.text = NSLocalizedString("if you remember", comment: "")
            let topLabelText = RemoteConfigUtility.shared.bool(forKey: .hasNewRegistration)
                ? NSLocalizedString("your email or you can answer a security question to view your full email", comment: "")
                : NSLocalizedString("your username or you can answer a security question to view your full username", comment: "")
            topLabel3.text = topLabelText
        }
    }
    
    @IBAction func onSignInPress() {
        FirebaseUtility.logEvent(.forgotUsername, parameters: [EventParameter(parameterName: .action, value: .return_to_signin)])
        
        dismissModal()
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
