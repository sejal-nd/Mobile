//
//  BudgetBillingViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/20/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import MBProgressHUD

protocol BudgetBillingViewControllerDelegate: class {
    func budgetBillingViewControllerDidEnroll(_ budgetBillingViewController: BudgetBillingViewController)
    func budgetBillingViewControllerDidUnenroll(_ budgetBillingViewController: BudgetBillingViewController)
}

class BudgetBillingViewController: UIViewController {
    
    weak var delegate: BudgetBillingViewControllerDelegate?
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var accountBackgroundView: UIView! // For stretching edge to edge on iPad
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var whatIsBudgetBillingButtonView: UIView!
    @IBOutlet weak var whatIsBudgetBillingLabel: UILabel!
    @IBOutlet weak var yourPaymentWouldBeLabel: UILabel!
    @IBOutlet weak var paymentAmountView: UIView!
    @IBOutlet weak var paymentAmountActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var paymentAmountLabel: UILabel!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var amountDescriptionLabel: UILabel!
    
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var enrollSwitch: Switch!
    
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerLabel: UILabel!
    
    @IBOutlet weak var reasonForStoppingTableView: UITableView!
    @IBOutlet weak var reasonForStoppingLabel: UILabel!
    
    @IBOutlet weak var bgeFooterView: UIView!
    @IBOutlet var bgeFooterCardViews: [UIView]!
    @IBOutlet weak var monthlyAmountTitleLabel: UILabel!
    @IBOutlet weak var monthlyAmountLabel: UILabel!
    @IBOutlet weak var monthlyAmountDescriptionLabel: UILabel!
    @IBOutlet weak var lastPaymentDateTitleLabel: UILabel!
    @IBOutlet weak var lastPaymentDateLabel: UILabel!
    @IBOutlet weak var payoffBalanceTitleLabel: UILabel!
    @IBOutlet weak var payoffBalanceLabel: UILabel!
    @IBOutlet weak var payoffBalanceDescriptionLabel: UILabel!
    @IBOutlet weak var currentBalanceTitleLabel: UILabel!
    @IBOutlet weak var currentBalanceLabel: UILabel!
    @IBOutlet weak var currentBalanceDescriptionLabel: UILabel!
    @IBOutlet weak var accDifferenceTitleLabel: UILabel!
    @IBOutlet weak var accDifferenceLabel: UILabel!
    @IBOutlet weak var accDifferenceDescriptionLabel: UILabel!
    
    var gradientLayer: CAGradientLayer!
    
    var initialEnrollment: Bool!
    var account: Account!
    var viewModel: BudgetBillingViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = BudgetBillingViewModel(initialEnrollment: initialEnrollment, billService: ServiceFactory.createBillService())
        
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
        
        whatIsBudgetBillingButtonView.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        whatIsBudgetBillingButtonView.layer.cornerRadius = 2
        whatIsBudgetBillingButtonView.layer.masksToBounds = false
        
        whatIsBudgetBillingLabel.textColor = .darkJungleGreen
        whatIsBudgetBillingLabel.text = NSLocalizedString("What is\nBudget Billing?", comment: "")
        
        yourPaymentWouldBeLabel.textColor = .outerSpace
        yourPaymentWouldBeLabel.text = NSLocalizedString("Your payment would be:", comment: "")
        
        paymentAmountActivityIndicator.color = .mediumPersianBlue
        paymentAmountLabel.textColor = .outerSpace
        monthLabel.textColor = .outerSpace
        monthLabel.text = NSLocalizedString("/Month", comment: "")
        
        amountDescriptionLabel.textColor = .outerSpace
        amountDescriptionLabel.text = viewModel.getAmountDescriptionText()
        
        // TODO: LOAD REAL DATA HERE
        accountNumberLabel.textColor = .darkJungleGreen
        addressLabel.textColor = .oldLavender
        
        viewModel.currentEnrollment.asDriver().drive(enrollSwitch.rx.isOn).addDisposableTo(disposeBag)
        enrollSwitch.rx.isOn.bindTo(viewModel.currentEnrollment).addDisposableTo(disposeBag)
        
        reasonForStoppingLabel.textColor = .darkJungleGreen
        reasonForStoppingLabel.text = NSLocalizedString("Reason for stopping (select one)", comment: "")
        reasonForStoppingTableView.isHidden = true
        if Environment.sharedInstance.opco == .comEd || Environment.sharedInstance.opco == .peco {
            viewModel.unenrolling.asObservable().subscribe(onNext: { unenrolling in
                UIView.animate(withDuration: 0.3, animations: {
                    self.reasonForStoppingTableView.isHidden = !unenrolling
                })
            }).addDisposableTo(disposeBag)
        }
        
        // BGE Footer View when user is enrolled
        if Environment.sharedInstance.opco == OpCo.bge && initialEnrollment {
            for view in bgeFooterCardViews {
                view.layer.cornerRadius = 2
                view.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
            }
            
            monthlyAmountTitleLabel.textColor = .darkJungleGreen
            monthlyAmountTitleLabel.text = NSLocalizedString("Monthly Budget Bill Amount", comment: "")
            monthlyAmountLabel.textColor = .darkJungleGreen
            monthlyAmountLabel.text = "$200.00"
            monthlyAmountDescriptionLabel.textColor = .outerSpace
            monthlyAmountDescriptionLabel.text = NSLocalizedString("Payment received after March 13, 2017 will incur a late charge.\n\nA late payment charge is applied to the unpaid balance of your BGE charges. The charge is up to 1.5% for the first month; additional charges will be assessed on unpaid balances past the first month, not to exceed 5%.", comment: "")
            
            lastPaymentDateTitleLabel.textColor = .darkJungleGreen
            lastPaymentDateTitleLabel.text = NSLocalizedString("Last Payment Date", comment: "")
            lastPaymentDateLabel.textColor = .darkJungleGreen
            lastPaymentDateLabel.text = "11/01/2016"
            
            payoffBalanceTitleLabel.textColor = .darkJungleGreen
            payoffBalanceTitleLabel.text = NSLocalizedString("Payoff Balance for BGE Service", comment: "")
            payoffBalanceLabel.textColor = .darkJungleGreen
            payoffBalanceLabel.text = "$174.13"
            payoffBalanceDescriptionLabel.textColor = .outerSpace
            payoffBalanceDescriptionLabel.text = NSLocalizedString("Total actual-usage charges for BGE gas and/or electric service after payments and adjustments.", comment: "")
            
            currentBalanceTitleLabel.textColor = .darkJungleGreen
            currentBalanceTitleLabel.text = NSLocalizedString("Current Balance for BGE Service", comment: "")
            currentBalanceLabel.textColor = .darkJungleGreen
            currentBalanceLabel.text = "$0.00"
            currentBalanceDescriptionLabel.textColor = .outerSpace
            currentBalanceDescriptionLabel.text = NSLocalizedString("Total billed charges for BGE gas and/or electric service after payments and adjustments.", comment: "")
            
            accDifferenceTitleLabel.textColor = .darkJungleGreen
            accDifferenceTitleLabel.text = NSLocalizedString("Accumulated Difference for BGE Service", comment: "")
            accDifferenceLabel.textColor = .darkJungleGreen
            accDifferenceLabel.text = "$174.13"
            accDifferenceDescriptionLabel.textColor = .outerSpace
            accDifferenceDescriptionLabel.text = NSLocalizedString("The difference between your Payoff Balance and your Current Balance for BGE Service.", comment: "")
        } else {
            bgeFooterView.isHidden = true
        }
        
        footerLabel.textColor = .darkJungleGreen
        if let footerText = viewModel.getFooterText() {
            footerLabel.text = footerText
        } else {
            footerView.isHidden = true
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.barTintColor = .primaryColor
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.isTranslucent = false
        
        let titleDict: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: OpenSans.bold.ofSize(18)
        ]
        navigationController?.navigationBar.titleTextAttributes = titleDict
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.getBudgetBillingInfo(forAccount: account, onSuccess: { (budgetBillingInfo: BudgetBillingInfo) in
            self.paymentAmountLabel.text = budgetBillingInfo.averageMonthlyBill
            self.paymentAmountActivityIndicator.isHidden = true
            self.paymentAmountView.isHidden = false
        }, onError: { errMessage in
            self.paymentAmountActivityIndicator.isHidden = true
            print("budget billing error: \(errMessage)")
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradientLayer.frame = gradientView.frame
        accountBackgroundView.addBottomBorder(color: UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1), width: 0.5)
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        gradientLayer.frame = gradientView.frame
        accountBackgroundView.addBottomBorder(color: UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1), width: 0.5)
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
        if viewModel.enrolling.value || viewModel.unenrolling.value {
            let message = viewModel.enrolling.value ? NSLocalizedString("Are you sure you want to exit this screen without completing enrollment?", comment: "") : NSLocalizedString("Are you sure you want to exit this screen without completing unenrollment?", comment: "")
            let alertVc = UIAlertController(title: NSLocalizedString("Exit Budget Billing", comment: ""), message: message, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Exit", comment: ""), style: .default, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
            present(alertVc, animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    func onSubmitPress() {
        if viewModel.enrolling.value {
            let hud = MBProgressHUD.showAdded(to: UIApplication.shared.keyWindow!, animated: true)
            hud.bezelView.style = MBProgressHUDBackgroundStyle.solidColor
            hud.bezelView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            hud.contentColor = .white
            
            viewModel.enroll(account: account, onSuccess: {
                hud.hide(animated: true)
                self.delegate?.budgetBillingViewControllerDidEnroll(self)
                self.navigationController?.popViewController(animated: true)
            }, onError: { errMessage in
                hud.hide(animated: true)
                let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self.present(alertVc, animated: true, completion: nil)
            })

        } else if viewModel.unenrolling.value {
            var message = ""
            if Environment.sharedInstance.opco == .comEd || Environment.sharedInstance.opco == .peco {
                message = NSLocalizedString("You will see your regular bill amount on your next billing cycle. Any credit balance remaining in your account will be applied to your bill until used, and any negative account balance will become due with your next bill.", comment: "")
            } else { // BGE
                // TODO: There are 3 dynamic messages here, we need logic to determine which to use
                message = NSLocalizedString("You are responsible for the full budget bill amount shown on your current bill. Your new billing amount will reflect your actual usage.", comment: "")
//                message = NSLocalizedString("You are responsible for the full budget bill amount shown on your current bill. Your new billing amount will reflect your actual usage. This will include a debit of $XX.XX beginning with your next bill.", comment: "")
//                message = NSLocalizedString("You are responsible for the full budget bill amount shown on your current bill. Your new billing amount will reflect your actual usage. This will include a credit of $XX.XX beginning with your next bill.", comment: "")
            }
            let alertVc = UIAlertController(title: NSLocalizedString("Unenroll from Budget Billing", comment: ""), message: message, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Unenroll", comment: ""), style: .destructive, handler: { _ in
                let hud = MBProgressHUD.showAdded(to: UIApplication.shared.keyWindow!, animated: true)
                hud.bezelView.style = MBProgressHUDBackgroundStyle.solidColor
                hud.bezelView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
                hud.contentColor = .white
                
                self.viewModel.unenroll(account: self.account, onSuccess: {
                    hud.hide(animated: true)
                    self.delegate?.budgetBillingViewControllerDidUnenroll(self)
                    self.navigationController?.popViewController(animated: true)
                }, onError: { errMessage in
                    hud.hide(animated: true)
                    let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self.present(alertVc, animated: true, completion: nil)
                })

            }))
            present(alertVc, animated: true, completion: nil)
        }
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
        
        cell.label.text = viewModel.getReasonString(forIndex: indexPath.row)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectedUnenrollmentReason.value = indexPath.row
    }
    
}
