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

class AccountPicker: UIControl {
    
    @IBOutlet weak var view: UIView!
    
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var singleAccountView: UIView!
    @IBOutlet weak var multiAccountView: UIView!
    
    @IBOutlet var iconImageViews: [UIImageView]!
    @IBOutlet var accountNumberLabels: [UILabel]!
    @IBOutlet var addressLabels: [UILabel]!
    @IBOutlet weak var switchAccountImageView: UIImageView!
    
    weak var delegate: AccountPickerDelegate?
    weak var parentViewController: UIViewController?
    
    var accounts: [Account]! {
        get { return AccountsStore.shared.accounts }
    }
    
    /* We keep track of the current account so that we can avoid reloads when the user
       selects the same account again...see refresh() */
    var currentAccount: Account?
    
    private var isMultiPremise: Bool {
        return accounts?.contains { $0.isMultipremise } ?? false
    }
    
    @IBInspectable var tintWhite: Bool = false {
        didSet {
            for label in accountNumberLabels {
                label.textColor = tintWhite ? .white: .deepGray
            }
            for label in addressLabels {
                label.textColor = tintWhite ? .white: .deepGray
            }
            
            switchAccountImageView.image = tintWhite ? UIImage(named: "ic_switchaccount")! :
                UIImage(named: "ic_switchaccount_blue")
            
            let borderWhiteAlpha: CGFloat = StormModeStatus.shared.isOn ? 0.3 : 0.5
            let borderColor = tintWhite ? UIColor.white.withAlphaComponent(borderWhiteAlpha) : .accentGray
            addBottomBorder(color: borderColor, width: 1)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 0, height: 50)
    }

    func commonInit() {
        Bundle.main.loadNibNamed(AccountPicker.className, owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        addSubview(view)
        
        isAccessibilityElement = true
        accessibilityTraits = .button
        clipsToBounds = true
        backgroundColor = .clear
        view.backgroundColor = .clear
        
        multiAccountView.isHidden = true // Hide one so that intrinsic height is 50
        loadingIndicator.isHidden = true
        loadingIndicator.isStormMode = StormModeStatus.shared.isOn
        
//        if StormModeStatus.shared.isOn {
//            backgroundColor = UIColor.black.withAlphaComponent(0.1)
//        }
        
        addTarget(self, action: #selector(onAccountPickerPress), for: .touchUpInside)
        
        for label in accountNumberLabels {
            label.font = SystemFont.semibold.of(textStyle: .subheadline)
        }
        for label in addressLabels {
            label.font = SystemFont.regular.of(textStyle: .subheadline)
        }

    }
    
    func setLoading(_ loading: Bool) {
        loadingIndicator.isHidden = !loading
        stackView.isHidden = loading
    }

    func refresh() {
        if currentAccount != AccountsStore.shared.currentAccount {
            currentAccount = AccountsStore.shared.currentAccount
            delegate?.accountPickerDidChangeAccount(self)
            
            let isSingleAccount = accounts.count == 1 && !isMultiPremise
            multiAccountView.isHidden = isSingleAccount
            singleAccountView.isHidden = !isSingleAccount
            
            guard let account = currentAccount else { return }
            
            let icon: UIImage
            let a11yDescription: String
            switch (!account.isResidential, tintWhite) {
            case (true, true):
                icon = UIImage(named: "ic_commercial_mini_white")!
                a11yDescription = NSLocalizedString("Commercial account", comment: "")
            case (true, false):
                icon = UIImage(named: "ic_commercial_mini")!
                a11yDescription = NSLocalizedString("Commercial account", comment: "")
            case (false, true):
                icon = UIImage(named: "ic_residential_mini_white")!
                a11yDescription = NSLocalizedString("Residential account", comment: "")
            case (false, false):
                icon = UIImage(named: "ic_residential_mini")!
                a11yDescription = NSLocalizedString("Residential account", comment: "")
            }
            setIconImage(icon, accessibilityLabel: a11yDescription)
            
            let finaledString = NSLocalizedString(Environment.shared.opco == .bge ? "Stopped" : "Finaled", comment: "")
            let linkedString = NSLocalizedString("Linked", comment: "")
            
            let accountNumberText = "\(account.accountNumber) " +
            "\(account.isFinaled ? "(\(finaledString))" : account.isLinked ? "(\(linkedString))":"")"
            
            setAccountNumberText(accountNumberText, accessibilityLabel: String.localizedStringWithFormat("Account number %@", accountNumberText))
            
            if let currPremise = account.currentPremise, let address = currPremise.addressGeneral {
                setAddressText(address, accessibilityLabel: String.localizedStringWithFormat("Street address %@", address))
            } else if let address = account.address {
                setAddressText(address, accessibilityLabel: String.localizedStringWithFormat("Street address %@", address))
            } else {
                setAddressText(" ", accessibilityLabel: "")
            }
        }
    }
    
    @objc func onAccountPickerPress() {
        // Single, non-multipremise accounts
        guard accounts.count > 1 || isMultiPremise else { return }
        
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
    
    // MARK: - IBOutletCollection Helpers
    
    func setIconImage(_ image: UIImage, accessibilityLabel: String) {
        for imageView in iconImageViews {
            imageView.image = image
            imageView.accessibilityLabel = accessibilityLabel
        }
    }
    
    func setAccountNumberText(_ text: String, accessibilityLabel: String) {
        for label in accountNumberLabels {
            label.text = text
            label.accessibilityLabel = accessibilityLabel
        }
    }
    
    func setAddressText(_ text: String, accessibilityLabel: String) {
        for label in addressLabels {
            label.text = text
            label.accessibilityLabel = accessibilityLabel
        }
    }
    
}

extension AccountPicker: AdvancedAccountPickerViewControllerDelegate {
    func advancedAccountPickerViewController(_ advancedAccountPickerViewController: AdvancedAccountPickerViewController, didSelectAccount account: Account) {
        AccountsStore.shared.currentIndex = accounts.firstIndex(of: account)
        refresh()
    }
}
