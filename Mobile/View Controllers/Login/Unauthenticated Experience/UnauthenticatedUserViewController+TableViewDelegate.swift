//
//  UnauthenticatedUserViewController+TableViewDelegate.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/9/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

extension UnauthenticatedUserViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TitleTableViewCell", for: indexPath) as? TitleTableViewCell else { return UITableViewCell() }
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                cell.configure(image: UIImage(named: "ic_reportoutage"), text: "Report Outage")
            case 1:
                cell.configure(image: UIImage(named: "ic_checkoutage"), text: "Check My Outage Status")
            case 2:
                cell.configure(image: UIImage(named: "ic_mapoutage"), text: "View Outage Map")
            default:
                return UITableViewCell()
            }
        case 1:
            switch indexPath.row {
            case 0:
                cell.configure(image: UIImage(named: "ic_moreupdates"), text: "News and Updates")
            case 1:
                cell.configure(image: UIImage(named: "ic_morecontact"), text: "Contact Us")
            case 2:
                cell.configure(image: UIImage(named: "ic_moretos"), text: "Policies and Terms")
            default:
                return UITableViewCell()
            }
        default:
            return UITableViewCell()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "TitleTableViewHeaderView") as? TitleTableViewHeaderView else { return nil }

        switch section {
        case 0:
            headerView.configure(text: "Outage")
        case 1:
            headerView.configure(text: "Help & Support")
        default:
            break
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "HairlineFooterView")
    }
    
}
