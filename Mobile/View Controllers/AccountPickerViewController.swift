//
//  AccountPickerViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/4/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class AccountPickerViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var accountPicker: AccountPicker!
    
    var containerView: UIView!
    var innerView: UIView!
    var accountNumberLabel: UILabel!
    var isAnimating = false
    
    let accountPickerViewControllerWillAppear = PublishSubject<Void>()
    
    open var defaultStatusBarStyle: UIStatusBarStyle = .default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let commercialUser = UserDefaults.standard.bool(forKey: UserDefaultKeys.IsCommercialUser) && Environment.sharedInstance.opco != .bge
        
        containerView = UIView(frame: CGRect(x: 0, y: -60, width: UIScreen.main.bounds.size.width, height: 60))
        containerView.backgroundColor = .white
        containerView.addShadow(color: .black, opacity: 0.1, offset: CGSize(width: 0, height: 2), radius: 2)
        containerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onMinimizedPickerTap)))
        
        innerView = UIView(frame: .zero)
        innerView.translatesAutoresizingMaskIntoConstraints = false
        let iconView = UIImageView(image: commercialUser ? #imageLiteral(resourceName: "ic_commercial_mini") : #imageLiteral(resourceName: "ic_residential_mini"))
        iconView.translatesAutoresizingMaskIntoConstraints = false
        accountNumberLabel = UILabel(frame: .zero)
        accountNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        accountNumberLabel.font = UIFont.systemFont(ofSize: 14)
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
                if !self.isAnimating {
                    self.accountNumberLabel.text = AccountsStore.sharedInstance.currentAccount.accountNumber
                    self.setNeedsStatusBarAppearanceUpdate()
                    
                    // 2 separate animations here so that the icon/text are completely transparent by the time they animate under the status bar
                    self.isAnimating = true
                    UIView.animate(withDuration: 0.1, animations: {
                        self.innerView.alpha = pickerVisible ? 0 : 1
                    })
                    UIView.animate(withDuration: 0.2, animations: {
                        self.containerView.frame.origin = CGPoint(x: 0, y: pickerVisible ? -60 : 0)
                    }, completion: { _ in
                        self.isAnimating = false
                    })
                }

            })
            .addDisposableTo(disposeBag)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if AccountsStore.sharedInstance.currentAccount != accountPicker.currentAccount {
            accountPicker.updateCurrentAccount()
        }
        
        accountPickerViewControllerWillAppear.onNext()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return scrollView.contentOffset.y <= accountPicker.frame.size.height ? defaultStatusBarStyle: .default
    }
    
    func onMinimizedPickerTap() {
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
}

