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
    
    var accounts: [Account] {
        get { return AccountsStore.shared.accounts ?? [Account]() }
    }
    
    /* We keep track of the current account so that we can avoid reloads when the user
       selects the same account again...see refresh() */
    var currentAccount: Account?
    
    private var isMultiPremise: Bool {
        return accounts.contains { $0.isMultipremise }
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Need to set border here for it to properly stretch on iPad
        let borderWhiteAlpha: CGFloat = StormModeStatus.shared.isOn ? 0.3 : 0.5
        let borderColor = tintWhite ? UIColor.white.withAlphaComponent(borderWhiteAlpha) : .accentGray
        addBottomBorder(color: borderColor, width: 1)
    }

    private func commonInit() {
        Bundle.main.loadNibNamed(AccountPicker.className, owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        addSubview(view)
        
        isAccessibilityElement = true
                
        clipsToBounds = true
        backgroundColor = .clear
        view.backgroundColor = .clear
        
        multiAccountView.isHidden = true // Hide one so that intrinsic height is 50
        loadingIndicator.isHidden = true
        loadingIndicator.isStormMode = StormModeStatus.shared.isOn
    
        for label in accountNumberLabels {
            label.textColor = .deepGray
            label.font = SystemFont.semibold.of(textStyle: .subheadline)
        }
        for label in addressLabels {
            label.textColor = .deepGray
            label.font = SystemFont.regular.of(textStyle: .subheadline)
        }
        
        addTarget(self, action: #selector(onAccountPickerPress), for: .touchUpInside)
    }
    
    func setLoading(_ loading: Bool) {
        loadingIndicator.isHidden = !loading
        stackView.isHidden = loading
    }
    
    private var shouldRefresh: Bool {
        let storedCurrAccount = AccountsStore.shared.currentAccount
        if currentAccount != storedCurrAccount {
            return true
        }
        if isMultiPremise && currentAccount?.currentPremise != storedCurrAccount.currentPremise {
            return true
        }
        return false
    }

    func refresh(force: Bool = false) {
        if force || shouldRefresh {
            currentAccount = AccountsStore.shared.currentAccount
            
            let isSingleAccount = accounts.count == 1 && !isMultiPremise
            multiAccountView.isHidden = isSingleAccount
            singleAccountView.isHidden = !isSingleAccount
            
            accessibilityTraits = isSingleAccount ? [] : .button
            var a11yDescription = isSingleAccount ? "" : NSLocalizedString("Account picker button.", comment: "")
            
            guard let account = currentAccount else { return }
            
            let icon: UIImage
            let iconA11yLabel: String
            switch (!account.isResidential, tintWhite) {
            case (true, true):
                icon = UIImage(named: "ic_commercial_mini_white")!
                iconA11yLabel = NSLocalizedString("Commercial account", comment: "")
            case (true, false):
                icon = UIImage(named: "ic_commercial_mini")!
                iconA11yLabel = NSLocalizedString("Commercial account", comment: "")
            case (false, true):
                icon = UIImage(named: "ic_residential_mini_white")!
                iconA11yLabel = NSLocalizedString("Residential account", comment: "")
            case (false, false):
                icon = UIImage(named: "ic_residential_mini")!
                iconA11yLabel = NSLocalizedString("Residential account", comment: "")
            }
            setIconImage(icon, accessibilityLabel: iconA11yLabel)
            a11yDescription += iconA11yLabel
            
            let finaledString = NSLocalizedString(Environment.shared.opco == .bge ? "Stopped" : "Finaled", comment: "")
            let linkedString = NSLocalizedString("Linked", comment: "")
            
            let accountNumberText = "\(account.accountNumber) " +
            "\(account.isFinaled ? "(\(finaledString))" : account.isLinked ? "(\(linkedString))":"")"
            
            let accountNumA11yLabel = String.localizedStringWithFormat("Account number %@", accountNumberText)
            setAccountNumberText(accountNumberText, accessibilityLabel: accountNumA11yLabel)
            a11yDescription += ", \(accountNumA11yLabel)"
            
            if let currPremise = account.currentPremise, let address = currPremise.addressGeneral {
                let addressA11yLabel = String.localizedStringWithFormat("Street address %@", address)
                setAddressText(address, accessibilityLabel: addressA11yLabel)
                a11yDescription += ", \(addressA11yLabel)"
            } else if let address = account.address {
                let addressA11yLabel = String.localizedStringWithFormat("Street address %@", address)
                setAddressText(address, accessibilityLabel: addressA11yLabel)
                a11yDescription += ", \(addressA11yLabel)"
            } else {
                setAddressText(" ", accessibilityLabel: "")
            }

            accessibilityLabel = a11yDescription
            delegate?.accountPickerDidChangeAccount(self)
        }
    }
    
    /// Present Bottom Sheet
    @objc private func onAccountPickerPress() {
        FirebaseUtility.logEvent(.accountPicker, parameters: [EventParameter(parameterName: .action, value: .press)])
        
        guard accounts.count > 1 || isMultiPremise,
        let vc = UIStoryboard(name: "AccountSheet", bundle: .main).instantiateInitialViewController() as? AccountSheetViewController else { return }
        vc.delegate = self
        vc.modalPresentationStyle = .overCurrentContext
        if let tabBarController = parentViewController?.tabBarController {
            tabBarController.present(vc, animated: false, completion: nil)
        } else {
            parentViewController?.present(vc, animated: false, completion: nil)
        }
    }
    
    
    // MARK: - IBOutletCollection Helpers
    
    private func setIconImage(_ image: UIImage, accessibilityLabel: String) {
        for imageView in iconImageViews {
            imageView.image = image
            imageView.accessibilityLabel = accessibilityLabel
        }
    }
    
    private func setAccountNumberText(_ text: String, accessibilityLabel: String) {
        for label in accountNumberLabels {
            label.text = text
            label.accessibilityLabel = accessibilityLabel
        }
    }
    
    private func setAddressText(_ text: String, accessibilityLabel: String) {
        for label in addressLabels {
            label.text = text
            label.accessibilityLabel = accessibilityLabel
        }
    }
    
}

extension AccountPicker: AccountSelectDelegate {
    internal func didSelectAccount(_ account: Account, premiseIndexPath: IndexPath?) {
        let selectedAccountIndex = accounts.firstIndex(of: account)
        
        // Set Selected Account
        AccountsStore.shared.currentIndex = selectedAccountIndex
        
        // Set Selected Premise
        if let selectedAccountIndex = selectedAccountIndex,
            let premiseIndexPath = premiseIndexPath {
            AccountsStore.shared.accounts[selectedAccountIndex].currentPremise = AccountsStore.shared.currentAccount.premises[premiseIndexPath.row]
        }

        refresh(force: true)
    }
}
