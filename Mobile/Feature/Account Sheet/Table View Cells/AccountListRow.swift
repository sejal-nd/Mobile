//
//  AccountListRow.swift
//  Mobile
//
//  Created by Joseph Erlandson on 6/14/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

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
    
    
    private var account: Account!
    
    var cellState: CellState = .collapsed
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        accountNumber.textColor = .orange//.black
        accountNumber.font = SystemFont.regular.of(textStyle: .headline)
        addressLabel.textColor = .middleGray
        addressLabel.font = SystemFont.regular.of(textStyle: .footnote)

        let premiseListCell = UINib(nibName: PremiseListRow.className, bundle: nil)
        tableView.register(premiseListCell, forCellReuseIdentifier: PremiseListRow.className)
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    // we may need to bring distinction to selecting the cell vs selecting the area of the cell.....
    // tap gestures in top areaof cell vs tap gestures in cells of other table view...?
    func didPress() {
        guard account.isMultipremise else { return }
        
        switch cellState {
        case .expanded:
            cellState = .collapsed
            tableViewHeightConstraint.constant = 0
        case .collapsed:
            cellState = .expanded
            tableViewHeightConstraint.constant = tableView.contentSize.height
        }
        
        UIView.animate(withDuration: 0.3) { [unowned self] in
            self.stackView.layoutIfNeeded()
        }

        UIView.transition(with: carrotImageView, duration: 0.2, options: .transitionCrossDissolve, animations: { [unowned self] in
            self.carrotImageView.image = self.cellState == .collapsed ? UIImage(named: "ic_carat_down") : UIImage(named: "ic_carat_up")
        }, completion: nil)
    }
    
    func configure(withAccount account: Account) {
        self.account = account
        
        if account.isMultipremise {
            cellState = .collapsed
            
            // Dyanmic height table view
            self.layoutIfNeeded()
            tableViewHeightConstraint.constant = 0
        }
        
        let commercialUser = !account.isResidential
        
        accountImageView.image = commercialUser ? UIImage(named: "ic_commercial_mini") : UIImage(named: "ic_residential_mini")
        accountImageView.isAccessibilityElement = false
        accountImageView.accessibilityLabel = commercialUser ? NSLocalizedString("Commercial account", comment: "") : NSLocalizedString("Residential account", comment: "")
        addressLabel.text = account.address
        if let address = account.address {
            addressLabel.accessibilityLabel = String(format: NSLocalizedString("Street address: %@.", comment: ""), address)
        } else {
            addressLabel.accessibilityLabel = nil
        }
        
        let accountNumberText: String
        if account.isDefault {
            accountNumberText = "\(account.accountNumber) (Default)"
        } else if account.isFinaled {
            accountNumberText = "\(account.accountNumber) (Finaled)"
            accountImageView.image = commercialUser ? #imageLiteral(resourceName: "ic_commercial_disabled") : #imageLiteral(resourceName: "ic_residential_disabled")
        } else if account.isLinked {
            accountNumberText = "\(account.accountNumber) (Linked)"
        } else {
            accountNumberText = account.accountNumber
        }
        
        accountNumber.text = account.accountNumber
        accountNumber.accessibilityLabel = String(format: NSLocalizedString("Account number %@", comment: ""), accountNumberText)
        
        if account.accountNumber == AccountsStore.shared.currentAccount.accountNumber {
//            separatorInset = UIEdgeInsets(top: 0, left: 90, bottom: 0, right: 0)
//            checkMarkImageView.isHidden = false
            checkMarkImageView.accessibilityLabel = NSLocalizedString("Selected", comment: "")
        } else {
//            separatorInset = UIEdgeInsets(top: 0, left: 67, bottom: 0, right: 0)
//            checkMarkImageView.isHidden = true
        }
        checkMarkImageView.isAccessibilityElement = false
        
        self.accessibilityLabel = "\(checkMarkImageView.accessibilityLabel ?? ""), \(accountImageView.accessibilityLabel ?? ""), \(accountNumber.accessibilityLabel ?? ""), "
        
//        checkMarkImageView.isHidden = account.isMultipremise
        carrotImageView.isHidden = !account.isMultipremise
        
//        selectionStyle = account.isMultipremise ? .none : .default
    }
}


// MARK: - Table View Delegate

extension AccountListRow: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // todo do something.
        print("selected")
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


// MARK: - Table View Data Source

extension AccountListRow: UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return account.premises.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PremiseListRow.className, for: indexPath) as! PremiseListRow
        let premise = account.premises[indexPath.row]
        cell.configureWithPremise(premise)
        return cell
    }
}
