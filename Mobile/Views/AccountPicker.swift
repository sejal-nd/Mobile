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
    
    let maxAccounts = 5
    
    weak var delegate: AccountPickerDelegate?

    let scrollView = UIScrollView(frame: .zero)
    let pageControl = UIPageControl(frame: .zero)
    let loadingIndicator = LoadingIndicator(frame: .zero)
    let shadowView = UIView().usingAutoLayout()
    let leftButton = ButtonControl().usingAutoLayout()
    let leftCaretImageView = UIImageView(image: #imageLiteral(resourceName: "ic_caret_white_left"))
    let rightButton = ButtonControl().usingAutoLayout()
    let rightCaretImageView = UIImageView(image: #imageLiteral(resourceName: "ic_caret_white"))
    
    var accounts: [Account]! {
        get { return AccountsStore.shared.accounts }
    }
    
    var currentIndex: Int! {
        didSet {
            AccountsStore.shared.currentIndex = currentIndex
            leftButton.isEnabled = currentIndex > 0
            rightButton.isEnabled = currentIndex < accounts.count - 1
            pageControl.numberOfPages = accounts.count
            pageControl.currentPage = currentIndex
            delegate?.accountPickerDidChangeAccount(self)
        }
    }
    
    var currentAccount: Account {
        return accounts[currentIndex]
    }
    
    private var isMultiPremise: Bool {
        return accounts?.contains { $0.isMultipremise } ?? false
    }
    
    private var shouldScroll: Bool {
        return 2...maxAccounts ~= accounts?.count ?? 0 && !isMultiPremise
    }
    
    private var loadedAccounts = false
    
    weak var parentViewController: UIViewController?

    var pageViews = [UIView]()
    
    var advancedAccountIconImageView: UIImageView?
    var advancedAccountNumberLabel: UILabel?
    var advancedAccountAddressLabel: UILabel?
    var advancedAccountButton: UIButton?
    
    @IBInspectable var tintWhite: Bool = false
    
    @IBInspectable var showShadow: Bool = true {
        didSet {
            shadowView.isHidden = !showShadow
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        leftButton.frame = CGRect(x: 0, y: 0, width: 40, height: intrinsicContentSize.height)
        leftCaretImageView.frame = CGRect(x: leftButton.frame.width / 2 - leftCaretImageView.frame.width / 2,
                                          y: leftButton.frame.height / 2 - leftCaretImageView.frame.height / 2 - 10,
                                          width: 8, height: 13)
        rightButton.frame = CGRect(x: frame.size.width - 40, y: 0, width: 40, height: intrinsicContentSize.height)
        rightCaretImageView.frame = CGRect(x: rightButton.frame.width / 2 - rightCaretImageView.frame.width / 2,
                                           y: rightButton.frame.height / 2 - rightCaretImageView.frame.height / 2 - 10,
                                           width: 8, height: 13)
        
        
        if shouldScroll {
            scrollView.frame = CGRect(x: 40, y: 0, width: frame.size.width - 80, height: intrinsicContentSize.height)
        } else {
            scrollView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: intrinsicContentSize.height)
        }
        
        pageControl.frame = CGRect(x: frame.size.width / 2 - 80, y: intrinsicContentSize.height - 23, width: 160, height: 7)
        
        if let button = advancedAccountButton {
            button.frame = bounds
        }
        
        if pageViews.count > 0 {
            for index in 0..<pageViews.count {
                let pageView = pageViews[index]
                pageView.frame = CGRect(x: CGFloat(index) * scrollView.frame.size.width, y: 0, width: scrollView.frame.size.width, height: intrinsicContentSize.height)
            }
            
            scrollView.contentSize = CGSize(width: scrollView.frame.size.width * CGFloat(pageViews.count), height: intrinsicContentSize.height)
            if pageControl.currentPage < pageViews.count {
                scrollView.scrollRectToVisible(pageViews[accounts.firstIndex(of: currentAccount) ?? 0].frame, animated: false)
            }
        }
        
    }
    
    override var intrinsicContentSize: CGSize {
        if shouldScroll {
            return CGSize(width: 0, height: 90)
        } else {
            return CGSize(width: 0, height: 68)
        }
    }

    func commonInit() {
        clipsToBounds = true
        backgroundColor = .clear
        
        leftButton.shouldFadeSubviewsOnPress = true
        leftButton.addSubview(leftCaretImageView)
        leftButton.isEnabled = false
        addSubview(leftButton)
        leftButton.isHidden = true
        leftButton.isAccessibilityElement = true
        leftButton.accessibilityLabel = NSLocalizedString("Previous account", comment: "")
        
        rightButton.shouldFadeSubviewsOnPress = true
        rightButton.addSubview(rightCaretImageView)
        rightButton.isEnabled = false
        addSubview(rightButton)
        rightButton.isHidden = true
        rightButton.isAccessibilityElement = true
        rightButton.accessibilityLabel = NSLocalizedString("Next account", comment: "")
        
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.clipsToBounds = true
        addSubview(scrollView)

        pageControl.pageIndicatorTintColor = tintWhite ? UIColor.white.withAlphaComponent(0.43) : .accentGray
        pageControl.currentPageIndicatorTintColor = tintWhite ? .white : .actionBlue
        pageControl.addTarget(self, action: #selector(onPageControlTap(sender:)), for: .valueChanged)
        addSubview(pageControl)
        
        loadingIndicator.isHidden = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.isStormMode = StormModeStatus.shared.isOn
        addSubview(loadingIndicator)
        loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        addSubview(shadowView)
        shadowView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        shadowView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        shadowView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        shadowView.topAnchor.constraint(equalTo: bottomAnchor).isActive = true
        shadowView.addShadow(color: .black, opacity: 0.15, offset: .zero, radius: 3)

        leftButton.addTarget(self, action: #selector(leftPressed), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(rightPressed), for: .touchUpInside)
        
        if tintWhite {
            backgroundColor = .primaryColorAccountPicker
            shadowView.backgroundColor = .primaryColorAccountPicker
        } else {
            backgroundColor = .white
            shadowView.backgroundColor = .white
        }
        
        if StormModeStatus.shared.isOn {
            backgroundColor = UIColor.black.withAlphaComponent(0.1)
        }
    }
    
    @objc func rightPressed() {
        pageControl.currentPage += 1
        onPageControlTap(sender: pageControl)
    }
    
    @objc func leftPressed() {
        pageControl.currentPage -= 1
        onPageControlTap(sender: pageControl)
    }
    
    func setLoading(_ loading: Bool) {
        loadingIndicator.isHidden = !loading
    }

    func loadAccounts() {
        if loadedAccounts { return } // Prevent calling this multiple times
        loadedAccounts = true

        currentIndex = AccountsStore.shared.currentIndex ?? 0
        var pagedAccounts: [Account] = accounts

        if accounts.count > 1 && accounts.count <= maxAccounts {
            pageControl.numberOfPages = accounts.count
        } else {
            pagedAccounts = Array(accounts.prefix(maxAccounts))
            pageControl.isHidden = true
        }

        pageViews.removeAll()
        if accounts.count <= maxAccounts && !isMultiPremise {
            for account in pagedAccounts {
                addAccountToScrollView(account)
            }
        } else { // Advanced Account Picker
            pageControl.isHidden = true
            addAccountToScrollView(currentAccount, advancedPicker: true)
        }
        
        if shouldScroll {
            accessibilityElements = [scrollView, pageControl, leftButton, rightButton]
            leftButton.isHidden = false
            rightButton.isHidden = false
        } else {
            leftButton.isHidden = true
            rightButton.isHidden = true
        }

        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }
    
    private func addAccountToScrollView(_ account: Account, advancedPicker: Bool = false) {
        let commercialUser = !account.isResidential
        
        // Setting the page view to this initial size avoids upfront autolayout warnings
        let pageView = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 60))
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
        
        accountStackView.centerXAnchor.constraint(equalTo: pageView.centerXAnchor, constant: 0).isActive = true
        accountStackView.topAnchor.constraint(equalTo: pageView.topAnchor, constant: 10).isActive = true
        accountStackView.leadingAnchor.constraint(greaterThanOrEqualTo: pageView.leadingAnchor).isActive = true
        accountStackView.trailingAnchor.constraint(lessThanOrEqualTo: pageView.trailingAnchor).isActive = true
        addressLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 220).isActive = true
        
        leftCaretImageView.image = tintWhite ? #imageLiteral(resourceName: "ic_caret_white_left"):#imageLiteral(resourceName: "ic_caret_left")
        rightCaretImageView.image = tintWhite ? #imageLiteral(resourceName: "ic_caret_white"):#imageLiteral(resourceName: "ic_caret")
        
        scrollView.addSubview(pageView)
        
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
        let vc = AdvancedAccountPickerViewController()
        vc.delegate = self
        vc.accounts = accounts
        if let parentVc = parentViewController {
            if UIDevice.current.userInterfaceIdiom == .pad {
                vc.modalPresentationStyle = .formSheet
                parentVc.present(vc, animated: true, completion: nil)
            } else {
                parentVc.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    @objc func onPageControlTap(sender: UIPageControl) {
        scrollView.scrollRectToVisible(CGRect(x: scrollView.frame.size.width * CGFloat(pageControl.currentPage), y: 0, width: scrollView.frame.size.width, height: intrinsicContentSize.height), animated: true)
        currentIndex = pageControl.currentPage
    }
    
    func updateCurrentAccount() {
        currentIndex = AccountsStore.shared.currentIndex
        if pageViews.count > 0 {
            if let index = accounts.firstIndex(where: { $0 == currentAccount}) {
                pageControl.currentPage = index
                scrollView.scrollRectToVisible(CGRect(x: scrollView.frame.size.width * CGFloat(pageControl.currentPage), y: 0, width: scrollView.frame.size.width, height: intrinsicContentSize.height), animated: false)
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
        currentIndex = accounts.firstIndex(of: account)
        
        updateAdvancedAccountPicker(account)
        
        delegate?.accountPickerDidChangeAccount(self)
    }
}

extension AccountPicker: UIScrollViewDelegate {

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)

        if currentPage != pageControl.currentPage {
            currentIndex = currentPage
        }
    }

}
