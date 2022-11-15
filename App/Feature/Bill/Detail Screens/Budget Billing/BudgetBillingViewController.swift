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
    
    @IBOutlet weak var footerContainerView: StickyFooterView!
    @IBOutlet weak var footerLabel: UILabel!
        
    @IBOutlet weak var bgeEnrolledInfoContainerView: UIView!
    @IBOutlet var bgeEnrolledInfoCardViews: [UIView]!
    @IBOutlet var bgeEnrolledInfoCardDividers: [UIView]!
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
    
    @IBOutlet weak var stickyFooterView: StickyFooterView!
    @IBOutlet weak var enrollButton: PrimaryButton!
    @IBOutlet weak var unenrollView: UIView!
    @IBOutlet weak var unenrollButtonLabel: UILabel!
    @IBOutlet weak var unenrollButton: UIButton!
    
    var accountDetail: AccountDetail!
    var viewModel: BudgetBillingViewModel!
    
    var bgeDynamicUnenrollMessage: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = BudgetBillingViewModel(accountDetail: accountDetail)
        
        title = NSLocalizedString("Budget Billing", comment: "")
        
        let infoButton = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_tooltip.pdf"), style: .plain, target: self, action: #selector(onTooltipPress))
        navigationItem.rightBarButtonItem = infoButton
        infoButton.isAccessibilityElement = true
        infoButton.accessibilityLabel = NSLocalizedString("Tooltip", comment: "")
        
        descriptionHeaderLabel.textColor = .neutralDark
        descriptionHeaderLabel.font = SystemFont.regular.of(textStyle: .body)
        if accountDetail.isBudgetBill {
            descriptionHeaderLabel.text = Configuration.shared.opco.isPHI ? NSLocalizedString("You are currently enrolled in Budget Billing. Your monthly Budget Billing payment is adjusted periodically based on your actual usage.\n\nPlease refer to your full bill for additional details.", comment: "") : NSLocalizedString("You are currently enrolled in Budget Billing. Your monthly Budget Billing payment is adjusted periodically based on your actual usage.", comment: "")
        } else {
            descriptionHeaderLabel.text = Configuration.shared.opco.isPHI ? NSLocalizedString("If you prefer a consistent and predictable monthly payment throughout the year that eliminates monthly or seasonal variation, Budget Billing spreads costs evenly month to month by charging a pre-arranged amount with each bill.", comment: "") :  NSLocalizedString("Budget Billing spreads out your utility payments evenly throughout the year, so you will know what to expect each month.", comment: "")
        }
        descriptionHeaderLabel.setLineHeight(lineHeight: 24)
        
        paymentAmountView.layer.borderColor = UIColor.accentGray.cgColor
        paymentAmountView.layer.borderWidth = 1

        yourPaymentWouldBeLabel.font = ExelonFont.semibold.of(textStyle: .footnote)
        yourPaymentWouldBeLabel.textColor = .neutralDark
        yourPaymentWouldBeLabel.text = NSLocalizedString("Your monthly payment would be", comment: "")
        paymentAmountLabel.textColor = .neutralDark
        paymentAmountLabel.font = ExelonFont.semibold.of(textStyle: .title1)
        
        footerLabel.font = SystemFont.regular.of(textStyle: .footnote)
        footerLabel.textColor = .neutralDark
        footerLabel.text = viewModel.footerLabelText

        // When BGE user is enrolled they get a series of card views with information
        if Configuration.shared.opco == .bge && accountDetail.isBudgetBill {
            for card in bgeEnrolledInfoCardViews {
                card.layer.borderColor = UIColor.accentGray.cgColor
                card.layer.borderWidth = 1
            }
            for divider in bgeEnrolledInfoCardDividers {
                divider.backgroundColor = .accentGray
            }
            
            monthlyAmountTitleLabel.font = SystemFont.semibold.of(textStyle: .footnote)
            monthlyAmountTitleLabel.textColor = .neutralDark
            monthlyAmountTitleLabel.text = NSLocalizedString("Monthly Budget Bill Amount", comment: "")
            monthlyAmountLabel.font = ExelonFont.semibold.of(textStyle: .title3)
            monthlyAmountLabel.textColor = .neutralDark
            monthlyAmountDescriptionLabel.font = SystemFont.regular.of(textStyle: .caption1)
            monthlyAmountDescriptionLabel.textColor = .neutralDark
            monthlyAmountDescriptionLabel.text = NSLocalizedString("The amount that you are billed for BGE gas and/or electric service each month. This charge appears on the first page of your bill under Charges/Adjustments this period.", comment: "")
            
            lastPaymentDateTitleLabel.font = SystemFont.semibold.of(textStyle: .footnote)
            lastPaymentDateTitleLabel.textColor = .neutralDark
            lastPaymentDateTitleLabel.text = NSLocalizedString("Last Payment Date", comment: "")
            lastPaymentDateLabel.font = ExelonFont.semibold.of(textStyle: .title3)
            lastPaymentDateLabel.textColor = .neutralDark
            
            payoffBalanceTitleLabel.font = SystemFont.semibold.of(textStyle: .footnote)
            payoffBalanceTitleLabel.textColor = .neutralDark
            payoffBalanceTitleLabel.text = NSLocalizedString("Payoff Balance for BGE Service", comment: "")
            payoffBalanceLabel.font = ExelonFont.semibold.of(textStyle: .title3)
            payoffBalanceLabel.textColor = .neutralDark
            payoffBalanceDescriptionLabel.font = SystemFont.regular.of(textStyle: .caption1)
            payoffBalanceDescriptionLabel.textColor = .neutralDark
            payoffBalanceDescriptionLabel.text = NSLocalizedString("Total actual-usage charges for BGE gas and/or electric service after payments and adjustments.", comment: "")
            
            currentBalanceTitleLabel.font = SystemFont.semibold.of(textStyle: .footnote)
            currentBalanceTitleLabel.textColor = .neutralDark
            currentBalanceTitleLabel.text = NSLocalizedString("Current Balance for BGE Service", comment: "")
            currentBalanceLabel.font = ExelonFont.semibold.of(textStyle: .title3)
            currentBalanceLabel.textColor = .neutralDark
            currentBalanceDescriptionLabel.font = SystemFont.regular.of(textStyle: .caption1)
            currentBalanceDescriptionLabel.textColor = .neutralDark
            currentBalanceDescriptionLabel.text = NSLocalizedString("Total billed charges for BGE gas and/or electric service after payments and adjustments.", comment: "")
            
            accDifferenceTitleLabel.font = SystemFont.semibold.of(textStyle: .footnote)
            accDifferenceTitleLabel.textColor = .neutralDark
            accDifferenceTitleLabel.text = NSLocalizedString("Accumulated Difference for BGE Service", comment: "")
            accDifferenceLabel.font = ExelonFont.semibold.of(textStyle: .title3)
            accDifferenceLabel.textColor = .neutralDark
            accDifferenceDescriptionLabel.font = SystemFont.regular.of(textStyle: .caption1)
            accDifferenceDescriptionLabel.textColor = .neutralDark
            accDifferenceDescriptionLabel.text = NSLocalizedString("The difference between your Payoff Balance and your Current Balance for BGE Service.", comment: "")
        }
        
        errorLabel.textColor = .neutralDark
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        
        unenrollButtonLabel.textColor = .neutralDark
        unenrollButtonLabel.font = SystemFont.regular.of(textStyle: .callout)
        unenrollButtonLabel.text = NSLocalizedString("Looking to end Budget Billing?", comment: "")
        unenrollButton.setTitleColor(.primaryBlue, for: .normal)
        unenrollButton.titleLabel?.font = SystemFont.bold.of(textStyle: .callout)
        unenrollButton.setTitle(NSLocalizedString("Unenroll", comment: ""), for: .normal)
        
        if accountDetail.isBudgetBill {
            yourPaymentWouldBeLabel.isHidden = true
            paymentAmountView.isHidden = true
            footerContainerView.isHidden = true
            enrollButton.isHidden = true
        } else {
            unenrollView.isHidden = true
        }
        
        scrollView.isHidden = true
        loadingIndicator.isHidden = false
        bgeEnrolledInfoContainerView.isHidden = true
        stickyFooterView.isHidden = true
        viewModel.getBudgetBillingInfo(onSuccess: { [weak self] (budgetBillingInfo: BudgetBilling) in
            guard let self = self else { return }
            
            self.paymentAmountLabel.text = budgetBillingInfo.averageMonthlyBill.currencyString
            self.scrollView.isHidden = false
            self.loadingIndicator.isHidden = true
            
            if Configuration.shared.opco == .comEd && self.viewModel.accountDetail.isPippEnrolled {
                self.stickyFooterView.isHidden = true
            } else {
                self.stickyFooterView.isHidden = false
            }
            
            if Configuration.shared.opco == .bge && self.accountDetail.isBudgetBill {
                self.monthlyAmountLabel.text = budgetBillingInfo.budgetBill?.currencyString ?? budgetBillingInfo.averageMonthlyBill.currencyString
                self.lastPaymentDateLabel.text = self.accountDetail.billingInfo.lastPaymentDate?.mmDdYyyyString
                self.payoffBalanceLabel.text = budgetBillingInfo.budgetBillPayoff?.currencyString
                self.currentBalanceLabel.text = budgetBillingInfo.budgetBillBalance?.currencyString
                self.accDifferenceLabel.text = budgetBillingInfo.budgetBillDifference?.currencyString
                self.bgeEnrolledInfoContainerView.isHidden = false
                
                let budgetBillDifference = budgetBillingInfo.budgetBillDifference ?? 0
                if budgetBillDifference < 0 {
                    self.bgeDynamicUnenrollMessage = String(format: NSLocalizedString("You are responsible for the full budget bill amount shown on your current bill. Your new billing amount will reflect your actual usage. This will include a credit of %f beginning with your next bill.", comment: ""), budgetBillDifference)
                } else if budgetBillDifference > 0 {
                    self.bgeDynamicUnenrollMessage = String(format: NSLocalizedString("You are responsible for the full budget bill amount shown on your current bill. Your new billing amount will reflect your actual usage. This will include a debit of %f beginning with your next bill.", comment: ""), budgetBillDifference)
                } else {
                    self.bgeDynamicUnenrollMessage = NSLocalizedString("You are responsible for the full budget bill amount shown on your current bill. Your new billing amount will reflect your actual usage.", comment: "")
                }
                
                UIAccessibility.post(notification: .screenChanged, argument: self.view)
            }
        }, onError: { [weak self] errMessage in
            guard let self = self else { return }
            self.scrollView.isHidden = true
            self.loadingIndicator.isHidden = true
            self.errorLabel.isHidden = false
        })
        
        FirebaseUtility.logEvent(.budgetBillingStart)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @objc func onTooltipPress() {
        FirebaseUtility.logEvent(.budgetBill(parameters: [.learn_more]))
        
        performSegue(withIdentifier: "whatIsBudgetBillingSegue", sender: self)
    }
    
    @IBAction func onEnrollPress() {
        LoadingView.show()
        GoogleAnalytics.log(event: .budgetBillEnrollOffer)
        
        FirebaseUtility.logEvent(.budgetBillingSubmit)
        FirebaseUtility.logEvent(.budgetBill(parameters: [.enroll_start]))
        
        viewModel.enroll(onSuccess: { [weak self] in
            LoadingView.hide()
            guard let self = self else { return }
            
            FirebaseUtility.logEvent(.budgetBill(parameters: [.enroll_complete]))
            
            FirebaseUtility.logEvent(.budgetBillingNetworkComplete)
            
            self.delegate?.budgetBillingViewControllerDidEnroll(self, averageMonthlyBill: self.viewModel.averageMonthlyBill)
            self.navigationController?.popViewController(animated: true)
        }, onError: { [weak self] errMessage in
            LoadingView.hide()
            
            FirebaseUtility.logEvent(.budgetBill(parameters: [.network_submit_error]))
            
            let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self?.present(alertVc, animated: true, completion: nil)
        })
    }
    
    @IBAction func onUnenrollPress() {
        if Configuration.shared.opco == .bge || Configuration.shared.opco.isPHI {
            GoogleAnalytics.log(event: .budgetBillUnEnrollOffer)
            
            FirebaseUtility.logEvent(.budgetBillingSubmit)
            
            let message = Configuration.shared.opco.isPHI ? "You are responsible for the full budget bill amount shown on your current bill. Your new billing amount will reflect your actual usage." : bgeDynamicUnenrollMessage ?? ""
            let alertVc = UIAlertController(title: NSLocalizedString("Unenroll from Budget Billing", comment: ""), message: message, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { _ in
                GoogleAnalytics.log(event: .budgetBillUnEnrollCancel) }))
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Unenroll", comment: ""), style: .destructive, handler: { [weak self] _ in
                LoadingView.show()
                GoogleAnalytics.log(event: .budgetBillUnEnrollOK)
                
                FirebaseUtility.logEvent(.budgetBill(parameters: [.unenroll_start]))
                guard let self = self else { return }
                self.viewModel.unenroll(onSuccess: { [weak self] in
                    LoadingView.hide()
                    guard let self = self else { return }
                    
                    FirebaseUtility.logEvent(.budgetBill(parameters: [.unenroll_complete]))
                    
                    FirebaseUtility.logEvent(.budgetBillingNetworkComplete)
                    
                    self.delegate?.budgetBillingViewControllerDidUnenroll(self)
                    self.navigationController?.popViewController(animated: true)
                }, onError: { [weak self] errMessage in
                    LoadingView.hide()
                    guard let self = self else { return }
                    
                    FirebaseUtility.logEvent(.budgetBill(parameters: [.network_submit_error]))
                    
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
        viewModel.selectedUnenrollmentReason.accept(indexPath.row)
    }
    
}
