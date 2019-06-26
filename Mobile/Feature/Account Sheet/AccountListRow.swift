//
//  AccountListRow.swift
//  Mobile
//
//  Created by Joseph Erlandson on 6/14/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

protocol PremiseSelectDelegate: class {
    func didSelectPremise(at indexPath: IndexPath)
}

class AccountListRow: UITableViewCell {
    
    enum CellState {
        case expanded
        case collapsed
    }
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var checkMarkImageView: UIImageView!
    @IBOutlet weak var accountImageView: UIImageView!
    @IBOutlet weak var accountNumber: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var carrotImageView: UIImageView!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    weak var delegate: PremiseSelectDelegate?
    var parentIndexPath: IndexPath!
    
    private var account: Account!
    
    var premiseSelectedIndexPath: IndexPath?
    
    var cellState: CellState = .collapsed
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        accountNumber.textColor = .blackText
        accountNumber.font = SystemFont.regular.of(textStyle: .headline)
        addressLabel.textColor = .middleGray
        addressLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        let premiseListCell = UINib(nibName: PremiseListRow.className, bundle: nil)
        tableView.register(premiseListCell, forCellReuseIdentifier: PremiseListRow.className)
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func didPress() {
        guard account.isMultipremise else { return }
        
        switch cellState {
        case .expanded:
            cellState = .collapsed
            tableViewHeightConstraint.constant = 0
        case .collapsed:
            cellState = .expanded
            tableViewHeightConstraint.constant = CGFloat(integerLiteral: account.premises.count) * 60
        }
        
        UIView.animate(withDuration: 0.3) { [unowned self] in
            self.stackView.layoutIfNeeded()
        }
        
        UIView.transition(with: carrotImageView, duration: 0.2, options: .transitionCrossDissolve, animations: { [unowned self] in
            self.carrotImageView.image = self.cellState == .collapsed ? UIImage(named: "ic_carat_down") : UIImage(named: "ic_carat_up")
            }, completion: nil)
    }
    
    func configure(withAccount account: Account,
                   indexPath: IndexPath,
                   selectedIndexPath: IndexPath?,
                   delegate: PremiseSelectDelegate) {
        self.account = account

        self.delegate = delegate

        
        // Mutli Premise
        if account.isMultipremise {
//            print("premise count: \(account.premises.count)")
            tableView.isHidden = false
            
            parentIndexPath = indexPath
            // determine selected indexPath
            guard let currentPremise = AccountsStore.shared.currentAccount.currentPremise,
                  let row = account.premises.firstIndex(of: currentPremise) else { return }
            premiseSelectedIndexPath = IndexPath(row: row, section: 0)
            tableView.reloadData()
            
            cellState = .collapsed
            
            // Start TableView Collapsed
            self.layoutIfNeeded()
            tableViewHeightConstraint.constant = 0
            self.layoutIfNeeded()
            
            selectionStyle = .none
            carrotImageView.isHidden = false
        } else {
            tableView.isHidden = true
            
            selectionStyle = .default
            
            carrotImageView.isHidden = true
        }
        
        // Checkmark
        if let selectedIndexPath = selectedIndexPath, indexPath == selectedIndexPath {
            checkMarkImageView.isHidden = false
            checkMarkImageView.accessibilityLabel = NSLocalizedString("Selected", comment: "")
        } else {
            checkMarkImageView.isHidden = true
        }
        checkMarkImageView.isAccessibilityElement = false
        
        let isCommericalUser = !account.isResidential
        
        // Determine Address Icon
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
            accountNumberText = "\(account.accountNumber) (Default)"
        } else if account.isFinaled {
            accountNumberText = "\(account.accountNumber) (Finaled)"
        } else if account.isLinked {
            accountNumberText = "\(account.accountNumber) (Linked)"
        } else {
            accountNumberText = account.accountNumber
        }
        
        accountNumber.text = account.accountNumber
        accountNumber.accessibilityLabel = String(format: NSLocalizedString("Account number %@", comment: ""), accountNumberText)
        
        // Address Label
        addressLabel.text = account.address
        if let address = account.address {
            addressLabel.accessibilityLabel = String(format: NSLocalizedString("Street address: %@.", comment: ""), address)
        } else {
            addressLabel.accessibilityLabel = nil
        }
        
        self.accessibilityLabel = "\(checkMarkImageView.accessibilityLabel ?? ""), \(accountImageView.accessibilityLabel ?? ""), \(accountNumber.accessibilityLabel ?? ""), "
    }
}


// MARK: - Table View Delegate

extension AccountListRow: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Single Cell Selection
        if indexPath == premiseSelectedIndexPath {
            return
        }
        
        // toggle old one off and the new one on
        guard let newCell = tableView.cellForRow(at: indexPath) as? PremiseListRow else { return }
        if newCell.checkMarkImageView.isHidden {
            newCell.checkMarkImageView.isHidden = false
        }
        
        guard let unwrappedSelectedIndexPath = premiseSelectedIndexPath, let oldCell = tableView.cellForRow(at: unwrappedSelectedIndexPath) as? PremiseListRow else { return }
        if !oldCell.checkMarkImageView.isHidden {
            oldCell.checkMarkImageView.isHidden = true
        }
        
        premiseSelectedIndexPath = indexPath
        
        // Select parent checkmark.
        delegate?.didSelectPremise(at: parentIndexPath)
    }
}


// MARK: - Table View Data Source

extension AccountListRow: UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return account.premises.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PremiseListRow.className, for: indexPath) as! PremiseListRow
        let premise = account.premises[indexPath.row]
        cell.configureWithPremise(premise, indexPath: indexPath, selectedIndexPath: premiseSelectedIndexPath)
        return cell
    }
}
