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
    
    let disposeBag = DisposeBag()

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingIndicator: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var emptyStateLabel: UILabel!
    
    var billingSelection: BillingSelection!
    var billingHistory: BillingHistory!
    var selectedIndexPath:IndexPath!
    
    let viewModel = BillingHistoryViewModel(billService: ServiceFactory.createBillService())
    
    var accountDetail: AccountDetail! // Passed from BillViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Activity", comment: "")
        
        tableView.delegate = self;
        tableView.dataSource = self;
        
        emptyStateLabel.font = SystemFont.regular.of(textStyle: .headline)
        emptyStateLabel.textColor = .blackText
        emptyStateLabel.text = NSLocalizedString("No data currently available.", comment: "")
        emptyStateLabel.isHidden = true
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        errorLabel.isHidden = true
        
        tableView.register(UINib(nibName: BillingHistoryTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: "Cell")
        
        getBillingHistory()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Analytics().logScreenView(AnalyticsPageView.BillingOfferComplete.rawValue)
    }
    
    func getBillingHistory() {
        loadingIndicator.isHidden = false;
        tableView.isHidden = true;
        viewModel.getBillingHistory(success: { [weak self] (billingHistory) in
            guard let `self` = self else { return }
            self.loadingIndicator.isHidden = true
            self.tableView.isHidden = false
            
            self.billingHistory = billingHistory
            if billingHistory.upcoming.count == 0 && billingHistory.past.count == 0 {
                self.tableView.isHidden = true
                self.emptyStateLabel.isHidden = false
                UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.emptyStateLabel)
            } else {
                self.tableView.reloadData()
                UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.tableView)
            }
            
        }) { [weak self] (error) in
            self?.errorLabel.isHidden = false
            self?.loadingIndicator.isHidden = true
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        view.endEditing(true)
        
        if let vc = segue.destination as? MoreBillingHistoryViewController {
            vc.accountDetail = accountDetail
            
            vc.billingSelection = billingSelection
            vc.billingHistory = billingHistory
            
        } else if let vc = segue.destination as? BillingHistoryDetailsViewController {
            let billingHistoryItem = selectedIndexPath.section == 0 ? billingHistory.upcoming[selectedIndexPath.row] : billingHistory.past[selectedIndexPath.row]
            vc.billingHistoryItem = billingHistoryItem
        } else if let vc = segue.destination as? ViewBillViewController {
            let billingHistoryItem = selectedIndexPath.section == 0 ? billingHistory.upcoming[selectedIndexPath.row] : billingHistory.past[selectedIndexPath.row]
            vc.viewModel.billDate = billingHistoryItem.date.apiFormatDate
        } else if let vc = segue.destination as? BGEAutoPayViewController {
            vc.accountDetail = accountDetail
        } else if let vc = segue.destination as? AutoPayViewController {
            vc.accountDetail = accountDetail
        }
    }
    
    func showDelayedToast(withMessage message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(message)
        })
    }
    
    // Prevents status bar color flash when pushed
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    deinit {
        dLog()
    }
}

extension BillingHistoryViewController: UITableViewDelegate {
    
    func selectedRow(at indexPath: IndexPath, tableView: UITableView) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        selectedIndexPath = indexPath
        
        //past billing history
        if indexPath.section == 1 {
            let billingItem = billingHistory.mostRecentSixMonths[indexPath.row]
            
            guard indexPath.row < billingHistory.mostRecentSixMonths.count, let type = billingItem.type else {
                return
            }
            
            let status = billingItem.status
            
            if type == BillingHistoryProperties.TypeBilling.rawValue {
                showBillPdf()
            } else if status == BillingHistoryProperties.StatusProcessing.rawValue ||
                status == BillingHistoryProperties.StatusSCHEDULED.rawValue ||
                status == BillingHistoryProperties.StatusScheduled.rawValue ||
                status == BillingHistoryProperties.StatusPending.rawValue {
                handleAllOpcoScheduledClick(indexPath: indexPath, billingItem: billingItem)
            } else {
                performSegue(withIdentifier: "showBillingDetailsSegue", sender: self)
            }
        //upcoming billing history
        } else {
            let opco = Environment.sharedInstance.opco
            
            if (accountDetail.isBGEasy || accountDetail.isAutoPay) {
                selectedIndexPath.row = selectedIndexPath.row - 1 //everything is offset by BGEasy cell
            }
            
            if indexPath.row == 0 && (accountDetail.isBGEasy || accountDetail.isAutoPay) {
                if accountDetail.isAutoPay {
                    if opco == .bge {
                        performSegue(withIdentifier: "bgeAutoPaySegue", sender: self)
                    } else {
                        performSegue(withIdentifier: "autoPaySegue", sender: self)
                    }
                } else if accountDetail.isBGEasy {
                    performSegue(withIdentifier: "viewBGEasySegue", sender: self)
                }
            } else {
                if opco == .bge {
                    handleBGEUpcomingClick(indexPath: selectedIndexPath) 
                } else {
                    let billingItem = billingHistory.upcoming[selectedIndexPath.row]
                    guard let status = billingItem.status else { return }
                    
                    //pending payments do not get a tap so we only handle scheduled/cancelled payments
                    if status == BillingHistoryProperties.StatusProcessing.rawValue || 
                        status == BillingHistoryProperties.StatusSCHEDULED.rawValue ||
                        status == BillingHistoryProperties.StatusScheduled.rawValue ||
                        status == BillingHistoryProperties.StatusPending.rawValue {
                        handleAllOpcoScheduledClick(indexPath: indexPath, billingItem: billingItem)
                    } else if status == BillingHistoryProperties.StatusCanceled.rawValue || 
                        status == BillingHistoryProperties.StatusCANCELLED.rawValue ||
                        status == BillingHistoryProperties.StatusFailed.rawValue {
                        performSegue(withIdentifier: "showBillingDetailsSegue", sender: self)
                    }
                }
            }
        }
    }
    
    private func handleBGEUpcomingClick(indexPath: IndexPath) {
        let billingItem = billingHistory.upcoming[indexPath.row]
        guard let status = billingItem.status else { return }
        
        if status == BillingHistoryProperties.StatusProcessing.rawValue ||
            status == BillingHistoryProperties.StatusCanceled.rawValue || 
            status == BillingHistoryProperties.StatusCANCELLED.rawValue ||
            status == BillingHistoryProperties.StatusFailed.rawValue {
            
            performSegue(withIdentifier: "showBillingDetailsSegue", sender: self)
            
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

extension BillingHistoryViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if billingHistory == nil {
            return 0
        }
        
        if section == 0 {
            let upcoming = billingHistory.upcoming
            if upcoming.count == 0 {
                return accountDetail.isBGEasy || accountDetail.isAutoPay ? 1 : 0
            }
            if accountDetail.isBGEasy || accountDetail.isAutoPay {
                return upcoming.count > 2 ? 3 : upcoming.count + 1
            } else {
                return upcoming.count > 3 ? 3 : upcoming.count
            }
        } else {
            return billingHistory.past.count > billingHistory.mostRecentSixMonths.count ? billingHistory.mostRecentSixMonths.count + 1 : billingHistory.mostRecentSixMonths.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.billingHistory != nil {
            if section == 0 && billingHistory.upcoming.count == 0 && !accountDetail.isAutoPay && !accountDetail.isBGEasy {
                return 0.000001
            } else if section == 1 && billingHistory.past.count == 0 {
                return 0.000001
            }
        }
        
        return 50
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if billingHistory != nil && section == 0 && (!billingHistory.upcoming.isEmpty || accountDetail.isAutoPay || accountDetail.isBGEasy) {
            return 22
        }
        
        return 0.000001 
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? { 
        
        if billingHistory != nil {
            if section == 0 {
                if accountDetail.isBGEasy || accountDetail.isAutoPay {
                    return headerView(section: section)
                } else {
                    return self.billingHistory.upcoming.count == 0 ? nil : headerView(section: section)
                }
            } else if section == 1 && self.billingHistory.past.count == 0 {
                return nil
            } else {
               return headerView(section: section) 
            }
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if billingHistory != nil {
            return footerView(section: section)
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let billingHistoryItem: BillingHistoryItem
        if indexPath.section == 0 {
            if (accountDetail.isBGEasy || accountDetail.isAutoPay) && indexPath.row == 0 {
                return bgEasyTableViewCell(indexPath: indexPath)
            } else {
                let row = (accountDetail.isBGEasy || accountDetail.isAutoPay) ? indexPath.row - 1 : indexPath.row
                billingHistoryItem = billingHistory.upcoming[row]
            }
        } else {
            if indexPath.row != billingHistory.mostRecentSixMonths.count {
                billingHistoryItem = billingHistory.mostRecentSixMonths[indexPath.row]
            } else {
                return viewMoreTableViewCell(indexPath: indexPath)
            }
            
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! BillingHistoryTableViewCell
        
        cell.configureWith(item: billingHistoryItem)
        cell.didSelect
            .drive(onNext: { [weak self, weak tableView] in
                guard let tableView = tableView else { return }
                self?.selectedRow(at: indexPath, tableView: tableView)
            })
            .disposed(by: cell.disposeBag)
        return cell
    }
    
    func headerView(section: Int) -> UIView {
        let view = UIView()
        
        view.backgroundColor = .white
        let label = UILabel()
        let button = UIButton(type: UIButtonType.system)
        
        label.text = section == 0 ? NSLocalizedString("UPCOMING", comment: "") : NSLocalizedString("PAST", comment: "")
        label.font = SystemFont.regular.of(textStyle: .subheadline)
        label.textColor = .deepGray
        
        var titleText = ""
        if section == 0 {
            if billingHistory.upcoming.count > (accountDetail.isBGEasy || accountDetail.isAutoPay ? 2 : 3) {
                let localizedText = NSLocalizedString("View All (%d)", comment: "")
                titleText = String(format: localizedText, billingHistory.upcoming.count)
            } else {
                button.isEnabled = false
                button.isAccessibilityElement = false
            }
        } else {
            if billingHistory.past.count > billingHistory.mostRecentSixMonths.count {
                titleText = NSLocalizedString("View More", comment: "")
            } else {
                button.isEnabled = false
                button.isAccessibilityElement = false
            }
            
        }
        
        button.setTitle(titleText, for: .normal)
        button.titleLabel?.font = SystemFont.semibold.of(textStyle: .subheadline)
        button.setTitleColor(.actionBlue, for: .normal)
        
        let selector = section == 0 ? #selector(BillingHistoryViewController.viewAllUpcoming) : #selector(BillingHistoryViewController.viewMorePast)
        button.addTarget(self, action: selector, for:.touchUpInside)
        
        let leadingSpace = UIView()
        leadingSpace.widthAnchor.constraint(equalToConstant: 19).isActive = true
        let trailingSpace = UIView()
        trailingSpace.widthAnchor.constraint(equalToConstant: 12).isActive = true
        
        let stackView = UIStackView(arrangedSubviews: [leadingSpace, label, UIView(), button, trailingSpace])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.axis = .horizontal
        stackView.alignment = .center
        
        view.addSubview(stackView)
        
        let leadingConstraint = stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0)
        leadingConstraint.priority = 750
        leadingConstraint.isActive = true
        let trailingConstraint = stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0)
        trailingConstraint.priority = 750
        trailingConstraint.isActive = true
        
        stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        stackView.widthAnchor.constraint(lessThanOrEqualToConstant: 460)
        let widthConstraint = stackView.widthAnchor.constraint(equalToConstant: 460)
        widthConstraint.priority = 750
        widthConstraint.isActive = true
        
        return view
    }
    
    func footerView(section: Int) -> UIView {
        let view = UIView() 
        
        if section == 0 {
           view.backgroundColor = .softGray
        } else {
            view.backgroundColor = .clear
        }
        return view
    }
    
    func viewAllUpcoming() {
        billingSelection = .upcoming
        
        performSegue(withIdentifier: "showMoreBillingHistorySegue", sender: self)
    }
    
    func viewMorePast() {
        billingSelection = .history
        
        performSegue(withIdentifier: "showMoreBillingHistorySegue", sender: self)
    }
    
    func viewMoreTableViewCell(indexPath: IndexPath) -> UITableViewCell {
        let button = UIButton(type: UIButtonType.system)
        button.contentEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8)
        button.titleLabel?.font = SystemFont.semibold.of(size: 18)
        button.setTitle("View More", for: .normal)
        button.setTitleColor(.actionBlue, for: .normal)
        button.addTarget(self, action: #selector(BillingHistoryViewController.viewMorePast), for:.touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: "ViewMoreCell")
        cell.selectionStyle = .none
        cell.contentView.addSubview(button)
        
        button.centerXAnchor.constraint(equalTo: cell.centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: cell.centerYAnchor).isActive = true
        
        return cell
    }
    
    func bgEasyTableViewCell(indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: "BgEasyCell")
        
        cell.selectionStyle = .none
        
        let innerContentView = ButtonControl(frame: .zero)
        innerContentView.translatesAutoresizingMaskIntoConstraints = false
        innerContentView.backgroundColorOnPress = .accentGray
        
        innerContentView.rx.touchUpInside.asDriver()
            .drive(onNext: { [weak self, weak tableView] in
                guard let tableView = tableView else { return }
                self?.selectedRow(at: indexPath, tableView: tableView)
            })
            .disposed(by: disposeBag)
        
        let label = UILabel()
        if accountDetail.isAutoPay {
            label.text = NSLocalizedString("You are enrolled in AutoPay", comment: "")
        } else {
            label.text = NSLocalizedString("You are enrolled in BGEasy", comment: "")
        }
        
        label.font = SystemFont.medium.of(textStyle: .headline)
        
        let carat = UIImageView(image: #imageLiteral(resourceName: "ic_caret"))
        carat.contentMode = .scaleAspectFit
        
        let stackView = UIStackView(arrangedSubviews: [label, UIView(), carat])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.isUserInteractionEnabled = false
        
        innerContentView.addSubview(stackView)
        
        stackView.topAnchor.constraint(equalTo: innerContentView.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: innerContentView.bottomAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: innerContentView.leadingAnchor, constant: 19).isActive = true
        stackView.trailingAnchor.constraint(equalTo: innerContentView.trailingAnchor, constant: -22).isActive = true
        
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        
        innerContentView.addSubview(separatorView)
        
        separatorView.leadingAnchor.constraint(equalTo: innerContentView.leadingAnchor).isActive = true
        separatorView.trailingAnchor.constraint(equalTo: innerContentView.trailingAnchor).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: innerContentView.bottomAnchor).isActive = true
        
        cell.contentView.addSubview(innerContentView)
        
        innerContentView.topAnchor.constraint(equalTo: cell.contentView.topAnchor).isActive = true
        innerContentView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor).isActive = true
        let leadingConstraint = innerContentView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 0)
        leadingConstraint.priority = 750
        leadingConstraint.isActive = true
        let trailingConstraint = innerContentView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: 0)
        trailingConstraint.priority = 750
        trailingConstraint.isActive = true
        
        innerContentView.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor).isActive = true
        innerContentView.widthAnchor.constraint(lessThanOrEqualToConstant: 460)
        let widthConstraint = innerContentView.widthAnchor.constraint(equalToConstant: 460)
        widthConstraint.priority = 750
        widthConstraint.isActive = true
        
        return cell
        
    }
    
    func onPaymentDelete() { // Called by MakePaymentViewController to display toast and refresh the data
        getBillingHistory()
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Scheduled payment deleted", comment: ""))
        })
    }
    
}
