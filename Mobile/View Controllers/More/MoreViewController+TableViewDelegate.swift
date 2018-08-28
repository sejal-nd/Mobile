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
                return viewModel.isDeviceBiometricCompatible() ? 60 : 0
            case 2:
                guard AccountsStore.shared.accounts != nil else { return 0 }
                return (Environment.shared.opco == .bge && AccountsStore.shared.accounts.count > 1) ? 60 : 0
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TitleTableViewCell.className) as? TitleTableViewCell else { return UITableViewCell() }
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                cell.configure(image: #imageLiteral(resourceName: "ic_morealerts"), text: NSLocalizedString("My Alerts", comment: ""))
            case 1:
                cell.configure(image: #imageLiteral(resourceName: "ic_moreupdates"), text: NSLocalizedString("News and Updates", comment: ""))
            default:
                return UITableViewCell()
            }
        case 1:
            switch indexPath.row {
            case 0:
                cell.configure(image: #imageLiteral(resourceName: "ic_morepassword"), text: NSLocalizedString("Change Password", comment: ""))
            case 1:
                guard let toggleCell = tableView.dequeueReusableCell(withIdentifier: ToggleTableViewCell.className) as? ToggleTableViewCell else { return UITableViewCell() }
                
                toggleCell.configure(viewModel: viewModel, tag: indexPath.row)
                toggleCell.toggle.addTarget(self, action: #selector(toggleBiometrics), for: .valueChanged)
                return toggleCell
            case 2:
                cell.configure(image: #imageLiteral(resourceName: "ic_moredefault"), text: NSLocalizedString("Set Default Account", comment: ""))
            case 3:
                cell.configure(image: #imageLiteral(resourceName: "ic_morerelease"), text: NSLocalizedString("Release of Info", comment: ""))
            default:
                return UITableViewCell()
            }
        case 2:
            switch indexPath.row {
            case 0:
                cell.configure(image: #imageLiteral(resourceName: "ic_morecontact"), text: NSLocalizedString("Contact Us", comment: ""))
            case 1:
                cell.configure(image: #imageLiteral(resourceName: "ic_morevideo"), text: NSLocalizedString("Billing Tutorial Videos", comment: ""))
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
            case 2:
                performSegue(withIdentifier: "defaultAccountSegue", sender: nil)
            case 3:
                performSegue(withIdentifier: "releaseOfInfoSegue", sender: nil)
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
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TitleTableViewHeaderView.className) as? TitleTableViewHeaderView else { return nil }
        
        switch section {
        case 0:
            headerView.configure(text: NSLocalizedString("Notifications", comment: ""))
        case 1:
            headerView.configure(text: NSLocalizedString("Settings", comment: ""))
        case 2:
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
