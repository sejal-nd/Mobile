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
        
        footerLabel.font = SystemFont.regular.of(textStyle: .footnote)
        footerLabel.textColor = .deepGray
        footerLabel.text = viewModel.footerLabelText

        // When BGE user is enrolled they get a series of card views with information
        if Environment.shared.opco == .bge && accountDetail.isBudgetBillEnrollment {
            for card in bgeEnrolledInfoCardViews {
                card.layer.borderColor = UIColor.accentGray.cgColor
                card.layer.borderWidth = 1
            }
            for divider in bgeEnrolledInfoCardDividers {
                divider.backgroundColor = .accentGray
            }
            
            monthlyAmountTitleLabel.font = SystemFont.semibold.of(textStyle: .footnote)
            monthlyAmountTitleLabel.textColor = .deepGray
            monthlyAmountTitleLabel.text = NSLocalizedString("Monthly Budget Bill Amount", comment: "")
            monthlyAmountLabel.font = OpenSans.semibold.of(textStyle: .title3)
            monthlyAmountLabel.textColor = .deepGray
            monthlyAmountDescriptionLabel.font = SystemFont.regular.of(textStyle: .caption1)
            monthlyAmountDescriptionLabel.textColor = .deepGray
            monthlyAmountDescriptionLabel.text = NSLocalizedString("The amount that you are billed for BGE gas and/or electric service each month. This charge appears on the first page of your bill under Charges/Adjustments this period.", comment: "")
            
            lastPaymentDateTitleLabel.font = SystemFont.semibold.of(textStyle: .footnote)
            lastPaymentDateTitleLabel.textColor = .deepGray
            lastPaymentDateTitleLabel.text = NSLocalizedString("Last Payment Date", comment: "")
            lastPaymentDateLabel.font = OpenSans.semibold.of(textStyle: .title3)
            lastPaymentDateLabel.textColor = .deepGray
            
            payoffBalanceTitleLabel.font = SystemFont.semibold.of(textStyle: .footnote)
            payoffBalanceTitleLabel.textColor = .deepGray
            payoffBalanceTitleLabel.text = NSLocalizedString("Payoff Balance for BGE Service", comment: "")
            payoffBalanceLabel.font = OpenSans.semibold.of(textStyle: .title3)
            payoffBalanceLabel.textColor = .deepGray
            payoffBalanceDescriptionLabel.font = SystemFont.regular.of(textStyle: .caption1)
            payoffBalanceDescriptionLabel.textColor = .deepGray
            payoffBalanceDescriptionLabel.text = NSLocalizedString("Total actual-usage charges for BGE gas and/or electric service after payments and adjustments.", comment: "")
            
            currentBalanceTitleLabel.font = SystemFont.semibold.of(textStyle: .footnote)
            currentBalanceTitleLabel.textColor = .deepGray
            currentBalanceTitleLabel.text = NSLocalizedString("Current Balance for BGE Service", comment: "")
            currentBalanceLabel.font = OpenSans.semibold.of(textStyle: .title3)
            currentBalanceLabel.textColor = .deepGray
            currentBalanceDescriptionLabel.font = SystemFont.regular.of(textStyle: .caption1)
            currentBalanceDescriptionLabel.textColor = .deepGray
            currentBalanceDescriptionLabel.text = NSLocalizedString("Total billed charges for BGE gas and/or electric service after payments and adjustments.", comment: "")
            
            accDifferenceTitleLabel.font = SystemFont.semibold.of(textStyle: .footnote)
            accDifferenceTitleLabel.textColor = .deepGray
            accDifferenceTitleLabel.text = NSLocalizedString("Accumulated Difference for BGE Service", comment: "")
            accDifferenceLabel.font = OpenSans.semibold.of(textStyle: .title3)
            accDifferenceLabel.textColor = .deepGray
            accDifferenceDescriptionLabel.font = SystemFont.regular.of(textStyle: .caption1)
            accDifferenceDescriptionLabel.textColor = .deepGray
            accDifferenceDescriptionLabel.text = NSLocalizedString("The difference between your Payoff Balance and your Current Balance for BGE Service.", comment: "")
        }
        
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
            footerContainerView.isHidden = true
            enrollButton.isHidden = true
        } else {
            unenrollView.isHidden = true
        }
        
        scrollView.isHidden = true
        loadingIndicator.isHidden = false
        bgeEnrolledInfoContainerView.isHidden = true
        stickyFooterView.isHidden = true
        viewModel.getBudgetBillingInfo(onSuccess: { [weak self] (budgetBillingInfo: BudgetBillingInfo) in
            guard let self = self else { return }
            
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
                self.bgeEnrolledInfoContainerView.isHidden = false
                
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
        
        FirebaseUtility.logEvent(.budgetBillingStart)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @objc func onTooltipPress() {
        FirebaseUtility.logEvent(.autoPay, parameters: [EventParameter(parameterName: .action, value: .learn_more)])
        
        performSegue(withIdentifier: "whatIsBudgetBillingSegue", sender: self)
    }
    
    @IBAction func onEnrollPress() {
        LoadingView.show()
        GoogleAnalytics.log(event: .budgetBillEnrollOffer)
        
        FirebaseUtility.logEvent(.budgetBillingSubmit)
        
        viewModel.enroll(onSuccess: { [weak self] in
            LoadingView.hide()
            guard let self = self else { return }
            
            FirebaseUtility.logEvent(.autoPay, parameters: [EventParameter(parameterName: .action, value: .enroll_complete)])
            
            FirebaseUtility.logEvent(.budgetBillingNetworkComplete)
            
            self.delegate?.budgetBillingViewControllerDidEnroll(self, averageMonthlyBill: self.viewModel.averageMonthlyBill)
            self.navigationController?.popViewController(animated: true)
        }, onError: { [weak self] errMessage in
            LoadingView.hide()
            
            FirebaseUtility.logEvent(.autoPay, parameters: [EventParameter(parameterName: .action, value: .network_submit_error)])
            
            let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self?.present(alertVc, animated: true, completion: nil)
        })
    }
    
    @IBAction func onUnenrollPress() {
        if Environment.shared.opco == .bge {
            GoogleAnalytics.log(event: .budgetBillUnEnrollOffer)
            
            FirebaseUtility.logEvent(.budgetBillingSubmit)
            
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
                    
                    FirebaseUtility.logEvent(.autoPay, parameters: [EventParameter(parameterName: .action, value: .unenroll_complete)])
                    
                    FirebaseUtility.logEvent(.budgetBillingNetworkComplete)
                    
                    self.delegate?.budgetBillingViewControllerDidUnenroll(self)
                    self.navigationController?.popViewController(animated: true)
                }, onError: { [weak self] errMessage in
                    LoadingView.hide()
                    guard let self = self else { return }
                    
                    FirebaseUtility.logEvent(.autoPay, parameters: [EventParameter(parameterName: .action, value: .network_submit_error)])
                    
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
        viewModel.selectedUnenrollmentReason.value = indexPath.row
    }
    
}
