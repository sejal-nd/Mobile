//
//  BudgetBillingViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/20/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class BudgetBillingViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var whatIsBudgetBillingButtonView: UIView!
    @IBOutlet weak var whatIsBudgetBillingLabel: UILabel!
    @IBOutlet weak var yourPaymentWouldBeLabel: UILabel!
    @IBOutlet weak var paymentAmountLabel: UILabel!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var amountDescriptionLabel: UILabel!
    
    @IBOutlet weak var accountView: UIView!
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var enrollSwitch: Switch!
    
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerLabel: UILabel!
    
    @IBOutlet weak var reasonForStoppingTableView: UITableView!
    @IBOutlet weak var reasonForStoppingLabel: UILabel!
    @IBOutlet weak var reasonForStoppingTableViewHeightConstraint: NSLayoutConstraint!
    
    var gradientLayer: CAGradientLayer!
    
    let viewModel = BudgetBillingViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Budget Billing", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = submitButton
        viewModel.submitButtonEnabled().bindTo(submitButton.rx.isEnabled).addDisposableTo(disposeBag)
        
        view.backgroundColor = .whiteSmoke
        
        gradientLayer = CAGradientLayer()
        gradientLayer.frame = gradientView.bounds
        gradientLayer.colors = [
            UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1).cgColor,
            UIColor.white.cgColor,
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientView.layer.addSublayer(gradientLayer)
        
        whatIsBudgetBillingButtonView.layer.cornerRadius = 2
        whatIsBudgetBillingButtonView.layer.shadowOffset = CGSize(width: 0, height: 0)
        whatIsBudgetBillingButtonView.layer.shadowOpacity = 0.2
        whatIsBudgetBillingButtonView.layer.shadowColor = UIColor.black.cgColor
        whatIsBudgetBillingButtonView.layer.shadowRadius = 3
        whatIsBudgetBillingButtonView.layer.masksToBounds = false
        
        whatIsBudgetBillingLabel.textColor = .darkJungleGreen
        whatIsBudgetBillingLabel.text = NSLocalizedString("What is\nBudget Billing?", comment: "")
        
        yourPaymentWouldBeLabel.textColor = .outerSpace
        yourPaymentWouldBeLabel.text = NSLocalizedString("Your payment would be:", comment: "")
        
        paymentAmountLabel.textColor = .outerSpace
        monthLabel.textColor = .outerSpace
        monthLabel.text = NSLocalizedString("/Month", comment: "")
        
        amountDescriptionLabel.textColor = .outerSpace
        amountDescriptionLabel.text = NSLocalizedString("The amount above is your suggested billing amount. It may be adjusted quarterly based on your actual usage. After 12 months, the difference between your budget bill amount and actual use for the previous 12 months will be applied to your bill.", comment: "")
        
        // TODO: LOAD REAL DATA HERE
        accountNumberLabel.textColor = .darkJungleGreen
        addressLabel.textColor = .oldLavender
        
        viewModel.currentEnrollment.asDriver().drive(enrollSwitch.rx.isOn).addDisposableTo(disposeBag)
        enrollSwitch.rx.isOn.bindTo(viewModel.currentEnrollment).addDisposableTo(disposeBag)
        
        footerLabel.textColor = .darkJungleGreen
        footerLabel.text = String(format: NSLocalizedString("Budget billing option only includes %@ charges. Energy Supply charges are billed by your chosen generation provider.", comment: ""), Environment.sharedInstance.opco)
        
        reasonForStoppingLabel.textColor = .darkJungleGreen
        reasonForStoppingLabel.text = NSLocalizedString("Reason for stopping (select one)", comment: "")
        reasonForStoppingTableView.isHidden = true
        viewModel.unenrolling.asObservable().subscribe(onNext: { unenrolling in
            UIView.animate(withDuration: 0.3, animations: {
                self.reasonForStoppingTableView.isHidden = !unenrolling
            })
        }).addDisposableTo(disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.barTintColor = .primaryColor
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.isTranslucent = false
        
        let titleDict: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: UIFont(name: "OpenSans-Bold", size: 18)!
        ]
        navigationController?.navigationBar.titleTextAttributes = titleDict
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradientLayer.frame = gradientView.frame
        accountView.addBottomBorder(color: UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1), width: 0.5)
    }
    
    @IBAction func onButtonTouchDown(_ sender: Any) {
        let button = sender as! UIButton
        button.superview?.backgroundColor = .whiteButtonHighlight
    }
    
    @IBAction func onButtonTouchCancel(_ sender: Any) {
        let button = sender as! UIButton
        button.superview?.backgroundColor = .white
    }
    
    func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    func onSubmitPress() {
        print("Submit!")
    }

}

extension BudgetBillingViewController: UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
}

extension BudgetBillingViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReasonForStoppingCell", for: indexPath) as! BudgetBillingTableViewCell
        
        if indexPath.row == 0 {
            cell.label.text = String(format: NSLocalizedString("Closing %@ Account", comment: ""), Environment.sharedInstance.opco)
        } else if indexPath.row == 1 {
            cell.label.text = NSLocalizedString("Changing Bank Account", comment: "")
        } else if indexPath.row == 2 {
            cell.label.text = NSLocalizedString("Dissatisfied with program", comment: "")
        } else if indexPath.row == 3 {
            cell.label.text = NSLocalizedString("Program no longer meets my needs", comment: "")
        } else if indexPath.row == 4 {
            cell.label.text = NSLocalizedString("Other", comment: "")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectedUnenrollmentReason.value = indexPath.row
    }
    
}
