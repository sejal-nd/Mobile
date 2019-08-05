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
    
    @IBOutlet weak var singleAccountEnrollView: UIView!
    @IBOutlet weak var singleAccountEnrollLabel: UILabel!
    @IBOutlet weak var singleAccountEnrollSwitch: Switch!
    @IBOutlet weak var enrollAllAccountsHeaderView: UIView!
    @IBOutlet weak var enrollAllAccountsHeaderLabel: UILabel!
    @IBOutlet weak var enrollAllAccountsView: UIView!
    @IBOutlet weak var allAccountsLabel: UILabel!
    @IBOutlet weak var enrollAllAccountsSwitch: UISwitch!
    @IBOutlet weak var allAccountsSeparatorView: UIView!
    @IBOutlet weak var accountsStackView: UIStackView!
    @IBOutlet weak var detailsLoadingActivityView: UIView!
    @IBOutlet weak var footerContainer: StickyFooterView!
    @IBOutlet weak var footerLabel: UILabel!
    
    var initialAccountDetail: AccountDetail!
    
    lazy var viewModel: PaperlessEBillViewModel = {
        PaperlessEBillViewModel(accountService: ServiceFactory.createAccountService(),
                                billService: ServiceFactory.createBillService(),
                                initialAccountDetail: self.initialAccountDetail)
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
        
        singleAccountEnrollLabel.textColor = .blackText
        singleAccountEnrollLabel.font = OpenSans.regular.of(textStyle: .headline)
        singleAccountEnrollLabel.text = NSLocalizedString("Paperless eBill Enrollment Status", comment: "")
        singleAccountEnrollLabel.isAccessibilityElement = false
        
        singleAccountEnrollSwitch.accessibilityLabel = singleAccountEnrollLabel.text
        
        enrollAllAccountsHeaderLabel.textColor = .blackText
        enrollAllAccountsHeaderLabel.font = OpenSans.regular.of(textStyle: .footnote)
        enrollAllAccountsHeaderLabel.text = NSLocalizedString("Enrollment Status:", comment: "")
        
        allAccountsLabel.font = SystemFont.medium.of(textStyle: .title1)
        
        footerLabel.font = SystemFont.regular.of(textStyle: .caption1)
        footerLabel.text = viewModel.footerText
        footerContainer.isHidden = viewModel.footerText == nil
        
        viewModel.accountDetails
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] accountDetails -> () in
                guard let self = self else { return }
                
                self.enrollAllAccountsSwitch.isEnabled = true
                self.detailsLoadingActivityView.isHidden = true
                UIAccessibility.post(notification: .screenChanged, argument: self.view)
                if self.viewModel.accounts.value.count == 1 {
                    let accountDetail = accountDetails.first!
                    self.singleAccountEnrollSwitch.isOn = accountDetail.eBillEnrollStatus == .canUnenroll
                    self.singleAccountEnrollSwitch.rx.isOn.asDriver().drive(onNext: { [weak self] isOn in
                        self?.viewModel.switched(accountDetail: accountDetail, on: isOn)
                    }).disposed(by: self.bag)
                } else {
                    accountDetails.forEach {
                        self.add(accountDetail: $0, animated: true)
                    }
                }
            })
            .disposed(by: bag)
        
        viewModel.enrollAllAccounts.distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] in
                self?.enrollAllAccountsSwitch.setOn($0, animated: true)
            })
            .disposed(by: bag)
        
//        Driver.combineLatest(viewModel.accountsToEnroll.asDriver(), viewModel.accountsToUnenroll.asDriver()) { !$0.isEmpty || !$1.isEmpty }
//            .drive(submitButton.rx.isEnabled)
//            .disposed(by: bag)
        
        if viewModel.accounts.value.count == 1 {
            enrollAllAccountsHeaderView.isHidden = true
            enrollAllAccountsView.isHidden = true
            accountsStackView.isHidden = true
        } else {
            accountInfoBar.isHidden = true
            singleAccountEnrollView.isHidden = true
        }
        
        enrollAllAccountsSwitch.accessibilityLabel = NSLocalizedString("Enrollment status: ", comment: "")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func add(accountDetail: AccountDetail, animated: Bool) {
        let accountView = PaperlessEBillAccountView.create(withAccountDetail: accountDetail)
        
        accountView.isOn?.asDriver()
            .drive(onNext: { [weak self] isOn in
                self?.viewModel.switched(accountDetail: accountDetail, on: isOn)
            })
            .disposed(by: accountView.bag)
        
        enrollAllAccountsSwitch.rx.isOn.asDriver().skip(1)
            .drive(onNext: {
                accountView.toggleSwitch(on: $0)
            })
            .disposed(by: accountView.bag)
        
        accountsStackView.addArrangedSubview(accountView)
    }
    
    @IBAction func onTooltipPress() {
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

    @IBAction func submitAction(_ sender: Any) {
        LoadingView.show()
        viewModel.submitChanges(onSuccess: { [weak self] changedStatus in
            LoadingView.hide()
            guard let self = self else { return }
            self.delegate?.paperlessEBillViewController(self, didChangeStatus: changedStatus)
            self.navigationController?.popViewController(animated: true)
        }, onError: { [weak self] errMessage in
            LoadingView.hide()
            let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self?.present(alertVc, animated: true, completion: nil)
        })
    }

}
