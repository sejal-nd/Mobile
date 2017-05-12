//
//  AccountScroller.swift
//  Mobile
//
//  Created by Marc Shilling on 3/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

protocol AccountPickerDelegate: class {
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker)
}

class AccountPicker: UIView {
    
    let MAX_ACCOUNTS = 5
    
    weak var delegate: AccountPickerDelegate?

    var scrollView: UIScrollView!
    var pageControl: UIPageControl!

    var currentAccount: Account!
    
    var parentViewController: UIViewController?

    var pageViews = [UIView]()
    
    var advancedAccountNumberLabel: UILabel?
    var advancedAccountAddressLabel: UILabel?
    var advancedAccountButton: UIButton?
    
    @IBInspectable var tintWhite: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        scrollView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: 57)
        pageControl.frame = CGRect(x: frame.size.width / 2 - 80, y: 57, width: 160, height: 7)
        
        if let button = advancedAccountButton {
            button.frame = scrollView.frame
        }
        
        if pageViews.count > 0 {
            for index in 0..<pageViews.count {
                let pageView = pageViews[index]
                pageView.frame = CGRect(x: CGFloat(index) * frame.size.width, y: 0, width: frame.size.width, height: 57)
            }
            
            scrollView.contentSize = CGSize(width: frame.size.width * CGFloat(pageViews.count), height: 57)
            scrollView.scrollRectToVisible(pageViews[pageControl.currentPage].frame, animated: false)
        }
        
    }

    func commonInit() {
        currentAccount = AccountsStore.sharedInstance.accounts[0]
        
        backgroundColor = .clear

        scrollView = UIScrollView(frame: .zero)
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        addSubview(scrollView)

        pageControl = UIPageControl(frame: .zero)
        pageControl.pageIndicatorTintColor = tintWhite ? UIColor.white.withAlphaComponent(0.43) : UIColor(red: 16/255, green: 56/255, blue: 112/255, alpha: 0.5)
        pageControl.currentPageIndicatorTintColor = tintWhite ? .white : UIColor(red: 16/255, green: 56/255, blue: 112/255, alpha: 1)
        pageControl.addTarget(self, action: #selector(onPageControlTap(sender:)), for: .valueChanged)
        addSubview(pageControl)
        
        setAccounts()
    }

    private func setAccounts() {

        let allAccounts: [Account]! = AccountsStore.sharedInstance.accounts
        var pagedAccounts: [Account]! = allAccounts

        if allAccounts.count > 1 && allAccounts.count <= MAX_ACCOUNTS {
            pageControl.numberOfPages = allAccounts.count
            pageControl.currentPage = 0
        } else {
            pagedAccounts = Array(allAccounts.prefix(MAX_ACCOUNTS))
            pageControl.isHidden = true
        }
        
        let commercialUser = UserDefaults.standard.bool(forKey: UserDefaultKeys.IsCommercialUser) && Environment.sharedInstance.opco != .bge

        pageViews.removeAll()
        if allAccounts.count <= MAX_ACCOUNTS {
            for account in pagedAccounts {
                let pageView = UIView(frame: .zero)
                pageViews.append(pageView)
                
                let icon: UIImage
                switch (commercialUser, tintWhite) {
                case (true, true):
                    icon = #imageLiteral(resourceName: "ic_commercial_white")
                case (true, false):
                    icon = #imageLiteral(resourceName: "ic_commercial")
                case (false, true):
                    icon = #imageLiteral(resourceName: "ic_residential_white")
                case (false, false):
                    icon = #imageLiteral(resourceName: "ic_residential")
                }
                
                let iconImageView = UIImageView(image: icon)
                iconImageView.frame = CGRect(x: 0, y: 4, width: 43, height: 43)
                
                let accountNumberLabel = UILabel(frame: .zero)
                accountNumberLabel.translatesAutoresizingMaskIntoConstraints = false
                accountNumberLabel.font = UIFont.systemFont(ofSize: 17)
                accountNumberLabel.textColor = tintWhite ? .white: .blackText
                accountNumberLabel.text = account.accountNumber
                
                let addressLabel = UILabel(frame: .zero)
                addressLabel.translatesAutoresizingMaskIntoConstraints = false
                addressLabel.font = UIFont.systemFont(ofSize: 12)
                addressLabel.textColor = tintWhite ? .white: .deepGray
                addressLabel.text = account.address
                
                let accountView = UIView(frame: .zero)
                accountView.translatesAutoresizingMaskIntoConstraints = false
                accountView.addSubview(iconImageView)
                accountView.addSubview(accountNumberLabel)
                accountView.addSubview(addressLabel)
                
                pageView.addSubview(accountView)
                scrollView.addSubview(pageView)
                
                self.addConstraints([
                    // accountNumberLabel
                    NSLayoutConstraint(item: accountNumberLabel, attribute: .top, relatedBy: .equal, toItem: accountView, attribute: .top, multiplier: 1, constant: 11),
                    NSLayoutConstraint(item: accountNumberLabel, attribute: .leading, relatedBy: .equal, toItem: accountView, attribute: .leading, multiplier: 1, constant: 51),
                    NSLayoutConstraint(item: accountNumberLabel, attribute: .trailing, relatedBy: .equal, toItem: accountView, attribute: .trailing, multiplier: 1, constant: 0),
                    NSLayoutConstraint(item: accountNumberLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20),
                    
                    // addressLabel
                    NSLayoutConstraint(item: addressLabel, attribute: .top, relatedBy: .equal, toItem: accountView, attribute: .top, multiplier: 1, constant: 32),
                    NSLayoutConstraint(item: addressLabel, attribute: .leading, relatedBy: .equal, toItem: accountView, attribute: .leading, multiplier: 1, constant: 51),
                    NSLayoutConstraint(item: addressLabel, attribute: .trailing, relatedBy: .equal, toItem: accountView, attribute: .trailing, multiplier: 1, constant: 0),
                    NSLayoutConstraint(item: addressLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 14),
                    // TODO: REMOVE THIS CONSTRAINT TO NOT LIMIT ADDRESS LENGTH:
                    NSLayoutConstraint(item: addressLabel, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 150),
                    
                    // accountView
                    NSLayoutConstraint(item: accountView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 57),
                    NSLayoutConstraint(item: accountView, attribute: .centerX, relatedBy: .equal, toItem: pageView, attribute: .centerX, multiplier: 1, constant: 0),
                    NSLayoutConstraint(item: accountView, attribute: .centerY, relatedBy: .equal, toItem: pageView, attribute: .centerY, multiplier: 1, constant: 0)
                ])
                
            }
        } else {
            let pageView = UIView(frame: .zero)
            pageView.backgroundColor = .clear
            pageViews.append(pageView)
            
            let icon: UIImage
            switch (commercialUser, tintWhite) {
            case (true, true):
                icon = #imageLiteral(resourceName: "ic_commercial_white")
            case (true, false):
                icon = #imageLiteral(resourceName: "ic_commercial")
            case (false, true):
                icon = #imageLiteral(resourceName: "ic_residential_white")
            case (false, false):
                icon = #imageLiteral(resourceName: "ic_residential")
            }
            
            let iconImageView = UIImageView(image: icon)
            iconImageView.frame = CGRect(x: 0, y: 4, width: 43, height: 43)
            
            advancedAccountNumberLabel = UILabel(frame: .zero)
            advancedAccountNumberLabel!.translatesAutoresizingMaskIntoConstraints = false
            advancedAccountNumberLabel!.font = UIFont.systemFont(ofSize: 17)
            advancedAccountNumberLabel!.textColor = tintWhite ? .white: .blackText
            advancedAccountNumberLabel!.text = pagedAccounts[0].accountNumber
            
            advancedAccountAddressLabel = UILabel(frame: .zero)
            advancedAccountAddressLabel!.translatesAutoresizingMaskIntoConstraints = false
            advancedAccountAddressLabel!.font = UIFont.systemFont(ofSize: 12)
            advancedAccountAddressLabel!.textColor = tintWhite ? .white: .deepGray
            advancedAccountAddressLabel!.text = pagedAccounts[0].address
            
            let accountView = UIView(frame: .zero)
            accountView.backgroundColor = .clear
            accountView.translatesAutoresizingMaskIntoConstraints = false
            accountView.addSubview(iconImageView)
            accountView.addSubview(advancedAccountNumberLabel!)
            accountView.addSubview(advancedAccountAddressLabel!)
            
            pageView.addSubview(accountView)
            scrollView.addSubview(pageView)
            
            advancedAccountButton = UIButton(frame: scrollView.frame)
            advancedAccountButton!.addTarget(self, action: #selector(onAdvancedAccountButtonPress), for: .touchUpInside)
            addSubview(advancedAccountButton!)
            
            let caret = tintWhite ? #imageLiteral(resourceName: "ic_caret_white"): #imageLiteral(resourceName: "ic_caret")
            let caretImageView = UIImageView(image: caret)
            caretImageView.frame = .zero
            caretImageView.translatesAutoresizingMaskIntoConstraints = false
            pageView.addSubview(caretImageView)
            
            self.addConstraints([
                // caret
                NSLayoutConstraint(item: caretImageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 8),
                NSLayoutConstraint(item: caretImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 13),
                NSLayoutConstraint(item: caretImageView, attribute: .trailing, relatedBy: .equal, toItem: pageView, attribute: .trailing, multiplier: 1, constant: -18),
                NSLayoutConstraint(item: caretImageView, attribute: .centerY, relatedBy: .equal, toItem: pageView, attribute: .centerY, multiplier: 1, constant: 0),
                
                // accountNumberLabel
                NSLayoutConstraint(item: advancedAccountNumberLabel!, attribute: .top, relatedBy: .equal, toItem: accountView, attribute: .top, multiplier: 1, constant: 11),
                NSLayoutConstraint(item: advancedAccountNumberLabel!, attribute: .leading, relatedBy: .equal, toItem: accountView, attribute: .leading, multiplier: 1, constant: 51),
                NSLayoutConstraint(item: advancedAccountNumberLabel!, attribute: .trailing, relatedBy: .equal, toItem: accountView, attribute: .trailing, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: advancedAccountNumberLabel!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20),
                
                // addressLabel
                NSLayoutConstraint(item: advancedAccountAddressLabel!, attribute: .top, relatedBy: .equal, toItem: accountView, attribute: .top, multiplier: 1, constant: 32),
                NSLayoutConstraint(item: advancedAccountAddressLabel!, attribute: .leading, relatedBy: .equal, toItem: accountView, attribute: .leading, multiplier: 1, constant: 51),
                NSLayoutConstraint(item: advancedAccountAddressLabel!, attribute: .trailing, relatedBy: .equal, toItem: accountView, attribute: .trailing, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: advancedAccountAddressLabel!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 14),
                // TODO: REMOVE THIS CONSTRAINT TO NOT LIMIT ADDRESS LENGTH:
                NSLayoutConstraint(item: advancedAccountAddressLabel!, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 150),
                
                // accountView
                NSLayoutConstraint(item: accountView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 57),
                NSLayoutConstraint(item: accountView, attribute: .centerX, relatedBy: .equal, toItem: pageView, attribute: .centerX, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: accountView, attribute: .centerY, relatedBy: .equal, toItem: pageView, attribute: .centerY, multiplier: 1, constant: 0)
            ])

        }

        setNeedsLayout()
    }
    
    func onAdvancedAccountButtonPress() {
        let storyboard = UIStoryboard(name: "Outage", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "advancedAccountPicker") as? AdvancedAccountPickerViewController {
            vc.delegate = self
            vc.accounts = AccountsStore.sharedInstance.accounts
            if let parentVc = parentViewController {
                parentVc.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func onPageControlTap(sender: UIPageControl) {
        scrollView.scrollRectToVisible(CGRect(x: frame.size.width * CGFloat(pageControl.currentPage), y: 0, width: frame.size.width, height: 57), animated: true)
        currentAccount = AccountsStore.sharedInstance.accounts[pageControl.currentPage]
        AccountsStore.sharedInstance.currentAccount = currentAccount
        delegate?.accountPickerDidChangeAccount(self)
    }
    
    func updateCurrentAccount() {
        currentAccount = AccountsStore.sharedInstance.currentAccount
        
        if pageViews.count > 0 {
            for (index, account) in AccountsStore.sharedInstance.accounts.enumerated() {
                if account == currentAccount {
                    pageControl.currentPage = index
                    scrollView.scrollRectToVisible(CGRect(x: frame.size.width * CGFloat(pageControl.currentPage), y: 0, width: frame.size.width, height: 57), animated: false)
                    break
                }
            }
        }
        
        // Update advanced account picker
        advancedAccountNumberLabel?.text = currentAccount.accountNumber
        advancedAccountAddressLabel?.text = currentAccount.address
    }
    
}

extension AccountPicker: AdvancedAccountPickerViewControllerDelegate {
    func advancedAccountPickerViewController(_ advancedAccountPickerViewController: AdvancedAccountPickerViewController, didSelectAccount account: Account) {
        currentAccount = account
        AccountsStore.sharedInstance.currentAccount = account
        
        // Update advanced account picker
        advancedAccountNumberLabel?.text = account.accountNumber
        advancedAccountAddressLabel?.text = account.address
        
        delegate?.accountPickerDidChangeAccount(self)
    }
}

extension AccountPicker: UIScrollViewDelegate {

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)

        if currentPage != pageControl.currentPage {
            pageControl.currentPage = currentPage
            currentAccount = AccountsStore.sharedInstance.accounts[currentPage]
            AccountsStore.sharedInstance.currentAccount = currentAccount
            delegate?.accountPickerDidChangeAccount(self)
        }
    }

}
