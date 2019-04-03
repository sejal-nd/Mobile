//
//  AccountPickerViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/4/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

enum AccountPickerViewControllerState {
    case loadingAccounts
    case readyToFetchData
}

class AccountPickerViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    private let accountService = ServiceFactory.createAccountService()
    
    @IBOutlet weak var scrollView: UIScrollView?
    @IBOutlet weak var accountPicker: AccountPicker!
    
    var containerView: UIView!
    var innerView: UIStackView!
    var iconView: UIImageView!
    var accountNumberLabel: UILabel!
    
    var defaultStatusBarStyle: UIStatusBarStyle { return .default }
    
    var showMinimizedPicker: Bool { return true } // Override in subclasses to turn off
    var minimizedPickerHeight: CGFloat = 60
    var safeAreaTop: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let sv = scrollView, showMinimizedPicker else { return }
        
        containerView = UIView(frame: CGRect(x: 0, y: -minimizedPickerHeight, width: view.bounds.size.width, height: minimizedPickerHeight))
        containerView.backgroundColor = .white
        containerView.addShadow(color: .black, opacity: 0.1, offset: CGSize(width: 0, height: 2), radius: 2)
        containerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onMinimizedPickerTap)))
        
        iconView = UIImageView(frame: .zero)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.isAccessibilityElement = true
        iconView.setContentCompressionResistancePriority(.required, for: .vertical)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        iconView.setContentHuggingPriority(.required, for: .vertical)
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        
        accountNumberLabel = UILabel(frame: .zero)
        accountNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        accountNumberLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        accountNumberLabel.textColor = .deepGray
        accountNumberLabel.numberOfLines = 1
        accountNumberLabel.lineBreakMode = .byTruncatingTail
        
        innerView = UIStackView(arrangedSubviews: [iconView, accountNumberLabel])
        innerView.axis = .horizontal
        innerView.spacing = 4
        innerView.alignment = .center
        innerView.distribution = .fill
        innerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(innerView)
        view.addSubview(containerView)
        
        var topSpaceConstant: CGFloat = 20
        if #available(iOS 11.0, *) {
            safeAreaTop = UIApplication.shared.keyWindow!.safeAreaInsets.top
            if safeAreaTop > 0 { // iPhone X only
                minimizedPickerHeight = 40 + safeAreaTop
                topSpaceConstant = safeAreaTop
            }
        }
        
        view.addConstraints([
            innerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            innerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: topSpaceConstant),
            innerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            innerView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 16),
            innerView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16)
            ])
        
        sv.rx.contentOffset.asDriver()
            .map { [weak self] offset -> Bool in
                guard let self = self else { return false }
                return offset.y <= self.accountPicker.frame.size.height
            }
            .distinctUntilChanged()
            .drive(onNext: { [weak self] pickerVisible in
                guard let self = self else { return }
                guard AccountsStore.shared.currentIndex != nil else { // Don't show if accounts not loaded
                    return
                }
                
                let currentAccount = AccountsStore.shared.currentAccount
                self.iconView.image = currentAccount.isResidential ? #imageLiteral(resourceName: "ic_residential_mini") : #imageLiteral(resourceName: "ic_commercial_mini")
                self.iconView.accessibilityLabel = currentAccount.isResidential ? NSLocalizedString("Residential account", comment: "") : NSLocalizedString("Commercial account", comment: "")
                if currentAccount.address?.isEmpty ?? true {
                    self.accountNumberLabel.text = currentAccount.accountNumber
                    self.accountNumberLabel.accessibilityLabel = String(format: NSLocalizedString("Account number %@", comment: ""), currentAccount.accountNumber)
                } else {
                    self.accountNumberLabel.text = currentAccount.address!
                    self.accountNumberLabel.accessibilityLabel = String(format: NSLocalizedString("Street address %@", comment: ""), currentAccount.address!)
                }
                self.setNeedsStatusBarAppearanceUpdate()
                
                // 2 separate animations here so that the icon/text are completely transparent by the time they animate under the status bar
                UIView.animate(withDuration: 0.1, animations: {
                    self.innerView.alpha = pickerVisible ? 0 : 1
                })
                UIView.animate(withDuration: 0.2, animations: {
                    self.containerView.frame.origin = CGPoint(x: 0, y: pickerVisible ? -self.minimizedPickerHeight : 0)
                })
            })
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if AccountsStore.shared.currentIndex == nil {
            fetchAccounts()
        } else {
            let currentAccount = AccountsStore.shared.currentAccount
            accountPicker.loadAccounts()
            if currentAccount != accountPicker.currentAccount || currentAccount.currentPremise != accountPicker.currentAccount.currentPremise {
                accountPicker.updateCurrentAccount()
            }
        }
    }
    
    func fetchAccounts() {
        accountPicker.setLoading(true)
        accountService.fetchAccounts()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.accountPicker.setLoading(false)
                self.accountPicker.loadAccounts()
            }, onError: { _ in
                MCSApi.shared.logout()
                NotificationCenter.default.post(name: .didReceiveAccountListError, object: self)
            }).disposed(by: disposeBag)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if let sv = scrollView, showMinimizedPicker {
            containerView.frame = CGRect(x: 0, y: sv.contentOffset.y <= accountPicker.frame.size.height ? -minimizedPickerHeight : 0, width: view.bounds.size.width, height: minimizedPickerHeight)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if let sv = scrollView {
            return sv.contentOffset.y <= accountPicker.frame.size.height ? defaultStatusBarStyle: .default
        }
        return defaultStatusBarStyle
    }
    
    @objc func onMinimizedPickerTap() {
        scrollView?.setContentOffset(.zero, animated: true)
    }
    
}

