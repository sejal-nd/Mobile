//
//  ForgotUsernameResultViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class ForgotUsernameResultViewController: UIViewController {
    
    @IBOutlet weak var topTextView: UITextView!
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
        
        selectLabel.textColor = .darkJungleGreen
        selectLabel.text = viewModel.maskedUsernames.count > 1 ? NSLocalizedString("Select Username / Email Address:", comment: "") : NSLocalizedString("Username / Email Address:", comment: "")
        
        tableView.separatorInset = .zero
        tableViewHeightConstraint.constant = CGFloat(53 * viewModel.maskedUsernames.count) - 1
        
        answerSecurityQuestionButton.isEnabled = viewModel.maskedUsernames.count <= 1
        tableView.rx.itemSelected.asObservable().subscribe(onNext: { indexPath in
            if self.viewModel.maskedUsernames.count > 1 {
                self.viewModel.selectedUsernameIndex = indexPath.row
                self.answerSecurityQuestionButton.isEnabled = true
            } else {
                self.tableView.deselectRow(at: indexPath, animated: false)
            }
        }).addDisposableTo(disposeBag)
        
        backToSignInButton.tintColor = .mediumPersianBlue
    }
    
    func styleTopTextView() {
//        let signInString = NSLocalizedString("Sign In", comment: "")
//        let localizedString = String(format: NSLocalizedString("Remember your username? You can %@, or you can select an account to answer its security question to view your full username.", comment: ""), signInString)
        let localizedString = NSLocalizedString("You can sign in if you remember your username or you can answer a security question to view your full username.", comment: "")
        
        let attrString = NSMutableAttributedString(string: localizedString)
        let fullRange = NSMakeRange(0, attrString.length)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 24 // Line height
        attrString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: fullRange)
        
        attrString.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 16, weight: UIFontWeightSemibold), range: fullRange)
        attrString.addAttribute(NSForegroundColorAttributeName, value: UIColor.darkJungleGreen, range: fullRange)
        
//        let url = URL(fileURLWithPath: "") // Does not matter
//        attrString.addAttribute(NSLinkAttributeName, value: url, range: (localizedString as NSString).range(of: signInString))
        
//        topTextView.delegate = self
        topTextView.textContainerInset = .zero
        topTextView.textContainer.lineFragmentPadding = 0
        topTextView.attributedText = attrString
        topTextView.tintColor = .mediumPersianBlue
        
        // In case the localized string needs to grow the text view:
        topTextView.sizeToFit()
        topTextView.layoutIfNeeded()
        topTextViewHeightConstraint.constant = topTextView.sizeThatFits(CGSize(width: topTextView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
    }
    
    @IBAction func onBackToSignInPress() {
        for vc in (navigationController?.viewControllers)! {
            if vc.isKind(of: LoginViewController.self) {
                self.navigationController?.popToViewController(vc, animated: true)
            }
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination.isKind(of: SecurityQuestionViewController.self) {
            let vc = segue.destination as! SecurityQuestionViewController
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

//extension ForgotUsernameResultViewController: UITextViewDelegate {
//    
//    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
//        onBackToSignInPress()
//        return false
//    }
//    
//}
