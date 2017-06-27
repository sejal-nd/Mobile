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
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        view.endEditing(true)
        
        if let vc = segue.destination as? MoreBillingHistoryViewController {
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
        
        self.performSegue(withIdentifier: "showBillingDetailsSegue", sender: self)
    }
    
}

extension BillingHistoryViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            guard let upcoming = self.billingHistory?.upcoming else {
                return 0 //TODO: empty state
            }
            
            if upcoming.count > 3 {
                return 3
            }
            else {
                return upcoming.count
            }
        } else {
            guard let past = self.billingHistory?.past else {
                return 0 //TODO: empty state
            }
            
            if past.count > 16 {
                return 17
            }
            else {
                return past.count
            }
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
            if section == 0 && self.billingHistory?.upcoming.count == 0 {
                return nil
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
            billingHistoryItem = (self.billingHistory?.upcoming[indexPath.row])!;
        } else {
            billingHistoryItem = (self.billingHistory?.past[indexPath.row])!;
        }
        
        if indexPath.section == 1 && indexPath.row == 16 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            let button = UIButton(type: UIButtonType.system)
            button.setTitle("View More", for: .normal)
            button.setTitleColor(.actionBlue, for: .normal)
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
            button.addTarget(self, action: #selector(BillingHistoryViewController.viewMorePast), for:.touchUpInside)
            cell.contentView.addSubview(button)
            return cell
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
    
}
