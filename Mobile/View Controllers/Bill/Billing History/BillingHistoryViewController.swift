//
//  BillingHistoryViewController.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 6/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

enum BillingSelection {
    case upcoming
    case history
}

class BillingHistoryViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    @IBOutlet var loadingIndicator: UIView!
    @IBOutlet var empyStateLabel: UILabel!
    
    var billingSelection: BillingSelection!
    
    var billingHistory: BillingHistory?
    
    var selectedIndexPath:IndexPath!
    var historyItem: BillingHistoryItem?
    
    let viewModel = BillingHistoryViewModel(billService: ServiceFactory.createBillService())
    
    let disposeBag = DisposeBag()
    
    var accountDetail: AccountDetail!
    
    var didCreateBGEasyCell = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Activity", comment: "")
        self.loadingIndicator.isHidden = false;
        self.tableView.isHidden = true;
        self.empyStateLabel.isHidden = true
        
        tableView.delegate = self;
        tableView.dataSource = self;
        
        self.tableView.register(UINib(nibName: BillingHistoryTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: "Cell")
        
        viewModel.getBillingHistory(success: { (billingHistory) in
            self.loadingIndicator.isHidden = true
            self.tableView.isHidden = false
            self.billingHistory = billingHistory
            
            if self.billingHistory?.upcoming.count == 0 && self.billingHistory?.past.count == 00 {
                self.tableView.isHidden = true
                self.empyStateLabel.isHidden = false
            } else {
                self.tableView.reloadData()
            }
            
        }) { (error) in
            print(error)
            //TODO: handle this error
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar(hidesBottomBorder: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be revarated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        view.endEditing(true)
        
        if let vc = segue.destination as? MoreBillingHistoryViewController {
            vc.accountDetail = self.accountDetail
            
            vc.billingSelection = self.billingSelection
            vc.billingHistory = billingHistory
            
        } else if let vc = segue.destination as? BillingHistoryDetailsViewController {
            let billingHistoryItem: BillingHistoryItem
            
            if(selectedIndexPath.section == 0) {
                billingHistoryItem = (self.billingHistory?.upcoming[selectedIndexPath.row])!
            } else {
                billingHistoryItem = (self.billingHistory?.past[selectedIndexPath.row])!
            }
            
            vc.billingHistoryItem = billingHistoryItem
        }
    }
}



extension BillingHistoryViewController: UITableViewDelegate {
    
    //TODO: Not done here - need to figure out the Rx pattern to load this data
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        selectedIndexPath = indexPath
        
        if indexPath.section == 1 {
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                self.performSegue(withIdentifier: "showBillingDetailsSegue", sender: self)
                break
            case .pad:
                self.performSegue(withIdentifier: "showBillingDetailsIpadSegue", sender: self)
                break
            default:
                // what device is this... O_O
                break
            }
            
        } else {
            let billingItem = self.billingHistory?.upcoming[indexPath.row]
            
            let status = billingItem?.status!
            
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
                        self.performSegue(withIdentifier: "showBillingDetailsSegue", sender: self)
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

extension BillingHistoryViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            guard let upcoming = self.billingHistory?.upcoming else {
                return accountDetail.isBGEasy ? 1 : 0
            }
            
            if accountDetail.isBGEasy {
                return upcoming.count > 2 ? 3 : upcoming.count + 1
            } else {
                return upcoming.count > 3 ? 3 : upcoming.count
            }
        } else {
            guard let past = self.billingHistory?.past else {
                return 0 
            }
            return past.count > 16 ? 17 : past.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.billingHistory != nil {
            if section == 0 && self.billingHistory?.upcoming.count == 0 {
                return 0.000001
            } else if section == 1 && self.billingHistory?.past.count == 0 {
                return 0.000001
            }
        }
        
        return 50
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if self.billingHistory != nil {
            if section == 0 && self.billingHistory?.upcoming.count != 0 {
                return 22
            }
        }
        
        return 0.000001 
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? { 
        
        if self.billingHistory != nil {
            if section == 0 {
                if accountDetail.isBGEasy {
                    return headerView(section: section)
                } else {
                    return self.billingHistory?.upcoming.count == 0 ? nil : headerView(section: section)
                }
            } else if section == 1 && self.billingHistory?.past.count == 0 {
                return nil
            } else {
               return headerView(section: section) 
            }
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if self.billingHistory != nil {
            return footerView(section: section)
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let billingHistoryItem: BillingHistoryItem
        
        if indexPath.section == 0 {
            
            if accountDetail.isBGEasy {
                return bgEasyTableViewCell(indexPath: indexPath)
            } else {
                billingHistoryItem = (self.billingHistory?.upcoming[indexPath.row])!;
            }
        } else {
            billingHistoryItem = (self.billingHistory?.past[indexPath.row])!;
        }
        
        if indexPath.section == 1 && indexPath.row == 16 {
            return viewMoreTableViewCell(indexPath: indexPath)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! BillingHistoryTableViewCell
            cell.configureWith(item: billingHistoryItem)
            return cell
        }
        
    }
    
    func headerView(section: Int) -> UIView {
        let view = UIView() // The width will be the same as the cell, and the height should be set in tableView:heightForRowAtIndexPath:
        view.backgroundColor = UIColor.white
        let label = UILabel()
        let button = UIButton(type: UIButtonType.system)
        
        label.text = section == 0 ? "UPCOMING" : "PAST"
        label.font = label.font.withSize(14)
        label.textColor = UIColor.deepGray
        
        let titleText = section == 0 ? "View All (\(self.billingHistory!.upcoming.count))" : "View More" 
        button.setTitle(titleText, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.actionBlue, for: .normal)
        
        let selector = section == 0 ? #selector(BillingHistoryViewController.viewAllUpcoming) : #selector(BillingHistoryViewController.viewMorePast)
        button.addTarget(self, action: selector, for:.touchUpInside)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        view.addSubview(button)
        
        let views = ["label": label, "button": button, "view": view]
        
        let horizontallayoutContraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-19-[label]-60-[button]-22-|", options: .alignAllCenterY, metrics: nil, views: views)
        view.addConstraints(horizontallayoutContraints)
        
        let verticalLayoutContraint = NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        view.addConstraint(verticalLayoutContraint)
            
        return view
    }
    
    func footerView(section: Int) -> UIView {
        
        let isabaleneColor = UIColor(red: 233/255.0, green: 235/255.0, blue: 238/255.0, alpha: 1.00)
        let view = UIView() 
        
        if section == 0 {
           view.backgroundColor = isabaleneColor 
        } else {
            view.backgroundColor = UIColor.clear
        }
        return view
    }
    
    func viewAllUpcoming() {
        self.billingSelection = .upcoming
        
        self.performSegue(withIdentifier: "showMoreBillingHistorySegue", sender: self)
    }
    
    func viewMorePast() {
        self.billingSelection = .history
        
        self.performSegue(withIdentifier: "showMoreBillingHistorySegue", sender: self)
    }
    
    func viewMoreTableViewCell(indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: "ViewMoreCell")
        let button = UIButton(type: UIButtonType.system)
        button.setTitle("View More", for: .normal)
        button.setTitleColor(.actionBlue, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.addTarget(self, action: #selector(BillingHistoryViewController.viewMorePast), for:.touchUpInside)
        cell.contentView.addSubview(button)
        return cell
    }
    
    func bgEasyTableViewCell(indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: "BgEasyCell")
        
        let label = UILabel()
        label.text = "You currently have AutoPay set up"
        label.font = SystemFont.medium.of(textStyle: .subheadline).withSize(17)
        
        let carat = UIImageView(image: #imageLiteral(resourceName: "ic_caret"))
        carat.contentMode = .scaleAspectFit
    
        label.translatesAutoresizingMaskIntoConstraints = false
        carat.translatesAutoresizingMaskIntoConstraints = false
        
        cell.contentView.addSubview(label)
        cell.contentView.addSubview(carat)
        
        let views = ["label": label, "carat": carat, "view": cell.contentView]
        
        let horizontallayoutContraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-19-[label]-8-[carat]-22-|", options: .alignAllCenterY, metrics: nil, views: views)
        cell.contentView.addConstraints(horizontallayoutContraints)
        
        let verticalLayoutContraint = NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: cell.contentView, attribute: .centerY, multiplier: 1, constant: 0)
        cell.contentView.addConstraint(verticalLayoutContraint)
        
        return cell
        
    }
    
}
