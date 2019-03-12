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
    
    var billingHistory: BillingHistory!
    
    let viewModel = BillingHistoryViewModel(billService: ServiceFactory.createBillService())
    
    var accountDetail: AccountDetail! // Passed from BillViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Bill & Payment Activity", comment: "")
        
        tableView.delegate = self
        tableView.dataSource = self
        
        emptyStateLabel.font = SystemFont.regular.of(textStyle: .headline)
        emptyStateLabel.textColor = .blackText
        emptyStateLabel.text = NSLocalizedString("No data currently available.", comment: "")
        emptyStateLabel.isHidden = true
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        errorLabel.isHidden = true
        
        tableView.register(UINib(nibName: BillingHistoryTableViewCell.className, bundle: nil), forCellReuseIdentifier: BillingHistoryTableViewCell.className)
        
        getBillingHistory()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setColoredNavBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Analytics.log(event: .billingOfferComplete)
    }
    
    func getBillingHistory() {
        loadingIndicator.isHidden = false
        tableView.isHidden = true
        viewModel.getBillingHistory(success: { [weak self] (billingHistory) in
            guard let self = self else { return }
            self.loadingIndicator.isHidden = true
            self.tableView.isHidden = false
            
            self.billingHistory = billingHistory
            if billingHistory.upcoming.count == 0 && billingHistory.past.count == 0 {
                self.tableView.isHidden = true
                self.emptyStateLabel.isHidden = false
                UIAccessibility.post(notification: .screenChanged, argument: self.emptyStateLabel)
            } else {
                self.tableView.reloadData()
                UIAccessibility.post(notification: .screenChanged, argument: self.tableView)
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
            vc.billingSelection = sender as? BillingSelection ?? .history
            vc.billingHistory = billingHistory
        } else if let vc = segue.destination as? BillingHistoryDetailsViewController,
            let billingHistoryItem = sender as? BillingHistoryItem {
            vc.billingHistoryItem = billingHistoryItem
        } else if let vc = segue.destination as? ViewBillViewController,
            let billingHistoryItem = sender as? BillingHistoryItem {
            vc.viewModel.billDate = billingHistoryItem.date
            Analytics.log(event: .billViewPastOfferComplete)
            AppRating.logRatingEvent()
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
    
}

extension BillingHistoryViewController: UITableViewDelegate {
    
    func selectedRow(at indexPath: IndexPath) {
        if indexPath.section == 1 { // past billing history
            let billingItem = billingHistory.mostRecentSixMonths[indexPath.row]
            
            guard indexPath.row < billingHistory.mostRecentSixMonths.count else { return }
            
            if billingItem.isBillPDF {
                showBillPdf(billingItem: billingItem)
            } else {
                switch billingItem.status {
                case .processing, .processed, .scheduled, .pending:
                    handleAllOpcoScheduledClick(billingItem: billingItem)
                case .canceled, .failed, .accepted, .unknown:
                    performSegue(withIdentifier: "showBillingDetailsSegue", sender: billingItem)
                }
            }
        } else { // upcoming billing history
            if indexPath.row == 0 && (accountDetail.isBGEasy || accountDetail.isAutoPay) {
                if accountDetail.isAutoPay {
                    if Environment.shared.opco == .bge {
                        performSegue(withIdentifier: "bgeAutoPaySegue", sender: self)
                    } else {
                        performSegue(withIdentifier: "autoPaySegue", sender: self)
                    }
                } else if accountDetail.isBGEasy {
                    performSegue(withIdentifier: "viewBGEasySegue", sender: self)
                }
            } else {
                var selectedIndex = indexPath.row
                if accountDetail.isBGEasy || accountDetail.isAutoPay {
                    selectedIndex -= 1 //everything is offset by BGEasy cell
                }
                
                let billingItem = billingHistory.upcoming[selectedIndex]
                if Environment.shared.opco == .bge {
                    switch billingItem.status {
                    case .processing, .processed, .canceled, .failed:
                        performSegue(withIdentifier: "showBillingDetailsSegue", sender: billingItem)
                    case .scheduled:
                        handleAllOpcoScheduledClick(billingItem: billingItem)
                    case .pending, .accepted, .unknown:
                        break
                    }
                } else {
                    switch billingItem.status {
                    case .canceled, .accepted, .failed:
                        performSegue(withIdentifier: "showBillingDetailsSegue", sender: billingItem)
                    case .scheduled, .processing, .processed:
                        handleAllOpcoScheduledClick(billingItem: billingItem)
                    case .pending, .unknown:
                        break
                    }
                }
            }
        }
    }
    
    private func handleAllOpcoScheduledClick(billingItem: BillingHistoryItem) {
        if Environment.shared.opco == .bge {
            guard let paymentMethod = billingItem.paymentMethod else { return }
            if paymentMethod == "S" { //scheduled
                showModifyScheduledItem(billingItem: billingItem)
            } else {  // recurring/automatic
                let storyboard = UIStoryboard(name: "Bill", bundle: nil)
                if let vc = storyboard.instantiateViewController(withIdentifier: "BGEAutoPay") as? BGEAutoPayViewController {
                    vc.accountDetail = accountDetail
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
        } else { //PECO/COMED scheduled
            showModifyScheduledItem(billingItem: billingItem)
        }
    }
    
    private func showBillPdf(billingItem: BillingHistoryItem) {
        if Environment.shared.opco == .comEd && accountDetail.hasElectricSupplier && accountDetail.isSingleBillOption {
            let alertVC = UIAlertController(title: NSLocalizedString("You are enrolled with a Supplier who provides you with your electricity bill, including your ComEd delivery charges. Please reach out to your Supplier for your bill image.", comment: ""), message: nil, preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            present(alertVC, animated: true, completion: nil)
        } else {
            performSegue(withIdentifier: "viewBillSegue", sender: billingItem)
        }
    }
    
    private func showModifyScheduledItem(billingItem: BillingHistoryItem) {
        let paymentVc = UIStoryboard(name: "Payment", bundle: nil).instantiateInitialViewController() as! MakePaymentViewController
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: BillingHistoryTableViewCell.className, for: indexPath) as! BillingHistoryTableViewCell
        
        cell.configureWith(item: billingHistoryItem)
        cell.didSelect
            .drive(onNext: { [weak self] in
                self?.selectedRow(at: indexPath)
            })
            .disposed(by: cell.disposeBag)
        return cell
    }
    
    func headerView(section: Int) -> UIView {
        let view = UIView()
        
        view.backgroundColor = .white
        let label = UILabel()
        let button = UIButton(type: .system)
        
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
        
        stackView.addTabletWidthConstraints(horizontalPadding: 0)
        stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
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
    
    @objc func viewAllUpcoming() {
        performSegue(withIdentifier: "showMoreBillingHistorySegue", sender: BillingSelection.upcoming)
    }
    
    @objc func viewMorePast() {
        performSegue(withIdentifier: "showMoreBillingHistorySegue", sender: BillingSelection.history)
    }
    
    func viewMoreTableViewCell(indexPath: IndexPath) -> UITableViewCell {
        let button = UIButton(type: .system)
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        button.titleLabel?.font = SystemFont.semibold.of(size: 18)
        button.setTitle("View More", for: .normal)
        button.setTitleColor(.actionBlue, for: .normal)
        button.addTarget(self, action: #selector(BillingHistoryViewController.viewMorePast), for:.touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "ViewMoreCell")
        cell.selectionStyle = .none
        cell.contentView.addSubview(button)
        
        button.centerXAnchor.constraint(equalTo: cell.centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: cell.centerYAnchor).isActive = true
        
        return cell
    }
    
    func bgEasyTableViewCell(indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "BgEasyCell")
        
        cell.selectionStyle = .none
        
        let innerContentView = ButtonControl(frame: .zero)
        innerContentView.translatesAutoresizingMaskIntoConstraints = false
        innerContentView.backgroundColorOnPress = .accentGray
        
        innerContentView.rx.touchUpInside.asDriver()
            .drive(onNext: { [weak self] in
                self?.selectedRow(at: indexPath)
            })
            .disposed(by: disposeBag)
        
        let label = UILabel()
        
        let labelText: String
        if accountDetail.isAutoPay {
            labelText = NSLocalizedString("You are enrolled in AutoPay", comment: "")
        } else {
            labelText = NSLocalizedString("You are enrolled in BGEasy", comment: "")
        }
        
        label.text = labelText
        innerContentView.accessibilityLabel = labelText
        
        label.font = SystemFont.medium.of(textStyle: .headline)
        
        let carat = UIImageView(image: #imageLiteral(resourceName: "ic_caret"))
        carat.contentMode = .scaleAspectFit
        
        let stackView = UIStackView(arrangedSubviews: [label, UIView(), carat]).usingAutoLayout()
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
        
        innerContentView.addTabletWidthConstraints(horizontalPadding: 0)
        innerContentView.topAnchor.constraint(equalTo: cell.contentView.topAnchor).isActive = true
        innerContentView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor).isActive = true
        
        return cell
    }
    
    func onPaymentDelete() { // Called by MakePaymentViewController to display toast and refresh the data
        getBillingHistory()
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Scheduled payment canceled", comment: ""))
        })
    }
    
}
