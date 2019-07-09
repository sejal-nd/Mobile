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
    func budgetBillingViewControllerDidEnroll(_ budgetBillingViewController: BudgetBillingViewController, averageMonthlyBill: String?)
    func budgetBillingViewControllerDidUnenroll(_ budgetBillingViewController: BudgetBillingViewController)
}

class BudgetBillingViewController: UIViewController {
    
    weak var delegate: BudgetBillingViewControllerDelegate?
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var learnMoreAboutBudgetBillingButton: ButtonControl!
    @IBOutlet weak var learnMoreAboutBudgetBillingLabel: UILabel!
    @IBOutlet weak var yourPaymentWouldBeLabel: UILabel!
    @IBOutlet weak var paymentAmountView: UIView!
    @IBOutlet weak var paymentAmountLabel: UILabel!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var amountDescriptionLabel: UILabel!
    
    @IBOutlet weak var enrollmentLabel: UILabel!
    @IBOutlet weak var enrollSwitch: Switch!
    
    @IBOutlet weak var accountInfo: UIView!
    
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerLabel: UILabel!
    
    @IBOutlet weak var reasonForStoppingContainer: UIView!
    @IBOutlet weak var reasonForStoppingTableView: IntrinsicHeightTableView!
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
    
    var accountDetail: AccountDetail!
    var viewModel: BudgetBillingViewModel!
    
    var bgeDynamicUnenrollMessage: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = BudgetBillingViewModel(accountDetail: accountDetail, billService: ServiceFactory.createBillService(), alertsService: ServiceFactory.createAlertsService())
        
        title = NSLocalizedString("Budget Billing", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress(submitButton:)))
        navigationItem.leftBarButtonItem = cancelButton
        // Submit button will be added after successful load
        viewModel.submitButtonEnabled().bind(to: submitButton.rx.isEnabled).disposed(by: disposeBag)
        
        gradientLayer = CAGradientLayer()
        gradientLayer.frame = gradientView.bounds
        gradientLayer.colors = [
            UIColor.softGray.cgColor,
            UIColor.white.cgColor,
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientView.layer.addSublayer(gradientLayer)

        learnMoreAboutBudgetBillingButton.rx.touchUpInside.asDriver().drive(onNext: { [weak self] in
            self?.performSegue(withIdentifier: "whatIsBudgetBillingSegue", sender: self)
        }).disposed(by: disposeBag)
        learnMoreAboutBudgetBillingButton.accessibilityLabel = NSLocalizedString("Learn more about budget billing", comment: "")
        
        learnMoreAboutBudgetBillingLabel.textColor = .actionBlue
        learnMoreAboutBudgetBillingLabel.text = NSLocalizedString("Learn more about Budget Billing", comment: "")
        learnMoreAboutBudgetBillingLabel.font = SystemFont.semibold.of(textStyle: .headline)
        
        yourPaymentWouldBeLabel.font = SystemFont.medium.of(textStyle: .footnote)
        yourPaymentWouldBeLabel.textColor = .deepGray
        yourPaymentWouldBeLabel.text = NSLocalizedString("Your payment would be:", comment: "")
        paymentAmountLabel.textColor = .deepGray
        monthLabel.textColor = .deepGray
        monthLabel.text = NSLocalizedString("/Month", comment: "")
        
        amountDescriptionLabel.font = SystemFont.regular.of(textStyle: .footnote)
        amountDescriptionLabel.textColor = .deepGray
        if accountDetail.isBudgetBillEnrollment {
            yourPaymentWouldBeLabel.isHidden = true
            paymentAmountView.isHidden = true
            amountDescriptionLabel.text = NSLocalizedString("You are currently enrolled in Budget Billing. Your monthly budget billing payment is adjusted periodically based on your actual usage.", comment: "")
        } else {
            amountDescriptionLabel.text = viewModel.amountDescriptionText
        }
        
        enrollmentLabel.textColor = .blackText
        enrollmentLabel.font = OpenSans.regular.of(textStyle: .headline)
        enrollmentLabel.text = NSLocalizedString("Budget Billing Enrollment Status", comment: "")
        enrollmentLabel.isAccessibilityElement = false
        
        viewModel.currentEnrollment.asDriver().drive(enrollSwitch.rx.isOn).disposed(by: disposeBag)
        enrollSwitch.rx.isOn.bind(to: viewModel.currentEnrollment).disposed(by: disposeBag)
        enrollSwitch.accessibilityLabel = enrollmentLabel.text
        
        reasonForStoppingLabel.textColor = .blackText
        reasonForStoppingLabel.font = SystemFont.bold.of(textStyle: .subheadline)
        reasonForStoppingLabel.text = NSLocalizedString("Reason for stopping (select one)", comment: "")
        reasonForStoppingTableView.register(UINib(nibName: "RadioSelectionTableViewCell", bundle: nil), forCellReuseIdentifier: "ReasonForStoppingCell")
        reasonForStoppingTableView.estimatedRowHeight = 51
        reasonForStoppingContainer.isHidden = true
        if Environment.shared.opco == .comEd || Environment.shared.opco == .peco {
            viewModel.unenrolling.asDriver().drive(onNext: { [weak self] unenrolling in
                UIView.animate(withDuration: 0.3, animations: {
                    self?.reasonForStoppingContainer.isHidden = !unenrolling
                })
            }).disposed(by: disposeBag)
        }

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
        footerLabel.textColor = .blackText
        footerLabel.font = OpenSans.regular.of(textStyle: .footnote)
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        
        scrollView.isHidden = true
        loadingIndicator.isHidden = false
        bgeFooterView.isHidden = true
        gradientView.isHidden = true
        viewModel.getBudgetBillingInfo(onSuccess: { [weak self] (budgetBillingInfo: BudgetBillingInfo) in
            guard let self = self else { return }
            
            if let footerText = self.viewModel.footerText {
                self.footerLabel.text = footerText
                self.view.backgroundColor = .softGray
            } else {
                self.footerView.isHidden = true
            }
            
            self.navigationItem.rightBarButtonItem = submitButton
            self.paymentAmountLabel.text = budgetBillingInfo.averageMonthlyBill
            self.scrollView.isHidden = false
            self.loadingIndicator.isHidden = true
            self.gradientView.isHidden = false
            
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
                    self.navigationItem.rightBarButtonItem = nil
                    self.enrollSwitch.isHidden = true // USPP Participants cannot unenroll
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradientLayer.frame = gradientView.frame
        
        // Dynamic sizing for the table header view
        if let headerView = reasonForStoppingTableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            var headerFrame = headerView.frame
            
            // If we don't have this check, viewDidLayoutSubviews() will get called repeatedly, causing the app to hang.
            if height != headerFrame.size.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                reasonForStoppingTableView.tableHeaderView = headerView
            }
        }
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        gradientLayer.frame = gradientView.frame
    }
        
    @objc func onCancelPress() {
        if viewModel.enrolling.value || viewModel.unenrolling.value {
            let message = viewModel.enrolling.value ? NSLocalizedString("Are you sure you want to exit this screen without completing enrollment?", comment: "") : NSLocalizedString("Are you sure you want to exit this screen without completing unenrollment?", comment: "")
            let alertVc = UIAlertController(title: NSLocalizedString("Exit Budget Billing", comment: ""), message: message, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Exit", comment: ""), style: .default, handler: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }))
            present(alertVc, animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func onSubmitPress(submitButton: UIBarButtonItem) {
        guard submitButton.isEnabled else { return }
        
        if viewModel.enrolling.value {
            LoadingView.show()
            Analytics.log(event: .budgetBillEnrollOffer)
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

        } else if viewModel.unenrolling.value {
            Analytics.log(event: .budgetBillUnEnrollOffer)
            var message = ""
            if Environment.shared.opco == .comEd || Environment.shared.opco == .peco {
                message = NSLocalizedString("You will see your regular bill amount on your next billing cycle. Any credit balance remaining in your account will be applied to your bill until used, and any negative account balance will become due with your next bill.", comment: "")
            } else { // BGE
                message = bgeDynamicUnenrollMessage ?? ""
            }
            let alertVc = UIAlertController(title: NSLocalizedString("Unenroll from Budget Billing", comment: ""), message: message, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { _ in
                Analytics.log(event: .budgetBillUnEnrollCancel) }))
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Unenroll", comment: ""), style: .destructive, handler: { [weak self] _ in
                LoadingView.show()
                Analytics.log(event: .budgetBillUnEnrollOK)
                
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
        }
    }
    
    // Prevents status bar color flash when pushed
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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
