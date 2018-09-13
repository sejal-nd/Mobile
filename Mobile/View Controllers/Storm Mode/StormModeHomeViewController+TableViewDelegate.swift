//
//  StormModeHomeViewController+TableViewDelegate.swift
//  BGE
//
//  Created by Joseph Erlandson on 9/5/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

extension StormModeHomeViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TitleTableViewCell.className) as? TitleTableViewCell else { return UITableViewCell() }
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                // Must nil check AccountStore, it CAN be nil.  should be an optional AccountStore.shared.currentAccount
                
                if shouldShowOutageButtons {
                    // Populate Content
                    if viewModel.reportedOutage != nil, AccountsStore.shared.currentAccount != nil {
                        // Reported State
                        cell.configure(image: #imageLiteral(resourceName: "ic_check_outage_white"), text: NSLocalizedString("Report Outage", comment: ""), detailText: viewModel.outageReportedDateString, backgroundColor: .black, shouldConstrainWidth: true)
                    } else {
                        // Regular State
                        cell.configure(image: #imageLiteral(resourceName: "ic_reportoutage"), text: NSLocalizedString("Report Outage", comment: ""), backgroundColor: .black, shouldConstrainWidth: true)
                    }
                } else {
                    // Hide Content
                    cell.configure(image: nil, text: nil, detailText: nil, backgroundColor: .black, shouldConstrainWidth: true, shouldHideDisclosure: true, shouldHideSeparator: true)
                }
            case 1:
                if shouldShowOutageButtons {
                    // Populate Content
                    cell.configure(image: #imageLiteral(resourceName: "ic_mapoutage"), text: NSLocalizedString("View Outage Map", comment: ""), backgroundColor: .black, shouldConstrainWidth: true)
                } else {
                    // Hide Content
                    cell.configure(image: nil, text: nil, detailText: nil, backgroundColor: .black, shouldConstrainWidth: true, shouldHideDisclosure: true, shouldHideSeparator: true)
                }
            default:
                return UITableViewCell()
            }
        case 1:
            switch indexPath.row {
            case 0:
                cell.configure(image: #imageLiteral(resourceName: "ic_nav_bill_white"), text: NSLocalizedString("Bill", comment: ""), backgroundColor: .black, shouldConstrainWidth: true)
            case 1:
                cell.configure(image: #imageLiteral(resourceName: "ic_nav_more_white"), text: NSLocalizedString("More", comment: ""), backgroundColor: .black, shouldConstrainWidth: true)
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
                performSegue(withIdentifier: "ReportOutageSegue", sender: nil)
            case 1:
                performSegue(withIdentifier: "OutageMapSegue", sender: nil)
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "BillSegue", sender: nil)
            case 1:
                performSegue(withIdentifier: "MoreSegue", sender: nil)
            default:
                break
            }
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 0.5 // Only show the separator
        default:
            return 60
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TitleTableViewHeaderView.className) as? TitleTableViewHeaderView else { return nil }
        
        switch section {
        case 0:
            if shouldShowOutageButtons {
                // Show Separator
                headerView.configure(text: nil, backgroundColor: .black, shouldHideSeparator: false)
            } else {
                // Hide Separator
                headerView.configure(text: nil, backgroundColor: .black, shouldHideSeparator: true)
            }
        case 1:
            headerView.configure(text: NSLocalizedString("More Options", comment: ""), backgroundColor: .black, shouldConstrainWidth: true)
        default:
            break
        }

        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 21
    }
    
}
