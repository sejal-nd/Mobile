//
//  BudgetBillingViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/20/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

protocol BudgetBillingViewControllerDelegate: class {
    func budgetBillingViewControllerDidEnroll(_ budgetBillingViewController: UIViewController, averageMonthlyBill: String?)
    func budgetBillingViewControllerDidUnenroll(_ budgetBillingViewController: UIViewController)
}

class BudgetBillingViewController: UIViewController {
    
    weak var delegate: BudgetBillingViewControllerDelegate?
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet weak var descriptionHeaderLabel: UILabel!

    @IBOutlet weak var paymentAmountView: UIView!
    @IBOutlet weak var yourPaymentWouldBeLabel: UILabel!
    @IBOutlet weak var paymentAmountLabel: UILabel!
    @IBOutlet weak var amountDescriptionLabel: UILabel!
        
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
    
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerLabel: UILabel!
    
    @IBOutlet weak var stickyFooterView: StickyFooterView!
    @IBOutlet weak var enrollButton: PrimaryButtonNew!
    @IBOutlet weak var unenrollView: UIView!
    @IBOutlet weak var unenrollButtonLabel: UILabel!
    @IBOutlet weak var unenrollButton: UIButton!
    
    var accountDetail: AccountDetail!
    var viewModel: BudgetBillingViewModel!
    
    var bgeDynamicUnenrollMessage: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = BudgetBillingViewModel(accountDetail: accountDetail, billService: ServiceFactory.createBillService(), alertsService: ServiceFactory.createAlertsService())
        
        title = NSLocalizedString("Budget Billing", comment: "")
        
        let infoButton = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_tooltip.pdf"), style: .plain, target: self, action: #selector(onTooltipPress))
        navigationItem.rightBarButtonItem = infoButton
        infoButton.isAccessibilityElement = true
        infoButton.accessibilityLabel = NSLocalizedString("Tooltip", comment: "")
        
        descriptionHeaderLabel.textColor = .deepGray
        descriptionHeaderLabel.font = SystemFont.regular.of(textStyle: .body)
        if accountDetail.isBudgetBillEnrollment {
            descriptionHeaderLabel.text = NSLocalizedString("You are currently enrolled in Budget Billing. Your monthly Budget Billing payment is adjusted periodically based on your actual usage.", comment: "")
        } else {
            descriptionHeaderLabel.text = NSLocalizedString("Budget Billing spreads costs evenly month to month by charging a pre-arranged amount with each bill. It’s a predictable monthly payment that eliminates montlhy or seasonal variation.", comment: "")
        }
        descriptionHeaderLabel.setLineHeight(lineHeight: 24)
        
        paymentAmountView.layer.borderColor = UIColor.accentGray.cgColor
        paymentAmountView.layer.borderWidth = 1

        yourPaymentWouldBeLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        yourPaymentWouldBeLabel.textColor = .deepGray
        yourPaymentWouldBeLabel.text = NSLocalizedString("Your monthly payment would be", comment: "")
        paymentAmountLabel.textColor = .deepGray
        paymentAmountLabel.font = OpenSans.semibold.of(textStyle: .title1)
        
        amountDescriptionLabel.font = SystemFont.regular.of(textStyle: .footnote)
        amountDescriptionLabel.textColor = .deepGray
        amountDescriptionLabel.text = viewModel.amountDescriptionText
        
//        enrollmentLabel.textColor = .blackText
//        enrollmentLabel.font = OpenSans.regular.of(textStyle: .headline)
//        enrollmentLabel.text = NSLocalizedString("Budget Billing Enrollment Status", comment: "")
//        enrollmentLabel.isAccessibilityElement = false
//
//        viewModel.currentEnrollment.asDriver().drive(enrollSwitch.rx.isOn).disposed(by: disposeBag)
//        enrollSwitch.rx.isOn.bind(to: viewModel.currentEnrollment).disposed(by: disposeBag)
//        enrollSwitch.accessibilityLabel = enrollmentLabel.text
        
//        if Environment.shared.opco == .comEd || Environment.shared.opco == .peco {
//            viewModel.unenrolling.asDriver().drive(onNext: { [weak self] unenrolling in
//                UIView.animate(withDuration: 0.3, animations: {
//                    self?.reasonForStoppingContainer.isHidden = !unenrolling
//                })
//            }).disposed(by: disposeBag)
//        }

        // BGE Footer View when user is enrolled
        if Environment.shared.opco == .bge && accountDetail.isBudgetBillEnrollment {
            for view in bgeFooterCardViews {
                view.layer.cornerRadius = 10
                view.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
            }
            
            monthlyAmountTitleLabel.font = OpenSans.bold.of(textStyle: .footnote)
            monthlyAmountTitleLabel.textColor = .blackText
            monthlyAmountTitleLabel.text = NSLocalizedString("Monthly Budget Bill Amount", comment: "")
            monthlyAmountLabel.textColor = .blackText
            monthlyAmountDescriptionLabel.font = SystemFont.regular.of(textStyle: .footnote)
            monthlyAmountDescriptionLabel.textColor = .deepGray
            monthlyAmountDescriptionLabel.text = NSLocalizedString("The amount that you are billed for BGE gas and/or electric service each month. This charge appears on the first page of your bill under Charges/Adjustments this period.", comment: "")
            
            lastPaymentDateTitleLabel.font = OpenSans.bold.of(textStyle: .footnote)
            lastPaymentDateTitleLabel.textColor = .blackText
            lastPaymentDateTitleLabel.text = NSLocalizedString("Last Payment Date", comment: "")
            lastPaymentDateLabel.textColor = .blackText
            
            payoffBalanceTitleLabel.font = OpenSans.bold.of(textStyle: .footnote)
            payoffBalanceTitleLabel.textColor = .blackText
            payoffBalanceTitleLabel.text = NSLocalizedString("Payoff Balance for BGE Service", comment: "")
            payoffBalanceLabel.textColor = .blackText
            payoffBalanceDescriptionLabel.font = SystemFont.regular.of(textStyle: .footnote)
            payoffBalanceDescriptionLabel.textColor = .deepGray
            payoffBalanceDescriptionLabel.text = NSLocalizedString("Total actual-usage charges for BGE gas and/or electric service after payments and adjustments.", comment: "")
            
            currentBalanceTitleLabel.font = OpenSans.bold.of(textStyle: .footnote)
            currentBalanceTitleLabel.textColor = .blackText
            currentBalanceTitleLabel.text = NSLocalizedString("Current Balance for BGE Service", comment: "")
            currentBalanceLabel.textColor = .blackText
            currentBalanceDescriptionLabel.font = SystemFont.regular.of(textStyle: .footnote)
            currentBalanceDescriptionLabel.textColor = .deepGray
            currentBalanceDescriptionLabel.text = NSLocalizedString("Total billed charges for BGE gas and/or electric service after payments and adjustments.", comment: "")
            
            accDifferenceTitleLabel.font = OpenSans.bold.of(textStyle: .footnote)
            accDifferenceTitleLabel.textColor = .blackText
            accDifferenceTitleLabel.text = NSLocalizedString("Accumulated Difference for BGE Service", comment: "")
            accDifferenceLabel.textColor = .blackText
            accDifferenceDescriptionLabel.font = SystemFont.regular.of(textStyle: .footnote)
            accDifferenceDescriptionLabel.textColor = .deepGray
            accDifferenceDescriptionLabel.text = NSLocalizedString("The difference between your Payoff Balance and your Current Balance for BGE Service.", comment: "")
        }

        footerView.backgroundColor = .softGray
        bgeFooterView.backgroundColor = .softGray
        footerLabel.textColor = .deepGray
        footerLabel.font = OpenSans.regular.of(textStyle: .footnote)
        
        errorLabel.textColor = .deepGray
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        
        unenrollButtonLabel.textColor = .deepGray
        unenrollButtonLabel.font = SystemFont.regular.of(textStyle: .callout)
        unenrollButtonLabel.text = NSLocalizedString("Looking to end Budget Billing?", comment: "")
        unenrollButton.setTitleColor(.actionBlue, for: .normal)
        unenrollButton.titleLabel?.font = SystemFont.bold.of(textStyle: .callout)
        unenrollButton.setTitle(NSLocalizedString("Unenroll", comment: ""), for: .normal)
        
        if accountDetail.isBudgetBillEnrollment {
            yourPaymentWouldBeLabel.isHidden = true
            paymentAmountView.isHidden = true
            amountDescriptionLabel.text = NSLocalizedString("You are currently enrolled in Budget Billing. Your monthly budget billing payment is adjusted periodically based on your actual usage.", comment: "")
            enrollButton.isHidden = true
        } else {
            unenrollView.isHidden = true
        }
        
        scrollView.isHidden = true
        loadingIndicator.isHidden = false
        bgeFooterView.isHidden = true
        stickyFooterView.isHidden = true
        viewModel.getBudgetBillingInfo(onSuccess: { [weak self] (budgetBillingInfo: BudgetBillingInfo) in
            guard let self = self else { return }
            
            if let footerText = self.viewModel.footerText {
                self.footerLabel.text = footerText
                self.view.backgroundColor = .softGray
            } else {
                self.footerView.isHidden = true
            }
            
            self.paymentAmountLabel.text = budgetBillingInfo.averageMonthlyBill
            self.scrollView.isHidden = false
            self.loadingIndicator.isHidden = true
            self.stickyFooterView.isHidden = false
            
            if Environment.shared.opco == .bge && self.accountDetail.isBudgetBillEnrollment {
                self.monthlyAmountLabel.text = budgetBillingInfo.budgetBill ?? budgetBillingInfo.averageMonthlyBill
                self.lastPaymentDateLabel.text = self.accountDetail.billingInfo.lastPaymentDate?.mmDdYyyyString
                self.payoffBalanceLabel.text = budgetBillingInfo.budgetBillPayoff
                self.currentBalanceLabel.text = budgetBillingInfo.budgetBillBalance
                self.accDifferenceLabel.text = budgetBillingInfo.budgetBillDifference
                self.bgeFooterView.isHidden = false
                
                if let budgetBillDifference = budgetBillingInfo.budgetBillDifference {
                    if budgetBillingInfo.budgetBillDifferenceDecimal < 0 {
                        self.bgeDynamicUnenrollMessage = String(format: NSLocalizedString("You are responsible for the full budget bill amount shown on your current bill. Your new billing amount will reflect your actual usage. This will include a credit of %@ beginning with your next bill.", comment: ""), budgetBillDifference)
                    } else if budgetBillingInfo.budgetBillDifferenceDecimal > 0 {
                        self.bgeDynamicUnenrollMessage = String(format: NSLocalizedString("You are responsible for the full budget bill amount shown on your current bill. Your new billing amount will reflect your actual usage. This will include a debit of %@ beginning with your next bill.", comment: ""), budgetBillDifference)
                    } else {
                        self.bgeDynamicUnenrollMessage = NSLocalizedString("You are responsible for the full budget bill amount shown on your current bill. Your new billing amount will reflect your actual usage.", comment: "")
                    }
                }
                
                if budgetBillingInfo.isUSPPParticipant {
                    // USPP Participants cannot unenroll
                    self.stickyFooterView.isHidden = true
                }
            }
        }, onError: { [weak self] errMessage in
            guard let self = self else { return }
            self.scrollView.isHidden = true
            self.loadingIndicator.isHidden = true
            self.errorLabel.isHidden = false
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @objc func onTooltipPress() {
        performSegue(withIdentifier: "whatIsBudgetBillingSegue", sender: self)
    }
    
    @IBAction func onEnrollPress() {
        LoadingView.show()
        GoogleAnalytics.log(event: .budgetBillEnrollOffer)
        viewModel.enroll(onSuccess: { [weak self] in
            LoadingView.hide()
            guard let self = self else { return }
            self.delegate?.budgetBillingViewControllerDidEnroll(self, averageMonthlyBill: self.viewModel.averageMonthlyBill)
            self.navigationController?.popViewController(animated: true)
        }, onError: { [weak self] errMessage in
            LoadingView.hide()
            let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self?.present(alertVc, animated: true, completion: nil)
        })
    }
    
    @IBAction func onUnenrollPress() {
        if Environment.shared.opco == .bge {
            GoogleAnalytics.log(event: .budgetBillUnEnrollOffer)
            let message = bgeDynamicUnenrollMessage ?? ""
            let alertVc = UIAlertController(title: NSLocalizedString("Unenroll from Budget Billing", comment: ""), message: message, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { _ in
                GoogleAnalytics.log(event: .budgetBillUnEnrollCancel) }))
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Unenroll", comment: ""), style: .destructive, handler: { [weak self] _ in
                LoadingView.show()
                GoogleAnalytics.log(event: .budgetBillUnEnrollOK)
                
                guard let self = self else { return }
                self.viewModel.unenroll(onSuccess: { [weak self] in
                    LoadingView.hide()
                    guard let self = self else { return }
                    self.delegate?.budgetBillingViewControllerDidUnenroll(self)
                    self.navigationController?.popViewController(animated: true)
                }, onError: { [weak self] errMessage in
                    LoadingView.hide()
                    guard let self = self else { return }
                    let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self.present(alertVc, animated: true, completion: nil)
                })
            }))
            present(alertVc, animated: true, completion: nil)
        } else {
            performSegue(withIdentifier: "reasonForStoppingSegue", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? LargeTitleNavigationController,
            let vc = navController.viewControllers.first as? BudgetBillingReasonForStoppingViewController {
            vc.viewModel = viewModel
            vc.budgetBillingViewController = self
            vc.delegate = delegate
        }
    }
    
//    // Prevents status bar color flash when pushed
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .lightContent
//    }

}

extension BudgetBillingViewController: UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension BudgetBillingViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReasonForStoppingCell", for: indexPath) as! RadioSelectionTableViewCell
        
        cell.label.text = viewModel.reasonString(forIndex: indexPath.row)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectedUnenrollmentReason.value = indexPath.row
    }
    
}
