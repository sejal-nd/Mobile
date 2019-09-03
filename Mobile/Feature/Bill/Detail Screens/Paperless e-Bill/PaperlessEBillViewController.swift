//
//  PaperlessEBillViewController.swift
//  Mobile
//
//  Created by Sam Francis on 4/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol PaperlessEBillViewControllerDelegate: class {
    func paperlessEBillViewController(_ paperlessEBillViewController: PaperlessEBillViewController, didChangeStatus: PaperlessEBillChangedStatus)
}

class PaperlessEBillViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var accountInfoBar: AccountInfoBarNew!
    
    @IBOutlet weak var emailContainer: UIView!
    @IBOutlet weak var emailBox: UIView!
    @IBOutlet weak var emailsWillBeSentToLabel: UILabel!
    @IBOutlet weak var emailDivider: UIView!
	@IBOutlet weak var emailLabel: UILabel!
    
    @IBOutlet weak var singleAccountCurrentlyEnrolledContainer: UIView!
    @IBOutlet weak var singleAccountCurrentlyEnrolledLabel: UILabel!
    
    @IBOutlet weak var enrollAllAccountsView: UIView!
    @IBOutlet weak var allAccountsLabel: UILabel!
    @IBOutlet weak var enrollAllAccountsCheckbox: Checkbox!
    @IBOutlet weak var allAccountsSeparatorView: UIView!
    @IBOutlet weak var accountsStackView: UIStackView!
    @IBOutlet weak var detailsLoadingActivityView: UIView!
    
    @IBOutlet weak var footerContainer: UIView!
    @IBOutlet weak var footerLabel: UILabel!
    
    @IBOutlet weak var enrollmentButton: PrimaryButton!
    @IBOutlet weak var unenrollView: UIView!
    @IBOutlet weak var unenrollButtonLabel: UILabel!
    @IBOutlet weak var unenrollButton: UIButton!
    
    var accountDetail: AccountDetail!
    
    lazy var viewModel: PaperlessEBillViewModel = {
        PaperlessEBillViewModel(accountService: ServiceFactory.createAccountService(),
                                billService: ServiceFactory.createBillService(),
                                initialAccountDetail: self.accountDetail)
    }()
    
    weak var delegate: PaperlessEBillViewControllerDelegate?
    
    let bag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let systemBack = UINavigationBackButton()
        systemBack.isLabelHidden = true
        systemBack.addTarget(self, action: #selector(onBackPress), for: .touchUpInside)
        let backButton = UIBarButtonItem(customView: systemBack)
        backButton.isAccessibilityElement = true
        backButton.accessibilityLabel = NSLocalizedString("Back", comment: "")
        navigationItem.leftBarButtonItem = backButton
        navigationController?.interactivePopGestureRecognizer?.delegate = self // Enable interactive pop
        
        let infoButton = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_tooltip.pdf"), style: .plain, target: self, action: #selector(onTooltipPress))
        infoButton.isAccessibilityElement = true
        infoButton.accessibilityLabel = NSLocalizedString("Tooltip", comment: "")
        navigationItem.rightBarButtonItem = infoButton
        
        emailBox.layer.borderColor = UIColor.accentGray.cgColor
        emailBox.layer.borderWidth = 1
        emailDivider.backgroundColor = .accentGray
        emailsWillBeSentToLabel.textColor = .deepGray
        emailsWillBeSentToLabel.font = SystemFont.semibold.of(textStyle: .footnote)
        emailsWillBeSentToLabel.text = NSLocalizedString("Emails will be sent to", comment: "")
        emailLabel.textColor = .deepGray
        emailLabel.text = viewModel.initialAccountDetail.value.customerInfo.emailAddress
        emailLabel.font = SystemFont.regular.of(textStyle: .callout)
        
        singleAccountCurrentlyEnrolledLabel.textColor = .deepGray
        singleAccountCurrentlyEnrolledLabel.font = SystemFont.regular.of(textStyle: .body)
        singleAccountCurrentlyEnrolledLabel.text = NSLocalizedString("You are currently enrolled in Paperless eBill.", comment: "")
        
        allAccountsLabel.textColor = .deepGray
        allAccountsLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        allAccountsLabel.text = NSLocalizedString("All Eligible Accounts", comment: "")
        
        footerLabel.font = SystemFont.regular.of(textStyle: .caption1)
        footerLabel.text = viewModel.footerText
        footerContainer.isHidden = viewModel.footerText == nil
        
        unenrollButtonLabel.textColor = .deepGray
        unenrollButtonLabel.font = SystemFont.regular.of(textStyle: .callout)
        unenrollButtonLabel.text = NSLocalizedString("Looking to end Paperless eBill?", comment: "")
        unenrollButton.accessibilityLabel = "Looking to end Paperless e-bill?"
        unenrollButton.setTitleColor(.actionBlue, for: .normal)
        unenrollButton.titleLabel?.font = SystemFont.bold.of(textStyle: .callout)
        unenrollButton.setTitle(NSLocalizedString("Unenroll", comment: ""), for: .normal)
        
        self.enrollAllAccountsCheckbox.isEnabled = false
        viewModel.accountDetails
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] accountDetails -> () in
                guard let self = self else { return }
                self.enrollAllAccountsCheckbox.isEnabled = true
                self.detailsLoadingActivityView.isHidden = true
                UIAccessibility.post(notification: .screenChanged, argument: self.view)
                if self.viewModel.accounts.value.count > 1 {
                    accountDetails.forEach {
                        self.add(accountDetail: $0, animated: true)
                    }
                }
            })
            .disposed(by: bag)
        
        viewModel.allAccountsCheckboxState.distinctUntilChanged()
            .asDriver(onErrorJustReturn: .unchecked)
            .drive(onNext: { [weak self] state in
                if state == .indeterminate {
                    self?.enrollAllAccountsCheckbox.setIndeterminate(true)
                } else {
                    self?.enrollAllAccountsCheckbox.isChecked = state == .checked ? true : false
                }
            })
            .disposed(by: bag)
        
        Driver.combineLatest(viewModel.accountsToEnroll.asDriver(), viewModel.accountsToUnenroll.asDriver()) { !$0.isEmpty || !$1.isEmpty }
            .drive(enrollmentButton.rx.isEnabled)
            .disposed(by: bag)
        
        if viewModel.accounts.value.count == 1 {
            if accountDetail.isEBillEnrollment {
                enrollmentButton.isHidden = true
            } else {
                singleAccountCurrentlyEnrolledContainer.isHidden = true
                unenrollView.isHidden = true
            }
            enrollAllAccountsView.isHidden = true
            accountsStackView.isHidden = true
        } else {
            singleAccountCurrentlyEnrolledContainer.isHidden = true
            accountInfoBar.isHidden = true
            
            let enrollmentButtonText = NSLocalizedString("Update Enrollment", comment: "")
            enrollmentButton.setTitle(enrollmentButtonText, for: .normal)
            enrollmentButton.accessibilityLabel = enrollmentButtonText
            unenrollView.isHidden = true
        }
        
        enrollAllAccountsCheckbox.accessibilityLabel = NSLocalizedString("Enrollment status: ", comment: "")
        
        FirebaseUtility.logEvent(.paperlessEBillStart)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func add(accountDetail: AccountDetail, animated: Bool) {
        let accountView = PaperlessEBillAccountView.create(withAccountDetail: accountDetail)
        
        accountView.isChecked?.asDriver()
            .drive(onNext: { [weak self] isChecked in
                self?.viewModel.switched(accountDetail: accountDetail, on: isChecked)
            })
            .disposed(by: accountView.bag)
        
        enrollAllAccountsCheckbox.rx.isChecked.asDriver().skip(1)
            .drive(onNext: {
                accountView.toggleCheckbox(checked: $0)
            })
            .disposed(by: accountView.bag)
        
        accountsStackView.addArrangedSubview(accountView)
    }
    
    @IBAction func onTooltipPress() {
        FirebaseUtility.logEvent(.autoPay, parameters: [EventParameter(parameterName: .action, value: .learn_more)])
        
        let description: String
        if Environment.shared.opco == .bge {
            description = NSLocalizedString("Eliminate your paper bill.  Your online bill is identical to your current paper bill and is available to view, download, or print at any time.  You will receive bill ready email notifications regardless of preference.  Your preference will be updated with your next month’s bill.", comment: "")
        } else {
            description = NSLocalizedString("Eliminate your paper bill and receive an email notification when your bill is ready to view online.  Your online bill is identical to your current paper bill and is available to view, download, or print at any time.  Your preference will be updated with your next month’s bill.", comment: "")
        }
        let infoModal = InfoModalViewController(title: NSLocalizedString("Paperless eBill", comment: ""), image: #imageLiteral(resourceName: "paperless_modal"), description: description)
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
    
    @objc func onBackPress() {
        if viewModel.enrollStatesChanged.value {
            let message = !viewModel.accountsToEnroll.value.isEmpty ? NSLocalizedString("Are you sure you want to exit this screen without completing enrollment?", comment: "") : NSLocalizedString("Are you sure you want to exit this screen without completing unenrollment?", comment: "")
            let alertVc = UIAlertController(title: NSLocalizedString("Exit Paperless eBill", comment: ""), message: message, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Exit", comment: ""), style: .default, handler: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }))
            present(alertVc, animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @IBAction func onEnrollmentButtonPress() {
        
        FirebaseUtility.logEvent(.paperlessEBillSubmit)
        
        LoadingView.show()
        viewModel.submitChanges(onSuccess: { [weak self] changedStatus in
            LoadingView.hide()
            guard let self = self else { return }
            
            FirebaseUtility.logEvent(.paperlessEBillNetworkComplete)
            
            FirebaseUtility.logEvent(.autoPay, parameters: [EventParameter(parameterName: .action, value: .enroll_complete)])
            
            self.delegate?.paperlessEBillViewController(self, didChangeStatus: changedStatus)
            self.navigationController?.popViewController(animated: true)
        }, onError: { [weak self] errMessage in
            
            FirebaseUtility.logEvent(.autoPay, parameters: [EventParameter(parameterName: .action, value: .network_submit_error)])
            
            LoadingView.hide()
            let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self?.present(alertVc, animated: true, completion: nil)
        })
    }

}
