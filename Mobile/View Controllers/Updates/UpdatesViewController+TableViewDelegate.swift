//
//  UpdatesViewController+TableViewDelegate.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/10/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

extension UpdatesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.currentOpcoUpdates.value?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UpdatesTableViewCell", for: indexPath) as? UpdatesTableViewCell else { return UITableViewCell() }
        
        cell.titleLabel.text = viewModel.currentOpcoUpdates.value![indexPath.section].title
        cell.detailLabel.text = viewModel.currentOpcoUpdates.value![indexPath.section].message
        
        cell.innerContentView.accessibilityLabel = "\(cell.titleLabel.text ?? ""): \(cell.detailLabel.text ?? "")"
        
        return cell
    }
    
    // This is not getting called
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "opcoUpdateDetailSegue", sender: indexPath)
    }
    
}
