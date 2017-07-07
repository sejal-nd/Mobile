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
    var loadingIndicator: LoadingIndicator!

    var currentAccount: Account!
    private var loadedAccounts = false
    
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
        backgroundColor = .clear

        scrollView = UIScrollView(frame: .zero)
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        addSubview(scrollView)

        pageControl = UIPageControl(frame: .zero)
        pageControl.pageIndicatorTintColor = tintWhite ? UIColor.white.withAlphaComponent(0.43) : .accentGray
        pageControl.currentPageIndicatorTintColor = tintWhite ? .white : .actionBlue
        pageControl.addTarget(self, action: #selector(onPageControlTap(sender:)), for: .valueChanged)
        addSubview(pageControl)
        
        loadingIndicator = LoadingIndicator(frame: .zero)
        loadingIndicator.isHidden = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(loadingIndicator)
        loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    func setLoading(_ loading: Bool) {
        loadingIndicator.isHidden = !loading
    }

    func loadAccounts() {
        if loadedAccounts { return } // Prevent calling this multiple times
        loadedAccounts = true

        let allAccounts: [Account] = AccountsStore.sharedInstance.accounts
        currentAccount = allAccounts[0]
        var pagedAccounts: [Account] = allAccounts
        
        var isMultiPremise = false
        
        for account in allAccounts {
            if account.isMultipremise {
                isMultiPremise = true
            }
        }

        if allAccounts.count > 1 && allAccounts.count <= MAX_ACCOUNTS {
            pageControl.numberOfPages = allAccounts.count
            pageControl.currentPage = 0
        } else {
            pagedAccounts = Array(allAccounts.prefix(MAX_ACCOUNTS))
            pageControl.isHidden = true
        }

        pageViews.removeAll()
        if allAccounts.count <= MAX_ACCOUNTS && !isMultiPremise {
            for account in pagedAccounts {
                addAccountToScrollView(account)
            }
        } else { // Advanced Account Picker
            addAccountToScrollView(pagedAccounts[0], advancedPicker: true)
        }

        setNeedsLayout()
    }
    
    private func addAccountToScrollView(_ account: Account, advancedPicker: Bool = false) {
        let commercialUser = UserDefaults.standard.bool(forKey: UserDefaultKeys.IsCommercialUser) && Environment.sharedInstance.opco != .bge
        
        let pageView = UIView(frame: .zero)
        pageViews.append(pageView)
        
        let icon: UIImage
        let a11yDescription: String
        switch (commercialUser, tintWhite) {
        case (true, true):
            icon = #imageLiteral(resourceName: "ic_commercial_white")
            a11yDescription = NSLocalizedString("Commercial account", comment: "")
        case (true, false):
            icon = #imageLiteral(resourceName: "ic_commercial")
            a11yDescription = NSLocalizedString("Commercial account", comment: "")
        case (false, true):
            icon = #imageLiteral(resourceName: "ic_residential_white")
            a11yDescription = NSLocalizedString("Residential account", comment: "")
        case (false, false):
            icon = #imageLiteral(resourceName: "ic_residential")
            a11yDescription = NSLocalizedString("Residential account", comment: "")
        }
        
        let iconImageView = UIImageView(image: icon)
        iconImageView.frame = CGRect(x: 0, y: 4, width: 43, height: 43)
        iconImageView.isAccessibilityElement = true
        iconImageView.accessibilityLabel = a11yDescription
        
        let accountNumberLabel = UILabel(frame: .zero)
        accountNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        accountNumberLabel.font = SystemFont.regular.of(textStyle: .headline)
        accountNumberLabel.textColor = tintWhite ? .white: .blackText
        accountNumberLabel.text = account.accountNumber
        accountNumberLabel.accessibilityLabel = String(format: NSLocalizedString("Account number %@", comment: ""), account.accountNumber)
        
        let addressLabel = UILabel(frame: .zero)
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.font = SystemFont.regular.of(textStyle: .footnote)
        addressLabel.textColor = tintWhite ? .white: .deepGray
        addressLabel.text = account.address
        if let address = account.address {
            addressLabel.accessibilityLabel = String(format: NSLocalizedString("Street address %@", comment: ""), address)
        }
        
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
            // REMOVE THIS CONSTRAINT TO NOT LIMIT ADDRESS LENGTH:
            NSLayoutConstraint(item: addressLabel, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 150),
            
            // accountView
            NSLayoutConstraint(item: accountView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 57),
            NSLayoutConstraint(item: accountView, attribute: .centerX, relatedBy: .equal, toItem: pageView, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: accountView, attribute: .centerY, relatedBy: .equal, toItem: pageView, attribute: .centerY, multiplier: 1, constant: 0)
        ])
        
        if advancedPicker { // Makes area tappable and adds caret icon
            advancedAccountNumberLabel = accountNumberLabel
            advancedAccountAddressLabel = addressLabel
            
            advancedAccountButton = UIButton(frame: scrollView.frame)
            advancedAccountButton!.addTarget(self, action: #selector(onAdvancedAccountButtonPress), for: .touchUpInside)
            addSubview(advancedAccountButton!)
            
            let caret = tintWhite ? #imageLiteral(resourceName: "ic_caret_white"): #imageLiteral(resourceName: "ic_caret")
            let caretImageView = UIImageView(image: caret)
            caretImageView.frame = .zero
            caretImageView.translatesAutoresizingMaskIntoConstraints = false
            pageView.addSubview(caretImageView)
            
            self.addConstraints([
                NSLayoutConstraint(item: caretImageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 8),
                NSLayoutConstraint(item: caretImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 13),
                NSLayoutConstraint(item: caretImageView, attribute: .trailing, relatedBy: .equal, toItem: pageView, attribute: .trailing, multiplier: 1, constant: -18),
                NSLayoutConstraint(item: caretImageView, attribute: .centerY, relatedBy: .equal, toItem: pageView, attribute: .centerY, multiplier: 1, constant: 0)
            ])
        }
    }
    
    func onAdvancedAccountButtonPress() {
        let storyboard = UIStoryboard(name: "Outage", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "advancedAccountPicker") as? AdvancedAccountPickerViewController {
            vc.delegate = self
            vc.accounts = AccountsStore.sharedInstance.accounts
            if let parentVc = parentViewController {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    vc.modalPresentationStyle = .formSheet
                    parentVc.present(vc, animated: true, completion: nil)
                } else {
                    parentVc.navigationController?.pushViewController(vc, animated: true)
                }
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
        if account.currentPremise != nil {
            advancedAccountAddressLabel?.text = account.currentPremise!.addressGeneral
        } else {
            advancedAccountAddressLabel?.text = account.address
        }
        
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
