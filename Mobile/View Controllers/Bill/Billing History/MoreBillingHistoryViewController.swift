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
        
        title = NSLocalizedString("More Activity", comment: "")
        loadingIndicator.isHidden = false
        tableView.isHidden = true
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: BillingHistoryTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: "BillingHistoryCell")
        
        loadingIndicator.isHidden = true
        tableView.isHidden = false
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
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
    
    deinit {
        dLog()
    }
}

extension MoreBillingHistoryViewController: UITableViewDelegate {
    
    func selectedRow(at indexPath: IndexPath, tableView: UITableView) {
        
        selectedIndexPath = indexPath

        if billingSelection == .history {
            guard let billingItem = billingHistory?.past[indexPath.row],
                let type = billingItem.type else { return }
            
            let status = billingItem.status
            if type == BillingHistoryProperties.TypeBilling.rawValue {
                showBillPdf()
            } else if status == BillingHistoryProperties.StatusProcessing.rawValue ||
                status == BillingHistoryProperties.StatusSCHEDULED.rawValue ||
                status == BillingHistoryProperties.StatusScheduled.rawValue ||
                status == BillingHistoryProperties.StatusPending.rawValue {
                handleAllOpcoScheduledClick(indexPath: indexPath, billingItem: billingItem)
            } else {
                performSegue(withIdentifier: "showBillingHistoryDetailsSegue", sender: self)
            }
            //upcoming billing history
        } else {
            let opco = Environment.sharedInstance.opco
            
            if opco == .bge {
                if accountDetail.isBGEasy {
                    if billingHistory?.upcoming == nil {
                        performSegue(withIdentifier: "viewBGEasySegue", sender: self)
                    } else if indexPath.row == billingHistory!.upcoming.count + 1 {
                        performSegue(withIdentifier: "viewBGEasySegue", sender: self)
                    } else  {
                        handleBGEUpcomingClick(indexPath: indexPath)
                    }
                }  else {
                    handleBGEUpcomingClick(indexPath: indexPath)
                }
            } else {
                guard let billingItem = billingHistory?.upcoming[indexPath.row],
                    let status = billingItem.status else { return }
                
                //pending payments do not get a tap so we only handle scheduled/cancelled payments
                if status == BillingHistoryProperties.StatusProcessing.rawValue ||
                    status == BillingHistoryProperties.StatusSCHEDULED.rawValue ||
                    status == BillingHistoryProperties.StatusPending.rawValue {
                    handleAllOpcoScheduledClick(indexPath: indexPath, billingItem: billingItem)
                } else if status == BillingHistoryProperties.StatusCanceled.rawValue ||
                    status == BillingHistoryProperties.StatusCANCELLED.rawValue ||
                    status == BillingHistoryProperties.StatusFailed.rawValue {
                    performSegue(withIdentifier: "showBillingHistoryDetailsSegue", sender: self)
                }
            }
        }
    }
    
    private func handleBGEUpcomingClick(indexPath: IndexPath) {
        guard let billingItem = billingHistory?.upcoming[indexPath.row],
            let status = billingItem.status else { return }
        
        if status == BillingHistoryProperties.StatusProcessing.rawValue ||
            status == BillingHistoryProperties.StatusCanceled.rawValue ||
            status == BillingHistoryProperties.StatusCANCELLED.rawValue ||
            status == BillingHistoryProperties.StatusFailed.rawValue {
            
            performSegue(withIdentifier: "showBillingHistoryDetailsSegue", sender: self)
            
        } else { //It's scheduled hopefully
            handleAllOpcoScheduledClick(indexPath: indexPath, billingItem: billingItem)
        }
    }
    
    private func handleAllOpcoScheduledClick(indexPath: IndexPath, billingItem: BillingHistoryItem) {
        if Environment.sharedInstance.opco == .bge {
            guard let paymentMethod = billingItem.paymentMethod else { return }
            if paymentMethod == BillingHistoryProperties.PaymentMethod_S.rawValue { //scheduled
                showModifyScheduledItem(billingItem: billingItem)
            } else {  // recurring/automatic
                let storyboard = UIStoryboard(name: "Bill", bundle: nil)
                if let vc = storyboard.instantiateViewController(withIdentifier: "BGEAutoPay") as? BGEAutoPayViewController {
                    vc.accountDetail = accountDetail
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
        } else { //PECO/COMED scheduled
            guard let walletItemId = billingItem.walletItemId else { return }
            if walletItemId != "" {
                showModifyScheduledItem(billingItem: billingItem)
            }
        }
    }
    
    private func showBillPdf() {
        if Environment.sharedInstance.opco == .comEd && accountDetail.hasElectricSupplier && accountDetail.isSingleBillOption {
            let alertVC = UIAlertController(title: NSLocalizedString("You are enrolled with a Supplier who provides you with your electricity bill, including your ComEd delivery charges. Please reach out to your Supplier for your bill image.", comment: ""), message: nil, preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            present(alertVC, animated: true, completion: nil)
        } else {
            performSegue(withIdentifier: "viewBillSegue", sender: self)
        }
    }
    
    private func showModifyScheduledItem(billingItem: BillingHistoryItem) {
        let paymentVc = UIStoryboard(name: "Wallet", bundle: nil).instantiateViewController(withIdentifier: "makeAPayment") as! MakePaymentViewController
        paymentVc.accountDetail = accountDetail
        paymentVc.billingHistoryItem = billingItem
        if let walletItemId = billingItem.walletItemId, let paymentAmount = billingItem.amountPaid {
            let paymentDetail = PaymentDetail(walletItemId: walletItemId, paymentAmount: paymentAmount, paymentDate: billingItem.date)
            paymentVc.paymentDetail = paymentDetail
        }
        navigationController?.pushViewController(paymentVc, animated: true)
    }
}

extension MoreBillingHistoryViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (billingList) != nil {
            return billingList!.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let billingHistoryItem: BillingHistoryItem

        billingHistoryItem = (billingList![indexPath.row])
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "BillingHistoryCell", for: indexPath) as! BillingHistoryTableViewCell
        
        cell.configureWith(item: billingHistoryItem)
        
        cell.didSelect
            .drive(onNext: { [weak self, weak tableView] in
                guard let tableView = tableView else { return }
                self?.selectedRow(at: indexPath, tableView: tableView)
            })
            .disposed(by: cell.disposeBag)
        
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
