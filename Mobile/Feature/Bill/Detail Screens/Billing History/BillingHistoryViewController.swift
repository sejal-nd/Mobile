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
    
    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var emptyStateLabel: UILabel!
    @IBOutlet weak var emptyStateAutoPayButton: SecondaryButton!
    
    let viewModel = BillingHistoryViewModel(billService: ServiceFactory.createBillService())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .softGray
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: BillingHistoryTableViewCell.className, bundle: nil), forCellReuseIdentifier: BillingHistoryTableViewCell.className)
        
        // TODO: Uncomment this, and the `UIViewControllerPreviewingDelegate` below to enable 3D Touch
        //registerForPreviewing(with: self, sourceView: tableView)
        
        emptyStateAutoPayButton.setTitle(NSLocalizedString("View AutoPay Settings", comment: ""), for: .normal)
        emptyStateAutoPayButton.removeShadow()
        emptyStateAutoPayButton.layer.cornerRadius = 22.5
        emptyStateAutoPayButton.layer.borderWidth = 1
        emptyStateAutoPayButton.layer.borderColor = UIColor.accentGray.cgColor
        emptyStateAutoPayButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
        emptyStateAutoPayButton.rx.touchUpInside.asDriver().drive(onNext: { [weak self] _ in
            guard let self = self else { return }
            let billStoryboard = UIStoryboard(name: "Bill", bundle: nil)
            let vc = billStoryboard.instantiateViewController(withIdentifier: "BGEAutoPay") as! BGEAutoPayViewController
            vc.accountDetail = self.viewModel.accountDetail
            vc.delegate = self
            self.navigationController?.pushViewController(vc, animated: true)
        }).disposed(by: disposeBag)
        
        emptyStateLabel.font = OpenSans.regular.of(textStyle: .headline)
        emptyStateLabel.textColor = .middleGray
        var emptyStateText = NSLocalizedString("Once you receive your bill or make a payment, details about those activities can be accessed here.", comment: "")
        if viewModel.shouldShowAutoPayCellDetailLabel {
            emptyStateText += NSLocalizedString(" Automatic payments will be visible once your bill is generated.", comment: "")
            emptyStateAutoPayButton.isHidden = false
        }
        emptyStateLabel.text = emptyStateText
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        errorLabel.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)
        
        title = viewModel.viewingMoreActivity ?
            NSLocalizedString("More Activity", comment: "") :
            NSLocalizedString("Bill & Payment Activity", comment: "")
        
        if viewModel.billingHistory == nil { // Don't fetch on "More Activity" when we pass this in
            getBillingHistory()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        GoogleAnalytics.log(event: .billingOfferComplete)
    }
    
    func getBillingHistory() {
        loadingIndicator.isHidden = false
        tableView.isHidden = true
        viewModel.getBillingHistory(success: { [weak self] in
            guard let self = self, let billingHistory = self.viewModel.billingHistory else { return }
            self.loadingIndicator.isHidden = true
            self.tableView.isHidden = false
            
            if billingHistory.upcoming.count == 0 && billingHistory.past.count == 0 {
                self.tableView.isHidden = true
                self.emptyStateView.isHidden = false
                UIAccessibility.post(notification: .screenChanged, argument: self.emptyStateView)
            } else {
                self.tableView.reloadData()
                UIAccessibility.post(notification: .screenChanged, argument: self.tableView)
            }
        }, failure: { [weak self] (error) in
            self?.errorLabel.isHidden = false
            self?.loadingIndicator.isHidden = true
        })
    }
    
    func onPaymentCancel() { // Called by MakePaymentViewController to display toast and refresh the data
        getBillingHistory()
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Scheduled payment canceled", comment: ""))
        })
    }

    // MARK: - Navigation
    
    func selectedRow(at indexPath: IndexPath) {
        if let vc = viewControllerToPush(forTappedIndexPath: indexPath) {
            if vc is ViewBillViewController {
                GoogleAnalytics.log(event: .billViewPastOfferComplete)
                AppRating.logRatingEvent()
            }
            
            if vc is UIAlertController || vc is BGEasyViewController {
                // UIAlertController (3rd party supplier case) and BGEasyViewController are modals
                present(vc, animated: true, completion: nil)
            } else {
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func viewControllerToPush(forTappedIndexPath indexPath: IndexPath) -> UIViewController? {
        let billStoryboard = UIStoryboard(name: "Bill", bundle: nil)
        
        func billingHistoryDetailsVc(_ billingHistoryItem: BillingHistoryItem) -> UIViewController {
            let vc = billStoryboard.instantiateViewController(withIdentifier: "billingHistoryDetails") as! BillingHistoryDetailsViewController
            vc.accountDetail = viewModel.accountDetail
            vc.billingHistoryItem = billingHistoryItem
            return vc
        }
        
        if indexPath.section == 0 { // Upcoming
            if indexPath.row == 0 && viewModel.shouldShowAutoPayCell {
                if viewModel.accountDetail.isBGEasy {
                    let vc = billStoryboard.instantiateViewController(withIdentifier: "BGEasy") as! BGEasyViewController
                    return vc
                } else if viewModel.accountDetail.isAutoPay {
                    if Environment.shared.opco == .bge {
                        let vc = billStoryboard.instantiateViewController(withIdentifier: "BGEAutoPay") as! BGEAutoPayViewController
                        vc.accountDetail = viewModel.accountDetail
                        vc.delegate = self
                        return vc
                    } else {
                        let vc = billStoryboard.instantiateViewController(withIdentifier: "AutoPay") as! AutoPayViewController
                        vc.accountDetail = viewModel.accountDetail
                        vc.delegate = self
                        return vc
                    }
                }
            } else {
                var selectedIndex = indexPath.row
                if viewModel.shouldShowAutoPayCell {
                    selectedIndex -= 1 // Everything is offset by AutoPay cell
                }
                
                let billingHistoryItem = viewModel.billingHistory!.upcoming[selectedIndex]
                if billingHistoryItem.status == .scheduled {
                    if billingHistoryItem.isAutoPayPayment { // Scheduled AutoPay payment
                        return billingHistoryDetailsVc(billingHistoryItem)
                    } else { // Normal scheduled payment
                        let vc = UIStoryboard(name: "Payment", bundle: nil).instantiateInitialViewController() as! MakePaymentViewController
                        vc.accountDetail = viewModel.accountDetail
                        vc.billingHistoryItem = billingHistoryItem
                        return vc
                    }
                } else { // It's a Pending Payment
                    return billingHistoryDetailsVc(billingHistoryItem)
                }
            }
        } else { // Past
            let billingHistoryItem = viewModel.viewingMoreActivity ?
                viewModel.billingHistory!.past[indexPath.row] :
                viewModel.billingHistory!.mostRecentSixMonths[indexPath.row]
            if billingHistoryItem.isBillPDF {
                if Environment.shared.opco == .comEd &&
                    viewModel.accountDetail.hasElectricSupplier &&
                    viewModel.accountDetail.isSingleBillOption {
                    let alertTitle = "You are enrolled with a Supplier who provides you with your electricity bill, including your ComEd delivery charges. Please reach out to your Supplier for your bill image."
                    let alertVc = UIAlertController(title: NSLocalizedString(alertTitle, comment: ""), message: nil, preferredStyle: .alert)
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    return alertVc
                } else {
                    let vc = billStoryboard.instantiateViewController(withIdentifier: "viewBill") as! ViewBillViewController
                    vc.viewModel.billDate = billingHistoryItem.date
                    return vc
                }
            } else {
                return billingHistoryDetailsVc(billingHistoryItem)
            }
        }
        return nil
    }
    
    @objc func viewAllUpcoming() {
        let storyboard = UIStoryboard(name: "Bill", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "billingHistory") as! BillingHistoryViewController
        vc.viewModel.accountDetail = viewModel.accountDetail
        vc.viewModel.billingHistory = BillingHistory(upcoming: viewModel.billingHistory!.upcoming, past: [])
        vc.viewModel.viewingMoreActivity = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func viewMorePast() {
        let storyboard = UIStoryboard(name: "Bill", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "billingHistory") as! BillingHistoryViewController
        vc.viewModel.accountDetail = viewModel.accountDetail
        vc.viewModel.billingHistory = BillingHistory(upcoming: [], past: viewModel.billingHistory!.past)
        vc.viewModel.viewingMoreActivity = true
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 && viewModel.shouldShowAutoPayCellDetailLabel {
            return UITableView.automaticDimension
        }
        return 60
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let billingHistory = viewModel.billingHistory, !viewModel.viewingMoreActivity else { return 0.01 }
        if section == 0 && billingHistory.upcoming.isEmpty && !viewModel.shouldShowAutoPayCell {
            return 0.01
        } else if section == 1 && billingHistory.past.isEmpty {
            return 0.01
        }
        return 45
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let billingHistory = viewModel.billingHistory, !viewModel.viewingMoreActivity else { return 0.01 }
        if section == 0, !billingHistory.upcoming.isEmpty || viewModel.shouldShowAutoPayCell {
            return 22
        }
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let billingHistory = viewModel.billingHistory, !viewModel.viewingMoreActivity else { return nil }
        if section == 0, !billingHistory.upcoming.isEmpty || viewModel.shouldShowAutoPayCell {
            return headerView(section: section)
        } else if section == 1 && !billingHistory.past.isEmpty {
            return headerView(section: section)
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard viewModel.billingHistory != nil, !viewModel.viewingMoreActivity else { return nil }
        
        let view = UIView()
        if section == 0 {
            view.backgroundColor = .softGray
        } else {
            view.backgroundColor = .clear
        }
        return view
    }
    
    private func headerView(section: Int) -> UIView {
        let view = UIView()
        
        view.backgroundColor = .white
        let label = UILabel()
        let button = UIButton(type: .system)
        
        label.text = section == 0 ? NSLocalizedString("UPCOMING", comment: "") : NSLocalizedString("PAST", comment: "")
        label.font = SystemFont.regular.of(textStyle: .subheadline)
        label.textColor = .deepGray
        
        var titleText = ""
        if section == 0 {
            if viewModel.billingHistory!.upcoming.count > (viewModel.shouldShowAutoPayCell ? 2 : 3) {
                let localizedText = NSLocalizedString("View All (%d)", comment: "")
                titleText = String(format: localizedText, viewModel.billingHistory!.upcoming.count)
            } else {
                button.isEnabled = false
                button.isAccessibilityElement = false
            }
        } else {
            if viewModel.billingHistory!.past.count > viewModel.billingHistory!.mostRecentSixMonths.count {
                titleText = NSLocalizedString("View More", comment: "")
            } else {
                button.isEnabled = false
                button.isAccessibilityElement = false
            }
        }
        
        button.setTitle(titleText, for: .normal)
        button.titleLabel?.font = SystemFont.semibold.of(textStyle: .subheadline)
        button.setTitleColor(.actionBlue, for: .normal)
        
        let selector = section == 0 ?
            #selector(BillingHistoryViewController.viewAllUpcoming) :
            #selector(BillingHistoryViewController.viewMorePast)
        button.addTarget(self, action: selector, for:.touchUpInside)
        
        let leadingSpace = UIView()
        leadingSpace.widthAnchor.constraint(equalToConstant: 20).isActive = true
        let trailingSpace = UIView()
        trailingSpace.widthAnchor.constraint(equalToConstant: 20).isActive = true
        
        let stackView = UIStackView(arrangedSubviews: [leadingSpace, label, UIView(), button, trailingSpace]).usingAutoLayout()
        
        stackView.axis = .horizontal
        stackView.alignment = .center
        
        view.addSubview(stackView)
        
        stackView.addTabletWidthConstraints(horizontalPadding: 0)
        stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        let divider = UIView().usingAutoLayout()
        divider.backgroundColor = .accentGray
        
        view.addSubview(divider)
        
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        divider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        divider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        divider.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        
        return view
    }
}

extension BillingHistoryViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let billingHistory = viewModel.billingHistory else { return 0 }
        
        if section == 0 {
            let upcoming = billingHistory.upcoming
            if viewModel.viewingMoreActivity {
                return upcoming.count
            } else if viewModel.shouldShowAutoPayCell {
                if upcoming.isEmpty {
                    return 1
                }
                return upcoming.count > 2 ? 3 : upcoming.count + 1
            } else {
                return upcoming.count > 3 ? 3 : upcoming.count
            }
        } else {
            if viewModel.viewingMoreActivity {
                return billingHistory.past.count
            } else {
                return billingHistory.past.count > billingHistory.mostRecentSixMonths.count ?
                    billingHistory.mostRecentSixMonths.count + 1 :
                    billingHistory.mostRecentSixMonths.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let billingHistoryItem: BillingHistoryItem
        if indexPath.section == 0 {
            if indexPath.row == 0 && viewModel.shouldShowAutoPayCell {
                return autoPayTableViewCell(indexPath: indexPath)
            } else {
                let row = viewModel.shouldShowAutoPayCell ? indexPath.row - 1 : indexPath.row
                billingHistoryItem = viewModel.billingHistory!.upcoming[row]
            }
        } else {
            if viewModel.viewingMoreActivity {
                billingHistoryItem = viewModel.billingHistory!.past[indexPath.row]
            } else {
                if indexPath.row != viewModel.billingHistory!.mostRecentSixMonths.count {
                    billingHistoryItem = viewModel.billingHistory!.mostRecentSixMonths[indexPath.row]
                } else {
                    return viewMoreTableViewCell(indexPath: indexPath)
                }
            }
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: BillingHistoryTableViewCell.className, for: indexPath)
            as! BillingHistoryTableViewCell
        cell.configureWith(item: billingHistoryItem)
        cell.didSelect.drive(onNext: { [weak self] in
            self?.selectedRow(at: indexPath)
        }).disposed(by: cell.disposeBag)
        return cell
    }
    
    private func viewMoreTableViewCell(indexPath: IndexPath) -> UITableViewCell {
        let button = UIButton(type: .system)
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        button.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
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
    
    private func autoPayTableViewCell(indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "AutoPayCell")
        cell.selectionStyle = .none
        
        let innerContentView = ButtonControl(frame: .zero)
        innerContentView.translatesAutoresizingMaskIntoConstraints = false
        innerContentView.backgroundColorOnPress = .accentGray
        
        innerContentView.rx.touchUpInside.asDriver()
            .drive(onNext: { [weak self] in
                self?.selectedRow(at: indexPath)
            })
            .disposed(by: disposeBag)
        
        let titleLabel = UILabel()
        titleLabel.textColor = .blackText
        titleLabel.font = SystemFont.medium.of(textStyle: .headline)
        let titleText: String
        if viewModel.accountDetail.isAutoPay {
            titleText = NSLocalizedString("You are enrolled in AutoPay", comment: "")
        } else {
            titleText = NSLocalizedString("You are enrolled in BGEasy", comment: "")
        }
        titleLabel.text = titleText
        
        let detailLabel = UILabel()
        detailLabel.textColor = .deepGray
        detailLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        detailLabel.text = NSLocalizedString("Your upcoming automatic payment will be\nvisible once your next bill is generated.", comment: "")
        detailLabel.numberOfLines = 0
        detailLabel.isHidden = true
        
        let carat = UIImageView(image: #imageLiteral(resourceName: "ic_caret"))
        carat.contentMode = .scaleAspectFit
        
        let labelStack = UIStackView(arrangedSubviews: [titleLabel, detailLabel]).usingAutoLayout()
        labelStack.axis = .vertical
        labelStack.alignment = .fill
        labelStack.distribution = .equalSpacing
        labelStack.spacing = 5
        labelStack.isUserInteractionEnabled = false
        
        let stackView = UIStackView(arrangedSubviews: [labelStack, UIView(), carat]).usingAutoLayout()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.isUserInteractionEnabled = false
        
        innerContentView.addSubview(stackView)
        
        var a11yLabel = titleText
        var topConstant: CGFloat = 0; var bottomConstant: CGFloat = 0.0
        if viewModel.shouldShowAutoPayCellDetailLabel {
            detailLabel.isHidden = false
            a11yLabel += ", \(detailLabel.text!)"
            topConstant = 13
            bottomConstant = -24
        }
        
        innerContentView.accessibilityLabel = a11yLabel
        
        stackView.topAnchor.constraint(equalTo: innerContentView.topAnchor, constant: topConstant).isActive = true
        stackView.bottomAnchor.constraint(equalTo: innerContentView.bottomAnchor, constant: bottomConstant).isActive = true
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

extension BillingHistoryViewController: AutoPayViewControllerDelegate {
    
    func autoPayViewController(_ autoPayViewController: UIViewController, enrolled: Bool) {
        let message = enrolled ? NSLocalizedString("Enrolled in AutoPay", comment: ""): NSLocalizedString("Unenrolled from AutoPay", comment: "")
        showDelayedToast(withMessage: message)
        
        if enrolled {
            GoogleAnalytics.log(event: .autoPayEnrollComplete)
        } else {
            GoogleAnalytics.log(event: .autoPayUnenrollComplete)
        }
    }
    
}

extension BillingHistoryViewController: BGEAutoPayViewControllerDelegate {
    
    func BGEAutoPayViewController(_ BGEAutoPayViewController: BGEAutoPayViewController, didUpdateWithToastMessage message: String) {
        showDelayedToast(withMessage: message)
    }
}

// TODO: Uncomment this, and the `registerForPreviewing` call in viewDidLoad() to enable 3D Touch

//extension BillingHistoryViewController: UIViewControllerPreviewingDelegate {
//
//    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
//        if let indexPath = tableView.indexPathForRow(at: location) {
//            let vc = viewControllerToPush(forTappedIndexPath: indexPath)
//            if vc is UIAlertController { // Catches 3rd party supplier case - no peek
//                return nil
//            }
//            previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
//            return vc
//        }
//        return nil
//    }
//
//    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
//        if viewControllerToCommit is ViewBillViewController {
//            Analytics.log(event: .billViewPastOfferComplete)
//            AppRating.logRatingEvent()
//        }
//        navigationController?.pushViewController(viewControllerToCommit, animated: true)
//    }
//}
