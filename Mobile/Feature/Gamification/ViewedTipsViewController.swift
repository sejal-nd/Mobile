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
    var viewedTips: [GameTip]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Viewed Tips", comment: "")

        emptyStateLabel.textColor = .middleGray
        emptyStateLabel.font = OpenSans.regular.of(textStyle: .headline)
        emptyStateLabel.text = NSLocalizedString("You haven't viewed any tips yet.", comment: "")
        
        reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func reloadData() {
        viewedTipTuples = coreDataManager.getViewedTips(accountNumber: AccountsStore.shared.currentAccount.accountNumber)
        viewedTips = viewedTipTuples.map({ GameTaskStore.shared.tipWithId($0.0) })
        if viewedTips.isEmpty {
            tableView.isHidden = true
        } else {
            emptyStateView.isHidden = true
        }
        
        GameTaskStore.shared.fetchTipIdsForPendingReminders { [weak self] tipIds in
            self?.reminderTipIds = tipIds
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
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
