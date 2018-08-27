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
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TitleTableViewCell.className, for: indexPath) as? TitleTableViewCell else { return UITableViewCell() }
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                cell.configure(image: #imageLiteral(resourceName: "ic_reportoutage"), text: NSLocalizedString("Report Outage", comment: ""))
            case 1:
                cell.configure(image: #imageLiteral(resourceName: "ic_checkoutage"), text: NSLocalizedString("Check My Outage Status", comment: ""))
            case 2:
                cell.configure(image: #imageLiteral(resourceName: "ic_mapoutage"), text: NSLocalizedString("View Outage Map", comment: ""))
            default:
                return UITableViewCell()
            }
        case 1:
            switch indexPath.row {
            case 0:
                cell.configure(image: #imageLiteral(resourceName: "ic_moreupdates"), text: NSLocalizedString("News and Updates", comment: ""))
            case 1:
                cell.configure(image: #imageLiteral(resourceName: "ic_morecontact"), text: NSLocalizedString("Contact Us", comment: ""))
            case 2:
                cell.configure(image: #imageLiteral(resourceName: "ic_moretos"), text: NSLocalizedString("Policies and Terms", comment: ""))
            default:
                return UITableViewCell()
            }
        default:
            return UITableViewCell()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "reportOutageValidateAccount", sender: nil)
            case 1:
                performSegue(withIdentifier: "checkOutageValidateAccount", sender: nil)
            case 2:
                performSegue(withIdentifier: "outageMapSegue", sender: nil)
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "updatesSegue", sender: nil)
            case 1:
                performSegue(withIdentifier: "contactUsSegue", sender: nil)
            case 2:
                performSegue(withIdentifier: "termPoliciesSegue", sender: nil)
            default:
                break
            }
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TitleTableViewHeaderView.className) as? TitleTableViewHeaderView else { return nil }

        switch section {
        case 0:
            headerView.configure(text: NSLocalizedString("Outage", comment: ""))
        case 1:
            headerView.configure(text: NSLocalizedString("Help & Support", comment: ""))
        default:
            break
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 21
    }
        
}
