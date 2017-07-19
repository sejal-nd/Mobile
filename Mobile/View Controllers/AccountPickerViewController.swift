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
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var accountPicker: AccountPicker!
    
    var containerView: UIView!
    var innerView: UIView!
    var accountNumberLabel: UILabel!
    
    let accountPickerViewControllerWillAppear = PublishSubject<AccountPickerViewControllerState>()
    
    var defaultStatusBarStyle: UIStatusBarStyle { return .default }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let commercialUser = UserDefaults.standard.bool(forKey: UserDefaultKeys.IsCommercialUser)
        
        containerView = UIView(frame: CGRect(x: 0, y: -60, width: UIScreen.main.bounds.size.width, height: 60))
        containerView.backgroundColor = .white
        containerView.addShadow(color: .black, opacity: 0.1, offset: CGSize(width: 0, height: 2), radius: 2)
        containerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onMinimizedPickerTap)))
        
        innerView = UIView(frame: .zero)
        innerView.translatesAutoresizingMaskIntoConstraints = false
        let iconView = UIImageView(image: commercialUser ? #imageLiteral(resourceName: "ic_commercial_mini") : #imageLiteral(resourceName: "ic_residential_mini"))
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.isAccessibilityElement = true
        iconView.accessibilityLabel = commercialUser ? NSLocalizedString("Commercial account", comment: "") : NSLocalizedString("Residential account", comment: "")
        
        accountNumberLabel = UILabel(frame: .zero)
        accountNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        accountNumberLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        accountNumberLabel.textColor = .deepGray
        accountNumberLabel.numberOfLines = 1
        
        innerView.addSubview(iconView)
        innerView.addSubview(accountNumberLabel)
        containerView.addSubview(innerView)
        view.addSubview(containerView)
        
        view.addConstraints([
            // innerView
            NSLayoutConstraint(item: innerView, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: innerView, attribute: .centerY, relatedBy: .equal, toItem: containerView, attribute: .centerY, multiplier: 1, constant: 10),
            
            // iconView
            NSLayoutConstraint(item: iconView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20),
            NSLayoutConstraint(item: iconView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20),
            NSLayoutConstraint(item: iconView, attribute: .leading, relatedBy: .equal, toItem: innerView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: iconView, attribute: .centerY, relatedBy: .equal, toItem: innerView, attribute: .centerY, multiplier: 1, constant: 0),
            
            // accountNumberLabel
            NSLayoutConstraint(item: accountNumberLabel, attribute: .leading, relatedBy: .equal, toItem: iconView, attribute: .trailing, multiplier: 1, constant: 4),
            NSLayoutConstraint(item: accountNumberLabel, attribute: .trailing, relatedBy: .equal, toItem: innerView, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: accountNumberLabel, attribute: .top, relatedBy: .equal, toItem: innerView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: accountNumberLabel, attribute: .bottom, relatedBy: .equal, toItem: innerView, attribute: .bottom, multiplier: 1, constant: 0),
            ])
        
        scrollView.rx.contentOffset.asDriver()
            .map { $0.y <= self.accountPicker.frame.size.height }
            .distinctUntilChanged()
            .drive(onNext: { pickerVisible in
                if let currentAccount = AccountsStore.sharedInstance.currentAccount { // Don't show if accounts not loaded
                    self.accountNumberLabel.text = currentAccount.accountNumber
                    self.accountNumberLabel.accessibilityLabel = String(format: NSLocalizedString("Account number %@", comment: ""), currentAccount.accountNumber)
                    self.setNeedsStatusBarAppearanceUpdate()
                    
                    // 2 separate animations here so that the icon/text are completely transparent by the time they animate under the status bar
                    UIView.animate(withDuration: 0.1, animations: {
                        self.innerView.alpha = pickerVisible ? 0 : 1
                    })
                    UIView.animate(withDuration: 0.2, animations: {
                        self.containerView.frame.origin = CGPoint(x: 0, y: pickerVisible ? -60 : 0)
                    })
                }
            })
            .addDisposableTo(disposeBag)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if AccountsStore.sharedInstance.currentAccount == nil {
            accountPickerViewControllerWillAppear.onNext(.loadingAccounts)
            fetchAccounts()
        } else {
            accountPicker.loadAccounts()
            accountPickerViewControllerWillAppear.onNext(.readyToFetchData)
            if AccountsStore.sharedInstance.currentAccount != accountPicker.currentAccount {
                accountPicker.updateCurrentAccount()
            }
        }

    }
    
    func fetchAccounts() {
        accountPicker.setLoading(true)
        accountService.fetchAccounts()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                self.accountPicker.setLoading(false)
                self.accountPicker.loadAccounts()
                self.accountPickerViewControllerWillAppear.onNext(.readyToFetchData)
            }, onError: { err in
                self.accountPicker.setLoading(false)
                let alertVc = UIAlertController(title: NSLocalizedString("Could Not Load Accounts", comment: ""), message: err.localizedDescription, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Retry", comment: ""), style: .default, handler: { _ in
                    self.fetchAccounts()
                }))
                self.present(alertVc, animated: true, completion: nil)
            }).addDisposableTo(disposeBag)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        containerView.frame = CGRect(x: 0, y: scrollView.contentOffset.y <= accountPicker.frame.size.height ? -60 : 0, width: UIScreen.main.bounds.size.width, height: 60)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return scrollView.contentOffset.y <= accountPicker.frame.size.height ? defaultStatusBarStyle: .default
    }
    
    func onMinimizedPickerTap() {
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
}

