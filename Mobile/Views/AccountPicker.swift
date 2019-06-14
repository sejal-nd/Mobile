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
    
    weak var delegate: AccountPickerDelegate?
    weak var parentViewController: UIViewController?

    let scrollView = UIScrollView(frame: .zero)
    let loadingIndicator = LoadingIndicator(frame: .zero)
    let shadowView = UIView().usingAutoLayout()
    
    var accounts: [Account]! {
        get { return AccountsStore.shared.accounts }
    }
    
    var currentIndex: Int! {
        didSet {
            AccountsStore.shared.currentIndex = currentIndex
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
        return false
    }
    
    private var loadedAccounts = false
    
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
        
        if shouldScroll {
            scrollView.frame = CGRect(x: 40, y: 0, width: frame.size.width - 80, height: intrinsicContentSize.height)
        } else {
            scrollView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: intrinsicContentSize.height)
        }
        
        if let button = advancedAccountButton {
            button.frame = bounds
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
        
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.clipsToBounds = true
        addSubview(scrollView)
        
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
    
    func setLoading(_ loading: Bool) {
        loadingIndicator.isHidden = !loading
    }

    func loadAccounts() {
        if loadedAccounts { return } // Prevent calling this multiple times
        loadedAccounts = true

        currentIndex = AccountsStore.shared.currentIndex ?? 0
        
        addAccountToScrollView(currentAccount, advancedPicker: true)
        
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }
    
    private func addAccountToScrollView(_ account: Account, advancedPicker: Bool = false) {
        let commercialUser = !account.isResidential
        
        // Setting the page view to this initial size avoids upfront autolayout warnings
        let pageView = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 60))
        
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
    
    func updateCurrentAccount() {
        currentIndex = AccountsStore.shared.currentIndex
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
