//
//  ViewedTipsViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/20/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class ViewedTipsViewController: UIViewController {
    
    let coreDataManager = GameCoreDataManager()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var emptyStateLabel: UILabel!
    
    var reminderTipIds = [String]()
    var viewedTipTuples: [(String, Bool)]!
    var viewedTips = [GameTip]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Viewed Tips", comment: "")

        emptyStateLabel.textColor = .middleGray
        emptyStateLabel.font = OpenSans.regular.of(textStyle: .headline)
        emptyStateLabel.text = NSLocalizedString("You haven't viewed any tips yet.", comment: "")
        
        tableView.tableFooterView = UIView() // To hide empty row separators
        
        reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func reloadData() {
        GameTaskStore.shared.fetchTipIdsForPendingReminders { [weak self] tipIds in
            guard let self = self else { return }

            self.reminderTipIds = tipIds
            self.viewedTipTuples = self.coreDataManager.getViewedTips(accountNumber: AccountsStore.shared.currentAccount.accountNumber).sorted(by: { (a, b) -> Bool in
                let aIsReminder = tipIds.contains(a.0)
                let aIsFavorite = a.1
                let bIsReminder = tipIds.contains(b.0)
                let bIsFavorite = b.1
                
                if (aIsFavorite && aIsReminder) && (!bIsFavorite || !bIsReminder) { return true }
                if aIsFavorite && !bIsFavorite { return true }
                if aIsReminder && !bIsReminder { return true }
                
                return false
            })
            self.viewedTips = self.viewedTipTuples.compactMap({ GameTaskStore.shared.tipWithId($0.0) })
            
            if self.viewedTips.isEmpty {
                self.tableView.isHidden = true
            } else {
                self.emptyStateView.isHidden = true
            }
            self.tableView.reloadData()
        }
    }
    
}

extension ViewedTipsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewedTips.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ViewedTipCell", for: indexPath) as! ViewedTipTableViewCell
        
        let tip = viewedTips[indexPath.row]
        
        cell.titleLabel.text = tip.title
        cell.reminderImageView.isHidden = !reminderTipIds.contains(tip.id)
        if let tipTuple = viewedTipTuples.first(where: { tip.id == $0.0 }), tipTuple.1 {
            cell.favoriteImageView.isHidden = false
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let tip = viewedTips[indexPath.row]
        let tipVc = GameTipViewController.create(withTip: tip)
        tipVc.onUpdate = { [weak self] in
            self?.reloadData()
        }
        present(tipVc, animated: true, completion: nil)
    }
}
