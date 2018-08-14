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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UpdatesTableViewCell.className, for: indexPath) as? UpdatesTableViewCell, let opcoUpdates = viewModel.currentOpcoUpdates.value else { return UITableViewCell() }

        cell.configure(title: opcoUpdates[indexPath.row].title, detail: opcoUpdates[indexPath.row].message)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "UpdatesDetailSegue", sender: indexPath)
    }
    
}
