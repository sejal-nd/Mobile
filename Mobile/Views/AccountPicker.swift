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
    let shadowView = UIView().usingAutoLayout()

    var currentAccount: Account!
    private var loadedAccounts = false
    
    weak var parentViewController: UIViewController?

    var pageViews = [UIView]()
    
    var advancedAccountIconImageView: UIImageView?
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
        
        scrollView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: intrinsicContentSize.height)
        pageControl.frame = CGRect(x: frame.size.width / 2 - 80, y: intrinsicContentSize.height - 23, width: 160, height: 7)
        
        if let button = advancedAccountButton {
            button.frame = scrollView.frame
        }
        
        if pageViews.count > 0 {
            for index in 0..<pageViews.count {
                let pageView = pageViews[index]
                pageView.frame = CGRect(x: CGFloat(index) * frame.size.width, y: 0, width: frame.size.width, height: intrinsicContentSize.height)
            }
            
            scrollView.contentSize = CGSize(width: frame.size.width * CGFloat(pageViews.count), height: intrinsicContentSize.height)
            if pageControl.currentPage < pageViews.count {
                scrollView.scrollRectToVisible(pageViews[pageControl.currentPage].frame, animated: false)
            }
        }
        
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 0, height: 90)
    }

    func commonInit() {
        clipsToBounds = true
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
        
        addSubview(shadowView)
        shadowView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        shadowView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        shadowView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        shadowView.topAnchor.constraint(equalTo: bottomAnchor).isActive = true
        shadowView.addShadow(color: .black, opacity: 0.15, offset: .zero, radius: 3)
    }
    
    func setLoading(_ loading: Bool) {
        loadingIndicator.isHidden = !loading
    }

    func loadAccounts() {
        if loadedAccounts { return } // Prevent calling this multiple times
        loadedAccounts = true

        let allAccounts: [Account] = AccountsStore.shared.accounts
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
            pageControl.isHidden = true
            addAccountToScrollView(pagedAccounts[0], advancedPicker: true)
        }
        
        if 2...MAX_ACCOUNTS ~= allAccounts.count && !isMultiPremise {
            accessibilityElements = [scrollView, pageControl]
        }

        setNeedsLayout()
    }
    
    private func addAccountToScrollView(_ account: Account, advancedPicker: Bool = false) {
        let commercialUser = !account.isResidential
        
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
        
        shadowView.backgroundColor = tintWhite ? .primaryColorAccountPicker : .white
        backgroundColor = tintWhite ? .primaryColorAccountPicker : .white
        
        let iconImageView = UIImageView(image: icon)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.isAccessibilityElement = true
        iconImageView.accessibilityLabel = a11yDescription
        
        let accountNumberLabel = UILabel(frame: .zero)
        let finaledString = NSLocalizedString(Environment.shared.opco == .bge ?
                "Stopped" : "Finaled",
                comment: "")
        let linkedString = NSLocalizedString("Linked", comment: "")

        let accountNumberText = "\(account.accountNumber) " +
                "\(account.isFinaled ? "(\(finaledString))" : account.isLinked ? "(\(linkedString))":"")"
        accountNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        accountNumberLabel.setContentHuggingPriority(.required, for: .horizontal)
        accountNumberLabel.font = SystemFont.regular.of(textStyle: .headline)
        accountNumberLabel.textColor = tintWhite ? .white: .blackText
        accountNumberLabel.text = accountNumberText
        accountNumberLabel.accessibilityLabel = String(format: NSLocalizedString("Account number %@", comment: ""), accountNumberText)
        
        let addressLabel = UILabel(frame: .zero)
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.font = SystemFont.regular.of(textStyle: .footnote)
        addressLabel.textColor = tintWhite ? .white: .deepGray
        addressLabel.text = account.address ?? " "
        if let address = account.address {
            addressLabel.accessibilityLabel = String(format: NSLocalizedString("Street address %@", comment: ""), address)
        } else {
            addressLabel.accessibilityLabel = ""
        }
        
        let accountInfoStackView = UIStackView(arrangedSubviews: [accountNumberLabel, addressLabel])
        accountInfoStackView.translatesAutoresizingMaskIntoConstraints = false
        accountInfoStackView.axis = .vertical
        accountInfoStackView.alignment = .leading
        accountInfoStackView.distribution = .fill
        
        let accountStackView = UIStackView(arrangedSubviews: [iconImageView, accountInfoStackView])
        accountStackView.translatesAutoresizingMaskIntoConstraints = false
        accountStackView.axis = .horizontal
        accountStackView.alignment = .center
        accountStackView.distribution = .fill
        accountStackView.spacing = 7
        
        pageView.addSubview(accountStackView)
        scrollView.addSubview(pageView)
        
        accountStackView.centerXAnchor.constraint(equalTo: pageView.centerXAnchor, constant: 0).isActive = true
        accountStackView.topAnchor.constraint(equalTo: pageView.topAnchor, constant: 10).isActive = true
        //addressLabel.widthAnchor.constraint(equalTo: accountNumberLabel.widthAnchor, multiplier: 1.2).isActive = true
        addressLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 220).isActive = true
        
        if advancedPicker { // Makes area tappable and adds caret icon
            advancedAccountIconImageView = iconImageView
            advancedAccountNumberLabel = accountNumberLabel
            advancedAccountAddressLabel = addressLabel
            
            advancedAccountButton = UIButton(frame: scrollView.frame)
            advancedAccountButton!.addTarget(self, action: #selector(onAdvancedAccountButtonPress), for: .touchUpInside)
            advancedAccountButton?.isAccessibilityElement = true
            advancedAccountButton?.accessibilityLabel = NSLocalizedString("Account selector", comment: "")
            addSubview(advancedAccountButton!)
            
            let caret = tintWhite ? #imageLiteral(resourceName: "ic_caret_white"): #imageLiteral(resourceName: "ic_caret")
            let caretImageView = UIImageView(image: caret)
            caretImageView.frame = .zero
            caretImageView.translatesAutoresizingMaskIntoConstraints = false
            pageView.addSubview(caretImageView)
            
            addConstraints([
                caretImageView.widthAnchor.constraint(equalToConstant: 8),
                caretImageView.heightAnchor.constraint(equalToConstant: 13),
                caretImageView.trailingAnchor.constraint(equalTo: pageView.trailingAnchor, constant: -18),
                caretImageView.centerYAnchor.constraint(equalTo: pageView.centerYAnchor)
            ])
        }
    }
    
    @objc func onAdvancedAccountButtonPress() {
        let storyboard = UIStoryboard(name: "Outage", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "advancedAccountPicker") as? AdvancedAccountPickerViewController {
            vc.delegate = self
            vc.accounts = AccountsStore.shared.accounts
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
    
    @objc func onPageControlTap(sender: UIPageControl) {
        scrollView.scrollRectToVisible(CGRect(x: frame.size.width * CGFloat(pageControl.currentPage), y: 0, width: frame.size.width, height: 57), animated: true)
        currentAccount = AccountsStore.shared.accounts[pageControl.currentPage]
        AccountsStore.shared.currentAccount = currentAccount
        delegate?.accountPickerDidChangeAccount(self)
    }
    
    func updateCurrentAccount() {
        currentAccount = AccountsStore.shared.currentAccount
        
        if pageViews.count > 0 {
            for (index, account) in AccountsStore.shared.accounts.enumerated() {
                if account == currentAccount {
                    pageControl.currentPage = index
                    scrollView.scrollRectToVisible(CGRect(x: frame.size.width * CGFloat(pageControl.currentPage), y: 0, width: frame.size.width, height: 57), animated: false)
                    break
                }
            }
        }
        
        updateAdvancedAccountPicker(currentAccount)
    }
    
    func updateAdvancedAccountPicker(_ account: Account) {
        let icon: UIImage
        let a11yDescription: String
        switch (!account.isResidential, tintWhite) {
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
        advancedAccountIconImageView?.image = icon
        advancedAccountIconImageView?.accessibilityLabel = a11yDescription
        
        let finaledString = NSLocalizedString(Environment.shared.opco == .bge ?
            "Stopped" : "Finaled",
                                              comment: "")
        let linkedString = NSLocalizedString("Linked", comment: "")
        
        let accountNumberText = "\(account.accountNumber) " +
        "\(account.isFinaled ? "(\(finaledString))" : account.isLinked ? "(\(linkedString))":"")"
        
        advancedAccountNumberLabel?.text = accountNumberText
        advancedAccountNumberLabel?.accessibilityLabel = String(format: NSLocalizedString("Account number %@", comment: ""), account.accountNumber)
        if account.currentPremise != nil {
            advancedAccountAddressLabel?.text = account.currentPremise?.addressGeneral ?? " "
        } else {
            advancedAccountAddressLabel?.text = account.address ?? " "
        }
        if advancedAccountAddressLabel?.text == " " {
            advancedAccountAddressLabel?.accessibilityLabel = ""
        } else {
            advancedAccountAddressLabel?.accessibilityLabel = String(format: NSLocalizedString("Street address %@", comment: ""), advancedAccountAddressLabel?.text ?? "")
        }
    }
    
}

extension AccountPicker: AdvancedAccountPickerViewControllerDelegate {
    func advancedAccountPickerViewController(_ advancedAccountPickerViewController: AdvancedAccountPickerViewController, didSelectAccount account: Account) {
        currentAccount = account
        AccountsStore.shared.currentAccount = account
        
        updateAdvancedAccountPicker(account)
        
        delegate?.accountPickerDidChangeAccount(self)
    }
}

extension AccountPicker: UIScrollViewDelegate {

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)

        if currentPage != pageControl.currentPage {
            pageControl.currentPage = currentPage
            currentAccount = AccountsStore.shared.accounts[currentPage]
            AccountsStore.shared.currentAccount = currentAccount
            delegate?.accountPickerDidChangeAccount(self)
        }
    }

}
