//
//  AccountListRow.swift
//  Mobile
//
//  Created by Joseph Erlandson on 6/14/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

protocol PremiseSelectDelegate: class {
    func didSelectPremise(premiseIndexPath: IndexPath, accountIndexPath: IndexPath)
}

class AccountListRow: UITableViewCell {
    enum CellState {
        case expanded
        case collapsed
    }
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var checkmarkImageView: UIImageView!
    @IBOutlet weak var accountImageView: UIImageView!
    @IBOutlet weak var accountNumber: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var caretImageView: UIImageView!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    /// Used for calculating tableView Height: Objects * cellHeight
    private let cellHeight: CGFloat = 60
    
    /// Passes row selection action into parent view controller
    weak var delegate: PremiseSelectDelegate?
    
    /// Index of selected account
    var parentIndexPath: IndexPath!
    
    private var account: Account!
    
    /// Enforces single cell selection (of premises)
    var premiseSelectedIndexPath: IndexPath?
    
    /// State of tableView
    var cellState: CellState = .collapsed
    
    
    // MARK: - View Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Syle View
        accountNumber.textColor = .blackText
        accountNumber.font = .headline
        addressLabel.textColor = .middleGray
        addressLabel.font = .footnote
    }
    
    
    // MARK: - Action
    
    /// Selection at the account level: Expand TableView if `isMultipremise`
    func didSelect() {
        guard account.isMultipremise else { return }
        
        FirebaseUtility.logEvent(.accountPicker(parameters: [.expand_premise]))
        
        // Toggle cellState & change constraints
        switch cellState {
        case .expanded:
            cellState = .collapsed
            tableViewHeightConstraint.constant = 0
        case .collapsed:
            cellState = .expanded
            tableViewHeightConstraint.constant = CGFloat(integerLiteral: account.premises.count) * cellHeight
        }
        
        tableView.reloadData() // So we can update the a11y settings per-cell
        
        // Animate constraint change
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.stackView.layoutIfNeeded()
        }
        
        // Animate carrot image
        UIView.transition(with: caretImageView, duration: 0.2, options: .transitionCrossDissolve, animations: { [weak self] in
            self?.caretImageView.image = self?.cellState == .collapsed ? #imageLiteral(resourceName: "ic_caret_down.pdf") : #imageLiteral(resourceName: "ic_caret_up.pdf")
        }, completion: nil)
    }
    
    
    // MARK: - Helper
    
    func configure(withAccount account: Account,
                   indexPath: IndexPath,
                   selectedIndexPath: IndexPath?,
                   delegate: PremiseSelectDelegate, hasCalledStopService: Bool = false) {
        self.account = account
        self.delegate = delegate
        self.parentIndexPath = indexPath
        
        // Mutli Premise
        accountNumber.textColor = .blackText
        if account.isMultipremise {
            configureTableView()
            
            selectionStyle = .none
            caretImageView.isHidden = false
            
            // Address Label
            addressLabel.text = "Multi-Premise Account"
            addressLabel.accessibilityLabel = String(format: NSLocalizedString("Multi-Premise Account", comment: ""))
        } else {
            tableView.isHidden = true
            
            selectionStyle = .default
            
            // Cell Selection Color
            let backgroundView = UIView()
            backgroundView.backgroundColor = .softGray
            selectedBackgroundView = backgroundView
            
            caretImageView.isHidden = true
            
            // Address Label
            addressLabel.text = account.address
            if let address = account.address {
                addressLabel.accessibilityLabel = String(format: NSLocalizedString("Street address: %@.", comment: ""), address)
            } else {
                addressLabel.accessibilityLabel = nil
            }
        }
        
        // Checkmark
        if let selectedIndexPath = selectedIndexPath, indexPath == selectedIndexPath {
            checkmarkImageView.isHidden = false
            checkmarkImageView.accessibilityLabel = NSLocalizedString("Selected", comment: "")
        } else {
            checkmarkImageView.isHidden = true
        }
        checkmarkImageView.isAccessibilityElement = false
        
        let isCommericalUser = !account.isResidential
        
        // Address Icon
        if isCommericalUser {
            accountImageView.image = UIImage(named: "ic_commercial_mini")
            accountImageView.accessibilityLabel = NSLocalizedString("Commercial account", comment: "")
        } else {
            accountImageView.image = UIImage(named: "ic_residential_mini")
            accountImageView.accessibilityLabel = NSLocalizedString("Residential account", comment: "")
        }
        accountImageView.isAccessibilityElement = false
        
        // Account Number
        let accountNumberText: String
        if account.isDefault {
            accountNumberText = "\(account.displayName) (Default)"
        } else if account.isFinaled {
            let status = Configuration.shared.opco.isPHI ? "(Inactive)" : "(Finaled)"
            accountNumberText = "\(account.displayName) \(status)"
            if FeatureFlagUtility.shared.bool(forKey: .hasAuthenticatedISUM), Configuration.shared.opco.rawValue == "BGE" && hasCalledStopService {
                addressLabel.text = ""
                accountNumber.textColor = UIColor(red: 74.0/255.0, green: 74.0/255.0, blue: 74.0/255.0, alpha: 0.5)
                accountImageView.image = UIImage(named: "ic_residential_mini_1")
                self.isUserInteractionEnabled = false
            } else {
                self.isUserInteractionEnabled = true;
            }
        } else if account.isLinked {
            accountNumberText = "\(account.displayName) (Linked)"
        } else {
            if FeatureFlagUtility.shared.bool(forKey: .hasAuthenticatedISUM), Configuration.shared.opco.rawValue == "BGE", let accountStatusCode = account.accountStatusCode, accountStatusCode == "Inactive" {
                accountNumberText = "\(account.displayName) (\(accountStatusCode))"
                addressLabel.text = ""
                if hasCalledStopService {
                    accountNumber.textColor = UIColor(red: 74.0/255.0, green: 74.0/255.0, blue: 74.0/255.0, alpha: 0.5)
                    accountImageView.image = UIImage(named: "ic_residential_mini_1")
                }
                self.isUserInteractionEnabled = hasCalledStopService ? false : true;
            } else {
                self.isUserInteractionEnabled = true;
                accountNumberText = account.displayName
            }
        }
        
        accountNumber.text = accountNumberText
        accountNumber.accessibilityLabel = String(format: NSLocalizedString("Account number %@", comment: ""), accountNumberText)
        
        // Accessibility
        self.accessibilityLabel = "\(checkmarkImageView.accessibilityLabel ?? ""), \(accountImageView.accessibilityLabel ?? ""), \(accountNumber.accessibilityLabel ?? ""), \(addressLabel.accessibilityLabel ?? "")"
    }
    
    private func configureTableView() {
        let premiseListCell = UINib(nibName: PremiseListRow.className, bundle: nil)
        tableView.register(premiseListCell, forCellReuseIdentifier: PremiseListRow.className)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // Determine selected indexPath
        guard let currentPremise = AccountsStore.shared.currentAccount.currentPremise,
            let row = account.premises.firstIndex(of: currentPremise) else { return }
        premiseSelectedIndexPath = IndexPath(row: row, section: 0)
        tableView.reloadData()
        
        // Start TableView Collapsed
        tableView.isHidden = false
        cellState = .collapsed
    }
}


// MARK: - Table View Delegate

extension AccountListRow: UITableViewDelegate {
    /// Note: Can only be called if account is multipremise
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Single Cell Selection
        if indexPath == premiseSelectedIndexPath { return }
        
        // Toggle new cehckmark on
        guard let newCell = tableView.cellForRow(at: indexPath) as? PremiseListRow else { return }
        if newCell.checkmarkImageView.isHidden {
            newCell.checkmarkImageView.isHidden = false
        }
        
        // Toggle old checkmark off
        
        // Remove checkmark from premise table view
        if let unwrappedSelectedIndexPath = premiseSelectedIndexPath,
            let oldCell = tableView.cellForRow(at: unwrappedSelectedIndexPath) as? PremiseListRow {
            if !oldCell.checkmarkImageView.isHidden {
                oldCell.checkmarkImageView.isHidden = true
            }
        }

        premiseSelectedIndexPath = indexPath
        
        // Select parent checkmark.
        delegate?.didSelectPremise(premiseIndexPath: indexPath, accountIndexPath: parentIndexPath)
    }
}


// MARK: - Table View Data Source

extension AccountListRow: UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return account.premises.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PremiseListRow.className, for: indexPath) as! PremiseListRow
        let premise = account.premises[indexPath.row]
        cell.configureWithPremise(premise, indexPath: indexPath, selectedIndexPath: premiseSelectedIndexPath)
        
        cell.isAccessibilityElement = tableViewHeightConstraint.constant > 0
        cell.accessibilityElementsHidden = tableViewHeightConstraint.constant == 0
                
        return cell
    }
}
