//
//  MoreBillingHistoryViewController.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/26/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift


class MoreBillingHistoryViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var loadingIndicator: UIView!
    
    var billingHistory: BillingHistory?
    
    var billingSelection: BillingSelection?
    
    var billingList: [BillingHistoryItem]!
    
    var selectedIndexPath:IndexPath!
    
    let viewModel = BillingHistoryViewModel(billService: ServiceFactory.createBillService())
    
    var accountDetail: AccountDetail!

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch (billingSelection!) {
        case .history:
            billingList = billingHistory?.past
            
        case .upcoming:
            billingList = billingHistory?.upcoming
        }
        
        self.title = NSLocalizedString("More Activity", comment: "")
        self.loadingIndicator.isHidden = false
        self.tableView.isHidden = true
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.tableView.register(UINib(nibName: BillingHistoryTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: "BillingHistoryCell")
        
        self.loadingIndicator.isHidden = true
        self.tableView.isHidden = false
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar(hidesBottomBorder: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        view.endEditing(true)
        
        let billingHistoryItem: BillingHistoryItem
        
        billingHistoryItem = (self.billingHistory?.past[selectedIndexPath.row])!

        if let vc = segue.destination as? BillingHistoryDetailsViewController {
            vc.billingHistoryItem = billingHistoryItem
        }
    }
}

extension MoreBillingHistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        selectedIndexPath = indexPath

        // 
        if billingSelection == .history {
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                self.performSegue(withIdentifier: "showBillingHistoryDetailsSegue", sender: self)
                break
            case .pad:
                self.performSegue(withIdentifier: "showBillingDetailsIpadSegue", sender: self)
                break
            default:
                // what device is this... O_O
                break
            }
        } else {
            let billingItem = self.billingList[indexPath.row]
            
            let status = billingItem.status!
            
            let storyboard = UIStoryboard(name: "Bill", bundle: nil)
            
            let opco = Environment.sharedInstance.opco
            
            // PROCESSING, SCHEDULED, AUTOMATIC
            if opco == .bge {
                if status == "AUTOMATIC" {
                    if let vc = storyboard.instantiateViewController(withIdentifier: "BGEAutoPay") as? BGEAutoPayViewController {
                        vc.accountDetail = self.accountDetail
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                    
                } else if status == "PROCESSING" {
                    switch UIDevice.current.userInterfaceIdiom {
                    case .phone:
                        self.performSegue(withIdentifier: "showBillingHistoryDetailsSegue", sender: self)
                        break
                    case .pad:
                        self.performSegue(withIdentifier: "showBillingDetailsIpadSegue", sender: self)
                        break
                    default:
                        // what device is this... O_O
                        break
                    }
                    
                } else if status == "SCHEDULED" {
                    // TODO: load Scheduled Payment workflow (Sprint 13)
                }
                
            } else { // .comed/.peco
                if status == "AUTOMATIC" {
                    if let vc = storyboard.instantiateViewController(withIdentifier: "AutoPay") as? AutoPayViewController {
                        vc.accountDetail = self.accountDetail
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                    
                } else if status == "SCHEDULED" {
                    // TODO: load Scheduled Payment workflow (Sprint 13)
                }
            }
        }
    }
}

extension MoreBillingHistoryViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.billingList) != nil {
            return self.billingList!.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let billingHistoryItem: BillingHistoryItem

        billingHistoryItem = (self.billingList![indexPath.row])
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "BillingHistoryCell", for: indexPath) as! BillingHistoryTableViewCell
        
        cell.configureWith(item: billingHistoryItem)
        
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
