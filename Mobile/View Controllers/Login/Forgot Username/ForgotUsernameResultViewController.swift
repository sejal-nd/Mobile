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
    
    @IBOutlet weak var topTextView: ZeroInsetTextView!
    @IBOutlet weak var topTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var selectLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var answerSecurityQuestionButton: PrimaryButton!
    @IBOutlet weak var backToSignInButton: UIButton!
    
    var viewModel: ForgotUsernameViewModel!
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Forgot Username", comment: "")
        
        styleTopTextView()
        
        selectLabel.textColor = .blackText
        selectLabel.text = viewModel.maskedUsernames.count > 1 ? NSLocalizedString("Select Username / Email Address:", comment: "") : NSLocalizedString("Username / Email Address:", comment: "")
        selectLabel.font = SystemFont.bold.of(textStyle: .subheadline)
        
        tableView.separatorInset = .zero
        tableViewHeightConstraint.constant = CGFloat(53 * viewModel.maskedUsernames.count) - 1
        
        answerSecurityQuestionButton.isEnabled = viewModel.maskedUsernames.count <= 1
        tableView.rx.itemSelected.asDriver().drive(onNext: { [weak self] indexPath in
            guard let self = self else { return }
            if self.viewModel.maskedUsernames.count > 1 {
                self.viewModel.selectedUsernameIndex = indexPath.row
                self.answerSecurityQuestionButton.isEnabled = true
            } else {
                self.tableView.deselectRow(at: indexPath, animated: false)
            }
        }).disposed(by: disposeBag)
        
        backToSignInButton.tintColor = .actionBlue
        backToSignInButton.titleLabel?.font = SystemFont.bold.of(textStyle: .title1)
    }
    
    func styleTopTextView() {
        let localizedString = NSLocalizedString("You can sign in if you remember your username or you can answer a security question to view your full username.", comment: "")
        
        let attrString = NSMutableAttributedString(string: localizedString)
        let fullRange = NSMakeRange(0, attrString.length)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 24 // Line height
        attrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
        
        attrString.addAttribute(.font, value: SystemFont.semibold.of(textStyle: .subheadline), range: fullRange)
        attrString.addAttribute(.foregroundColor, value: UIColor.blackText, range: fullRange)
        
        topTextView.attributedText = attrString
        topTextView.tintColor = .actionBlue
        
        // In case the localized string needs to grow the text view:
        topTextView.sizeToFit()
        topTextView.layoutIfNeeded()
        topTextViewHeightConstraint.constant = topTextView.sizeThatFits(CGSize(width: topTextView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
    }
    
    @IBAction func onBackToSignInPress() {
        for vc in (navigationController?.viewControllers)! {
            if let dest = vc as? LoginViewController {
                navigationController?.popToViewController(dest, animated: true)
                break
            }
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ForgotUsernameSecurityQuestionViewController {
            vc.viewModel.phoneNumber.value = viewModel.phoneNumber.value
            vc.viewModel.identifierNumber.value = viewModel.identifierNumber.value
            vc.viewModel.accountNumber.value = viewModel.accountNumber.value
            vc.viewModel.maskedUsernames = viewModel.maskedUsernames
            vc.viewModel.selectedUsernameIndex = viewModel.selectedUsernameIndex
        }
    }

}

extension ForgotUsernameResultViewController: UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.maskedUsernames.count
    }
}

extension ForgotUsernameResultViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ForgotUsernameCell", for: indexPath) as! ForgotUsernameTableViewCell
        
        let maskedUsername = viewModel.maskedUsernames[indexPath.row]
        
        cell.label.text = maskedUsername.email
        
        return cell
    }
    
}
