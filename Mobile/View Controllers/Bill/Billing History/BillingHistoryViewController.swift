//
//  BillingHistoryViewController.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 6/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

class BillingHistoryViewController: UIViewController {
    
    let disposeBag = DisposeBag()

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingIndicator: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var emptyStateLabel: UILabel!
    
    let viewModel = BillingHistoryViewModel(billService: ServiceFactory.createBillService())
    
    // Pass these in
    var accountDetail: AccountDetail!
    var billingHistory: BillingHistory? // Passed in when viewing "More Activity", otherwise it's fetched here
    var viewingMoreActivity = false // Pass true to indicate "More Activity" screen

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setColoredNavBar()
        
        title = viewingMoreActivity ? NSLocalizedString("More Activity", comment: "") : NSLocalizedString("Bill & Payment Activity", comment: "")
        
        if billingHistory == nil { // Don't fetch on "More Activity" when we pass this in
            getBillingHistory()
        }
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
        }, failure: { [weak self] (error) in
            self?.errorLabel.isHidden = false
            self?.loadingIndicator.isHidden = true
        })
    }
    
    private var shouldShowAutoPayCell: Bool {
        return !viewingMoreActivity && (accountDetail.isBGEasy || accountDetail.isAutoPay)
    }
    
    func onPaymentCancel() { // Called by MakePaymentViewController to display toast and refresh the data
        getBillingHistory()
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Scheduled payment canceled", comment: ""))
        })
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        view.endEditing(true)
        
        if let vc = segue.destination as? BillingHistoryDetailsViewController,
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
    
    @objc func viewAllUpcoming() {
        let storyboard = UIStoryboard(name: "Bill", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "billingHistory") as? BillingHistoryViewController else {
            fatalError("Failed to instantiate BillingHistoryViewController")
        }
        vc.accountDetail = accountDetail
        vc.billingHistory = BillingHistory(upcoming: billingHistory!.upcoming, past: [])
        vc.viewingMoreActivity = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func viewMorePast() {
        let storyboard = UIStoryboard(name: "Bill", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "billingHistory") as? BillingHistoryViewController else {
            fatalError("Failed to instantiate BillingHistoryViewController")
        }
        vc.accountDetail = accountDetail
        vc.billingHistory = BillingHistory(upcoming: [], past: billingHistory!.past)
        vc.viewingMoreActivity = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Misc
    
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
        if indexPath.section == 0 { // Upcoming
            if indexPath.row == 0 && shouldShowAutoPayCell {
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
                if shouldShowAutoPayCell {
                    selectedIndex -= 1 // everything is offset by AutoPay cell
                }
                
                let billingItem = billingHistory!.upcoming[selectedIndex]
                switch billingItem.status {
                case .scheduled:
                    handleScheduledClick(billingItem: billingItem)
                default:
                    performSegue(withIdentifier: "showBillingDetailsSegue", sender: billingItem)
                }
            }
        } else { // Past
            let billingItem = viewingMoreActivity ?
                billingHistory!.past[indexPath.row] :
                billingHistory!.mostRecentSixMonths[indexPath.row]
            if billingItem.isBillPDF {
                showBillPdf(billingItem: billingItem)
            } else {
                switch billingItem.status {
                case .scheduled: // Should never happen?
                    handleScheduledClick(billingItem: billingItem)
                default:
                    performSegue(withIdentifier: "showBillingDetailsSegue", sender: billingItem)
                }
            }
        }
    }
    
    private func handleScheduledClick(billingItem: BillingHistoryItem) {
        // TODO: How do we handle scheduled payments that are AutoPay payments? We used to send them to BGE AutoPay like so:
        /*
        let storyboard = UIStoryboard(name: "Bill", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "BGEAutoPay") as? BGEAutoPayViewController {
            vc.accountDetail = accountDetail
            navigationController?.pushViewController(vc, animated: true)
        }
        */

        let paymentVc = UIStoryboard(name: "Payment", bundle: nil).instantiateInitialViewController() as! MakePaymentViewController
        paymentVc.accountDetail = accountDetail
        paymentVc.billingHistoryItem = billingItem
        navigationController?.pushViewController(paymentVc, animated: true)
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
    
}

extension BillingHistoryViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let billingHistory = billingHistory else { return 0 }
        
        if section == 0 {
            let upcoming = billingHistory.upcoming
            if viewingMoreActivity {
                return upcoming.count
            } else if shouldShowAutoPayCell {
                if upcoming.isEmpty {
                    return 1
                }
                return upcoming.count > 2 ? 3 : upcoming.count + 1
            } else {
                return upcoming.count > 3 ? 3 : upcoming.count
            }
        } else {
            if viewingMoreActivity {
                return billingHistory.past.count
            } else {
                return billingHistory.past.count > billingHistory.mostRecentSixMonths.count ?
                    billingHistory.mostRecentSixMonths.count + 1 :
                    billingHistory.mostRecentSixMonths.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let billingHistory = billingHistory, !viewingMoreActivity else { return 0.01 }
        if section == 0 && billingHistory.upcoming.isEmpty && !shouldShowAutoPayCell {
            return 0.01
        } else if section == 1 && billingHistory.past.isEmpty {
            return 0.01
        }
        return 50
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let billingHistory = billingHistory, !viewingMoreActivity else { return 0.01 }
        if section == 0, !billingHistory.upcoming.isEmpty || shouldShowAutoPayCell {
            return 22
        }
        return 0.01
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? { 
        guard let billingHistory = billingHistory, !viewingMoreActivity else { return nil }
        if section == 0, !billingHistory.upcoming.isEmpty || shouldShowAutoPayCell {
            return headerView(section: section)
        } else if section == 1 && !billingHistory.past.isEmpty {
            return headerView(section: section)
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard billingHistory != nil, !viewingMoreActivity else { return nil }
        
        let view = UIView()
        if section == 0 {
            view.backgroundColor = .softGray
        } else {
            view.backgroundColor = .clear
        }
        return view
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let billingHistoryItem: BillingHistoryItem
        if indexPath.section == 0 {
            if indexPath.row == 0 && shouldShowAutoPayCell {
                return autoPayTableViewCell(indexPath: indexPath)
            } else {
                let row = shouldShowAutoPayCell ? indexPath.row - 1 : indexPath.row
                billingHistoryItem = billingHistory!.upcoming[row]
            }
        } else {
            if viewingMoreActivity {
                billingHistoryItem = billingHistory!.past[indexPath.row]
            } else {
                if indexPath.row != billingHistory!.mostRecentSixMonths.count {
                    billingHistoryItem = billingHistory!.mostRecentSixMonths[indexPath.row]
                } else {
                    return viewMoreTableViewCell(indexPath: indexPath)
                }
            }
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: BillingHistoryTableViewCell.className, for: indexPath) as! BillingHistoryTableViewCell
        cell.configureWith(item: billingHistoryItem)
        cell.didSelect.drive(onNext: { [weak self] in
            self?.selectedRow(at: indexPath)
        }).disposed(by: cell.disposeBag)
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
            if billingHistory!.upcoming.count > (shouldShowAutoPayCell ? 2 : 3) {
                let localizedText = NSLocalizedString("View All (%d)", comment: "")
                titleText = String(format: localizedText, billingHistory!.upcoming.count)
            } else {
                button.isEnabled = false
                button.isAccessibilityElement = false
            }
        } else {
            if billingHistory!.past.count > billingHistory!.mostRecentSixMonths.count {
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
    
    func autoPayTableViewCell(indexPath: IndexPath) -> UITableViewCell {
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
    
}
