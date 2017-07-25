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
    
    var billingList: [BillingHistoryItem]?
    
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
        guard let billingHistoryItem = billingList?[selectedIndexPath.row] else { return }
        
        if let vc = segue.destination as? BillingHistoryDetailsViewController {
            vc.billingHistoryItem = billingHistoryItem
        } else if let vc = segue.destination as? ViewBillViewController {
            vc.viewModel.billDate = billingHistoryItem.date.apiFormatDate
        }
    }
}

extension MoreBillingHistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        selectedIndexPath = indexPath

        if billingSelection == .history {
            guard let billingItem = self.billingHistory?.past[indexPath.row], 
                let type = billingItem.type else { return }
            if type == BillingHistoryProperties.TypeBilling.rawValue {
                showBillPdf()
            } else {
                showBillingDetails()
            }
            //upcoming billing history
        } else {
            let opco = Environment.sharedInstance.opco
            
            if opco == .bge {
                if accountDetail.isBGEasy {
                    if self.billingHistory?.upcoming == nil {
                        self.performSegue(withIdentifier: "viewBGEasySegue", sender: self)
                    } else if indexPath.row == self.billingHistory!.upcoming.count + 1 {
                        self.performSegue(withIdentifier: "viewBGEasySegue", sender: self)
                    } else  {
                        handleBGEUpcomingClick(indexPath: indexPath)
                    }
                } 
            } else {
                guard let billingItem = self.billingHistory?.upcoming[indexPath.row], 
                    let status = billingItem.status else { return }
                
                //pending payments do not get a tap so we only handle scheduled payments
                if status == BillingHistoryProperties.StatusProcessing.rawValue || status == BillingHistoryProperties.StatusSCHEDULED.rawValue {
                    handleAllOpcoScheduledClick(indexPath: indexPath, billingItem: billingItem)
                }
            }
        }
    }
    
    private func handleBGEUpcomingClick(indexPath: IndexPath) {
        guard let billingItem = self.billingHistory?.upcoming[indexPath.row], 
            let status = billingItem.status else { return }
        
        if status == BillingHistoryProperties.StatusProcessing.rawValue {
            
            showBillingDetails()
            
        } else { //It's scheduled hopefully
            handleAllOpcoScheduledClick(indexPath: indexPath, billingItem: billingItem)
        }
    }
    
    private func handleAllOpcoScheduledClick(indexPath: IndexPath, billingItem: BillingHistoryItem) {
        
        let opco = Environment.sharedInstance.opco
        
        if opco == .bge {
            guard let paymentMethod = billingItem.paymentMethod,
                let allowDelete = billingItem.flagAllowDeletes,
                let allowEdit = billingItem.flagAllowEdits else { return }
            
            if paymentMethod == BillingHistoryProperties.PaymentMethod_S.rawValue { //scheduled
                if allowEdit || allowDelete {
                    showModifyScheduledItem(billingItem: billingItem)
                }
                else {
                    showBillingDetails()
                }
                
            } else {  // recurring/automatic
                let storyboard = UIStoryboard(name: "Bill", bundle: nil)
                if Environment.sharedInstance.opco == .bge {
                    if let vc = storyboard.instantiateViewController(withIdentifier: "BGEAutoPay") as? BGEAutoPayViewController {
                        vc.accountDetail = self.accountDetail
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                } else {
                    if let vc = storyboard.instantiateViewController(withIdentifier: "AutoPay") as? AutoPayViewController {
                        vc.accountDetail = self.accountDetail
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            }
            
        } else { //PECO/COMED scheduled
            guard let walletItemId = billingItem.walletItemId else { return }
            
            if walletItemId != "" {
                showModifyScheduledItem(billingItem: billingItem)
            }
            
        }
    }
    
    private func showBillingDetails() {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            self.performSegue(withIdentifier: "showBillingDetailsIpadSegue", sender: self)
            break
        default:
            self.performSegue(withIdentifier: "showBillingHistoryDetailsSegue", sender: self)
            break
        }
    }
    
    private func showBillPdf() {
        if Environment.sharedInstance.opco == .comEd && accountDetail.hasElectricSupplier && accountDetail.isSingleBillOption {
            let alertVC = UIAlertController(title: NSLocalizedString("You are enrolled with a Supplier who provides you with your electricity bill, including your ComEd delivery charges. Please reach out to your Supplier for your bill image.", comment: ""), message: nil, preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alertVC, animated: true, completion: nil)
        } else {
            self.performSegue(withIdentifier: "viewBillSegue", sender: self)
        }
    }
    
    private func showModifyScheduledItem(billingItem: BillingHistoryItem) {
        let paymentVc = UIStoryboard(name: "Wallet", bundle: nil).instantiateViewController(withIdentifier: "makeAPayment") as! MakePaymentViewController
        paymentVc.delegate = self
        paymentVc.accountDetail = accountDetail
        paymentVc.paymentId = billingItem.paymentId
        if let walletItemId = billingItem.walletItemId, let paymentAmount = billingItem.amountPaid {
            let paymentDetail = PaymentDetail(walletItemId: walletItemId, paymentAmount: paymentAmount, paymentDate: billingItem.date)
            paymentVc.paymentDetail = paymentDetail
        }
        self.navigationController?.pushViewController(paymentVc, animated: true)
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

extension MoreBillingHistoryViewController: MakePaymentViewControllerDelegate {
    func makePaymentViewControllerDidCancelPayment(_ makePaymentViewController: MakePaymentViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Scheduled payment deleted", comment: ""))
        })
    }
}
