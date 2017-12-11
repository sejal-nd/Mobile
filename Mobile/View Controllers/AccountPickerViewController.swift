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
    var innerView: UIView!
    var iconView: UIImageView!
    var accountNumberLabel: UILabel!
    
    let accountPickerViewControllerWillAppear = PublishSubject<AccountPickerViewControllerState>()
    
    var defaultStatusBarStyle: UIStatusBarStyle { return .default }
    
    var minimizedPickerHeight: CGFloat = 60
    var safeAreaTop: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let sv = scrollView {
            containerView = UIView(frame: CGRect(x: 0, y: -minimizedPickerHeight, width: view.bounds.size.width, height: minimizedPickerHeight))
            containerView.backgroundColor = .white
            containerView.addShadow(color: .black, opacity: 0.1, offset: CGSize(width: 0, height: 2), radius: 2)
            containerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onMinimizedPickerTap)))
            
            innerView = UIView(frame: .zero)
            innerView.translatesAutoresizingMaskIntoConstraints = false
            
            iconView = UIImageView(frame: .zero)
            iconView.translatesAutoresizingMaskIntoConstraints = false
            iconView.isAccessibilityElement = true
            
            accountNumberLabel = UILabel(frame: .zero)
            accountNumberLabel.translatesAutoresizingMaskIntoConstraints = false
            accountNumberLabel.font = SystemFont.regular.of(textStyle: .subheadline)
            accountNumberLabel.textColor = .deepGray
            accountNumberLabel.numberOfLines = 1
            accountNumberLabel.lineBreakMode = .byTruncatingTail

            innerView.addSubview(iconView)
            innerView.addSubview(accountNumberLabel)
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
                // innerView
                NSLayoutConstraint(item: innerView, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: innerView, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1, constant: topSpaceConstant),
                NSLayoutConstraint(item: innerView, attribute: .bottom, relatedBy: .equal, toItem: containerView, attribute: .bottom, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: innerView, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: containerView, attribute: .leading, multiplier: 1, constant: 16),
                NSLayoutConstraint(item: innerView, attribute: .trailing, relatedBy: .lessThanOrEqual, toItem: containerView, attribute: .trailing, multiplier: 1, constant: -16),
                
                // iconView
                NSLayoutConstraint(item: iconView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20),
                NSLayoutConstraint(item: iconView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20),
                NSLayoutConstraint(item: iconView, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: innerView, attribute: .leading, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: iconView, attribute: .centerY, relatedBy: .equal, toItem: innerView, attribute: .centerY, multiplier: 1, constant: 0),
                
                // accountNumberLabel
                NSLayoutConstraint(item: accountNumberLabel, attribute: .leading, relatedBy: .equal, toItem: iconView, attribute: .trailing, multiplier: 1, constant: 4),
                NSLayoutConstraint(item: accountNumberLabel, attribute: .trailing, relatedBy: .equal, toItem: innerView, attribute: .trailing, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: accountNumberLabel, attribute: .top, relatedBy: .equal, toItem: innerView, attribute: .top, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: accountNumberLabel, attribute: .bottom, relatedBy: .equal, toItem: innerView, attribute: .bottom, multiplier: 1, constant: 0),
            ])
            
            sv.rx.contentOffset.asDriver()
                .map { [weak self] offset -> Bool in
                    guard let `self` = self else { return false }
                    return offset.y <= self.accountPicker.frame.size.height
                }
                .distinctUntilChanged()
                .drive(onNext: { [weak self] pickerVisible in
                    guard let `self` = self else { return }
                    if let currentAccount = AccountsStore.sharedInstance.currentAccount { // Don't show if accounts not loaded
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
                    }
                })
                .disposed(by: disposeBag)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let currentAccount = AccountsStore.sharedInstance.currentAccount
        if currentAccount == nil {
            accountPickerViewControllerWillAppear.onNext(.loadingAccounts)
            fetchAccounts()
        } else {
            accountPicker.loadAccounts()
            accountPickerViewControllerWillAppear.onNext(.readyToFetchData)
            if currentAccount != accountPicker.currentAccount || currentAccount?.currentPremise != accountPicker.currentAccount.currentPremise {
                accountPicker.updateCurrentAccount()
            }
        }
    }
    
    func fetchAccounts() {
        accountPicker.setLoading(true)
        accountService.fetchAccounts()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.accountPicker.setLoading(false)
                self.accountPicker.loadAccounts()
                self.accountPickerViewControllerWillAppear.onNext(.readyToFetchData)
            }, onError: { [weak self] err in
                guard let `self` = self else { return }
                self.accountPicker.setLoading(false)
                let alertVc = UIAlertController(title: NSLocalizedString("Could Not Load Accounts", comment: ""), message: err.localizedDescription, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Retry", comment: ""), style: .default, handler: { _ in
                    self.fetchAccounts()
                }))
                self.present(alertVc, animated: true, completion: nil)
            }).disposed(by: disposeBag)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if let sv = scrollView {
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

