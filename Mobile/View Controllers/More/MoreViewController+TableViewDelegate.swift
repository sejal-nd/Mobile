//
//  MoreViewController+TableViewDelegate.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/13/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

extension MoreViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return 4
        case 2:
            return 3
        default:
            return 0
        }
    }
    
    /// We Use row height to show/hide cells
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                return 60
            case 1:
                return 60
            default:
                return 60
            }
        case 1:
            switch indexPath.row {
            case 0:
                return 60
            case 1:
                return viewModel.isBiometryEnabled() ? 60 : 0
            case 2:
                return Environment.shared.opco == .bge ? 60 : 0
            case 3:
                return Environment.shared.opco == .peco ? 60 : 0
            default:
                return 60
            }
        case 2:
            switch indexPath.row {
            case 0:
                return 60
            case 1:
                return 0
            case 2:
                return 60
            default:
                return 60
            }
        default:
            return 60
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TitleTableViewCell", for: indexPath) as? TitleTableViewCell else { return UITableViewCell() }
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                cell.configure(image: UIImage(named: "ic_morealerts"), text: "My Alerts")
            case 1:
                cell.configure(image: UIImage(named: "ic_moreupdates"), text: "Updates")
            default:
                return UITableViewCell()
            }
        case 1:
            switch indexPath.row {
            case 0:
                cell.configure(image: UIImage(named: "ic_morepassword"), text: "Change Password")
                
                if !viewModel.isBiometryEnabled() && Environment.shared.opco == .comEd { // we may also need to handle bge with only 1 account
                    cell.separatorInset = UIEdgeInsets.zero
                    cell.preservesSuperviewLayoutMargins = false
                }
            case 1:
                cell.configure(image: UIImage(named: "ic_morecontact"), text: "Contact Us") // TODO NEW CELL
            case 2:
                cell.configure(image: UIImage(named: "ic_moredefault"), text: "Set Default Account")
            case 3:
                cell.configure(image: UIImage(named: "ic_morerelease"), text: "Release of Info")
            default:
                return UITableViewCell()
            }
        case 2:
            switch indexPath.row {
            case 0:
                cell.configure(image: UIImage(named: "ic_morecontact"), text: "Contact Us")
            case 1:
                cell.configure(image: UIImage(named: "ic_morevideo"), text: "Billing Tutorial Videos")
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
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "alertsSegue", sender: nil)
            case 1:
                performSegue(withIdentifier: "updatesSegue", sender: nil)
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "changePasswordSegue", sender: nil)
            case 1:
                break
            case 2:
                performSegue(withIdentifier: "defaultAccountSegue", sender: nil) // unknown
            case 3:
                performSegue(withIdentifier: "releaseOfInfoSegue", sender: nil) // unknown
            default:
                break
            }
        case 2:
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "contactUsSegue", sender: nil)
            case 1:
                break
            case 2:
                performSegue(withIdentifier: "termsPoliciesSegue", sender: nil)
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
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "TitleTableViewHeaderView") as? TitleTableViewHeaderView else { return nil }
        
        switch section {
        case 0:
            headerView.configure(text: "Notifications")
        case 1:
            headerView.configure(text: "Settings")
        case 2:
            headerView.configure(text: "Help & Support")
        default:
            break
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 28
    }
    
}
