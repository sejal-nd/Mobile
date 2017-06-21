//
//  MiniWalletViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 6/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class MiniWalletViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableHeaderLabel: UILabel!
    @IBOutlet weak var tableFooterLabel: UILabel!
    
    var tableHeaderLabelText: String? // Passed by whatever VC is presenting MiniWalletViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Select Payment Account", comment: "")
        
        tableView.rx.contentOffset.asDriver()
            .map { $0.y <= 0 ? .white: .softGray }
            .distinctUntilChanged()
            .drive(onNext: { self.tableView.backgroundColor = $0 })
            .addDisposableTo(disposeBag)
        
        tableHeaderLabel.font = OpenSans.semibold.of(textStyle: .headline)
        tableHeaderLabel.textColor = .blackText
        if let headerText = tableHeaderLabelText {
            tableHeaderLabel.text = headerText
        }
        
        tableFooterLabel.font = OpenSans.regular.of(textStyle: .footnote)
        tableFooterLabel.textColor = .blackText
        tableFooterLabel.text = NSLocalizedString("We accept: VISA, MasterCard, Discover, and American Express. Small business customers cannot use VISA.", comment: "")
        
        tableView.estimatedSectionHeaderHeight = 16
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Dynamic sizing for the table header view
        if let headerView = tableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            var headerFrame = headerView.frame
            
            // If we don't have this check, viewDidLayoutSubviews() will get called repeatedly, causing the app to hang.
            if height != headerFrame.size.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                tableView.tableHeaderView = headerView
            }
        }
        
        // Dynamic sizing for the table footer view
        if let footerView = tableView.tableFooterView {
            let height = footerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            var footerFrame = footerView.frame
            
            // If we don't have this check, viewDidLayoutSubviews() will get called repeatedly, causing the app to hang.
            if height != footerFrame.size.height {
                let diff = footerFrame.size.height - height // How much we are about to resize the footerView
                let gap = view.frame.size.height - tableView.contentSize.height // Gap between the table's content height and the bottom of the screen
                footerFrame.size.height = height + gap + diff
                footerView.frame = footerFrame
                tableView.tableFooterView = footerView
            }
        }
    }

}



extension MiniWalletViewController: UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 74
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 23
    }
    
}

extension MiniWalletViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "SectionHeaderCell") as! MiniWalletSectionHeaderCell
        
        if section == 0 {
            cell.label.text = NSLocalizedString("No convenience fee will be applied.", comment: "")
        } else {
            cell.label.text = NSLocalizedString("A $1.50 convenience fee will be applied.", comment: "")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MiniWalletItemCell", for: indexPath) as! MiniWalletTableViewCell
                cell.iconImageView.image = #imageLiteral(resourceName: "opco_bank_mini")
                cell.accountNumberLabel.text = "**** 4321"
                cell.nicknameLabel.text = "SP Checking"
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddAccountCell", for: indexPath) as! MiniWalletAddAccountCell
                cell.iconImageView.image = #imageLiteral(resourceName: "bank_building")
                cell.label.text = NSLocalizedString("Add Bank Account", comment: "")
                return cell
            }
        } else {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MiniWalletItemCell", for: indexPath) as! MiniWalletTableViewCell
                cell.iconImageView.image = #imageLiteral(resourceName: "ic_credit_placeholder_mini")
                cell.accountNumberLabel.text = "**** 1234"
                cell.nicknameLabel.text = "Gray Card"
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddAccountCell", for: indexPath) as! MiniWalletAddAccountCell
                cell.iconImageView.image = #imageLiteral(resourceName: "credit_card")
                cell.label.text = NSLocalizedString("Add Credit/Debit Card", comment: "")
                return cell
            }
        }
    }
    
    
}


