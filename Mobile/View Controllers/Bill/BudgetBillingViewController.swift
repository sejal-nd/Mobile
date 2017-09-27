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
    func budgetBillingViewControllerDidEnroll(_ budgetBillingViewController: BudgetBillingViewController)
    func budgetBillingViewControllerDidUnenroll(_ budgetBillingViewController: BudgetBillingViewController)
}

class BudgetBillingViewController: UIViewController {
    
    weak var delegate: BudgetBillingViewControllerDelegate?
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var accountBackgroundView: UIView! // For stretching edge to edge on iPad
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var learnMoreAboutBudgetBillingButton: ButtonControl!
    @IBOutlet weak var learnMoreAboutBudgetBillingLabel: UILabel!
    @IBOutlet weak var yourPaymentWouldBeLabel: UILabel!
    @IBOutlet weak var paymentAmountView: UIView!
    @IBOutlet weak var paymentAmountLabel: UILabel!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var amountDescriptionLabel: UILabel!
    
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var enrollSwitch: Switch!
    @IBOutlet weak var accountIcon: UIImageView!
    
    @IBOutlet weak var accountInfo: UIView!
    
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerLabel: UILabel!
    
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
        
        viewModel = BudgetBillingViewModel(accountDetail: accountDetail, billService: ServiceFactory.createBillService())
        
        title = NSLocalizedString("Budget Billing", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress))
        navigationItem.leftBarButtonItem = cancelButton
        // Submit button will be added after successful load
        viewModel.submitButtonEnabled().bind(to: submitButton.rx.isEnabled).disposed(by: disposeBag)
        
        view.backgroundColor = .softGray
        
        gradientLayer = CAGradientLayer()
        gradientLayer.frame = gradientView.bounds
        gradientLayer.colors = [
            UIColor.softGray.cgColor,
            UIColor.white.cgColor,
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientView.layer.addSublayer(gradientLayer)

        learnMoreAboutBudgetBillingButton.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        learnMoreAboutBudgetBillingButton.layer.cornerRadius = 2
        learnMoreAboutBudgetBillingButton.backgroundColorOnPress = .softGray
        learnMoreAboutBudgetBillingButton.rx.touchUpInside.asDriver().drive(onNext: { [weak self] in
            self?.performSegue(withIdentifier: "whatIsBudgetBillingSegue", sender: self)
        }).disposed(by: disposeBag)
        learnMoreAboutBudgetBillingButton.accessibilityLabel = NSLocalizedString("Learn more about budget billing", comment: "")
        
        learnMoreAboutBudgetBillingLabel.textColor = .blackText
        let learnMoreString = NSLocalizedString("Learn more about ", comment: "")
        let budgetBillingString = NSLocalizedString("Budget Billing", comment: "")
        let learnMoreAboutBudgetBillingString = "\(learnMoreString)\n\(budgetBillingString)"
        let learnMoreAboutBudgetBillingAttrString = NSMutableAttributedString(string: learnMoreAboutBudgetBillingString, attributes: [NSForegroundColorAttributeName: UIColor.blackText])
        learnMoreAboutBudgetBillingAttrString.addAttribute(NSFontAttributeName, value: OpenSans.regular.of(size: 18), range: NSMakeRange(0, learnMoreString.characters.count))
        learnMoreAboutBudgetBillingAttrString.addAttribute(NSFontAttributeName, value: OpenSans.bold.of(size: 18), range: NSMakeRange(learnMoreString.characters.count + 1, budgetBillingString.characters.count))
        learnMoreAboutBudgetBillingLabel.attributedText = learnMoreAboutBudgetBillingAttrString
        
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
            amountDescriptionLabel.text = viewModel.getAmountDescriptionText()
        }
        
        accountNumberLabel.textColor = .blackText
        accountNumberLabel.text = AccountsStore.sharedInstance.currentAccount.accountNumber
        accountNumberLabel.font = SystemFont.medium.of(textStyle: .title1)
        addressLabel.textColor = .middleGray
        addressLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        addressLabel.text = AccountsStore.sharedInstance.currentAccount.address
        
        if accountDetail.isResidential {
            accountIcon.image = #imageLiteral(resourceName: "ic_residential")
            accountIcon.accessibilityLabel = NSLocalizedString("Residential Account", comment: "")
        } else {
            accountIcon.image = #imageLiteral(resourceName: "ic_commercial")
            accountIcon.accessibilityLabel = NSLocalizedString("Commercial Account", comment: "")
        }
                
        viewModel.currentEnrollment.asDriver().drive(enrollSwitch.rx.isOn).disposed(by: disposeBag)
        enrollSwitch.rx.isOn.bind(to: viewModel.currentEnrollment).disposed(by: disposeBag)
        
        reasonForStoppingLabel.textColor = .blackText
        reasonForStoppingLabel.font = SystemFont.bold.of(textStyle: .subheadline)
        reasonForStoppingLabel.text = NSLocalizedString("Reason for stopping (select one)", comment: "")
        reasonForStoppingTableView.register(UINib(nibName: "RadioSelectionTableViewCell", bundle: nil), forCellReuseIdentifier: "ReasonForStoppingCell")
        reasonForStoppingTableView.estimatedRowHeight = 51
        reasonForStoppingTableView.isHidden = true
        if Environment.sharedInstance.opco == .comEd || Environment.sharedInstance.opco == .peco {
            viewModel.unenrolling.asDriver().drive(onNext: { [weak self] unenrolling in
                UIView.animate(withDuration: 0.3, animations: {
                    self?.reasonForStoppingTableView.isHidden = !unenrolling
                })
            }).disposed(by: disposeBag)
        }
        let localizedText = NSLocalizedString("Account number: %@", comment: "")
        accountNumberLabel.accessibilityLabel = String(format: localizedText, accountNumberLabel.text ?? "")

        let localizedA11Y = NSLocalizedString("Street address: %@", comment: "")
        if let a11yAddress = addressLabel.text {
            addressLabel.accessibilityLabel = String(format: localizedA11Y, a11yAddress)
        } else {
            addressLabel.accessibilityLabel = nil
        }
        accountInfo.accessibilityElements = [accountIcon, accountNumberLabel, addressLabel, enrollSwitch]
        
        // BGE Footer View when user is enrolled
        if Environment.sharedInstance.opco == .bge && accountDetail.isBudgetBillEnrollment {
            for view in bgeFooterCardViews {
                view.layer.cornerRadius = 2
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

        footerLabel.textColor = .blackText
        if let footerText = viewModel.getFooterText() {
            footerLabel.text = footerText
        } else {
            footerView.isHidden = true
        }
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        
        scrollView.isHidden = true
        loadingIndicator.isHidden = false
        bgeFooterView.isHidden = true
        viewModel.getBudgetBillingInfo(onSuccess: { [weak self] (budgetBillingInfo: BudgetBillingInfo) in
            guard let `self` = self else { return }
            self.navigationItem.rightBarButtonItem = submitButton
            self.paymentAmountLabel.text = budgetBillingInfo.averageMonthlyBill
            self.scrollView.isHidden = false
            self.loadingIndicator.isHidden = true
            
            if Environment.sharedInstance.opco == .bge && self.accountDetail.isBudgetBillEnrollment {
                self.monthlyAmountLabel.text = budgetBillingInfo.averageMonthlyBill
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
                guard let `self` = self else { return }
                self.scrollView.isHidden = true
                self.loadingIndicator.isHidden = true
                self.errorLabel.isHidden = false
        })

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradientLayer.frame = gradientView.frame
        accountBackgroundView.addBottomBorder(color: .softGray, width: 0.5)
        
        // Dynamic sizing for the table header view
        if let headerView = reasonForStoppingTableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
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
        accountBackgroundView.addBottomBorder(color: .softGray, width: 0.5)
    }
        
    func onCancelPress() {
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
    
    func onSubmitPress() {
        if viewModel.enrolling.value {
            LoadingView.show()
            Analytics().logScreenView(AnalyticsPageView.BudgetBillUnEnrollOffer.rawValue)
            viewModel.enroll(onSuccess: { [weak self] in
                LoadingView.hide()
                Analytics().logScreenView(AnalyticsPageView.BudgetBillEnrollOffer.rawValue)
                
                guard let `self` = self else { return }
                self.delegate?.budgetBillingViewControllerDidEnroll(self)
                self.navigationController?.popViewController(animated: true)
            }, onError: { [weak self] errMessage in
                LoadingView.hide()
                let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alertVc, animated: true, completion: nil)
            })

        } else if viewModel.unenrolling.value {
            var message = ""
            if Environment.sharedInstance.opco == .comEd || Environment.sharedInstance.opco == .peco {
                message = NSLocalizedString("You will see your regular bill amount on your next billing cycle. Any credit balance remaining in your account will be applied to your bill until used, and any negative account balance will become due with your next bill.", comment: "")
            } else { // BGE
                message = bgeDynamicUnenrollMessage ?? ""
            }
            let alertVc = UIAlertController(title: NSLocalizedString("Unenroll from Budget Billing", comment: ""), message: message, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { _ in
                Analytics().logScreenView(AnalyticsPageView.BudgetBillUnEnrollCancel.rawValue);}))
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Unenroll", comment: ""), style: .destructive, handler: { [weak self] _ in
                LoadingView.show()
                
                guard let `self` = self else { return }
                self.viewModel.unenroll(onSuccess: { [weak self] in
                    LoadingView.hide()
                    
                    guard let `self` = self else { return }
                    self.delegate?.budgetBillingViewControllerDidUnenroll(self)
                    self.navigationController?.popViewController(animated: true)
                    Analytics().logScreenView(AnalyticsPageView.BudgetBillUnEnrollOK.rawValue)
                }, onError: { [weak self] errMessage in
                    LoadingView.hide()
                    
                    guard let `self` = self else { return }
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
        return UITableViewAutomaticDimension
    }
}

extension BudgetBillingViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReasonForStoppingCell", for: indexPath) as! RadioSelectionTableViewCell
        
        cell.label.text = viewModel.getReasonString(forIndex: indexPath.row)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectedUnenrollmentReason.value = indexPath.row
    }
    
}
