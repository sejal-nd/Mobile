//
//  UnauthenticatedUserViewController.swift
//  Mobile
//
//  Created by Junze Liu on 7/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class UnauthenticatedUserViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var fakeNavBarView: UIView! {
        didSet {
            fakeNavBarView.backgroundColor = .primaryColor
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var headerView: UIView! {
        didSet {
            headerView.backgroundColor = .primaryColor
        }
    }
    
    @IBOutlet weak var headerContentView: ButtonControl! {
        didSet {
            headerContentView.layer.cornerRadius = 10.0
            headerContentView.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
            headerContentView.accessibilityLabel = NSLocalizedString("Sign in / Register to pay. Includes features like the ability to effortlessly pay your bill from the home screen, auto pay, and payment activity.", comment: "")
        }
    }
    
    @IBOutlet weak var headerViewTitleLabel: UILabel! {
        didSet {
            headerViewTitleLabel.font = OpenSans.semibold.of(textStyle: .headline)
            headerViewTitleLabel.textColor = .actionBlue
        }
    }
    
    @IBOutlet weak var headerViewDescriptionLabel: UILabel! {
        didSet {
            headerViewDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
            headerViewDescriptionLabel.textColor = .blackText
        }
    }
    
    let billingVideosUrl: URL = {
        switch Environment.shared.opco {
        case .bge:
            return URL(string: "https://www.youtube.com/playlist?list=PLqZel3RCfgtuTtDFCBmFQ1xNLzI7H6J4m")!
        case .peco:
            return URL(string: "https://www.youtube.com/playlist?list=PLyIWX4qmx-oyOoGkxaU8A-ye-oQ0vrzi-")!
        case .comEd:
            return URL(string: "https://www.youtube.com/playlist?list=PL-PMuxD2q_DJFPh156UmI43FMbwQFIQ-N")!
        }
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: TitleTableViewHeaderView.className, bundle: nil), forHeaderFooterViewReuseIdentifier: TitleTableViewHeaderView.className)
        tableView.register(UINib(nibName: TitleTableViewCell.className, bundle: nil), forCellReuseIdentifier: TitleTableViewCell.className)

        view.backgroundColor = .primaryColor
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        headerView.frame.size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        tableView.tableHeaderView = headerView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    @IBAction func onBackPress() {
        navigationController?.popViewController(animated: true)
    }

    @IBAction private func loginRegisterPress(_ sender: ButtonControl) {
        navigationController?.popViewController(animated: true)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UnauthenticatedOutageValidateAccountViewController {
            switch(segue.identifier) {
            case "reportOutageValidateAccount"?:
                GoogleAnalytics.log(event: .reportAnOutageUnAuthOffer)
                vc.analyticsSource = .report
                break
            case "checkOutageValidateAccount"?:
                GoogleAnalytics.log(event: .outageStatusUnAuthOffer)
                vc.analyticsSource = .status
                break
            default:
                break
            }
        } else if let vc = segue.destination as? OutageMapViewController {
            vc.unauthenticatedExperience = true
            GoogleAnalytics.log(event: .viewOutageMapGuestMenu)
        } else if let vc = segue.destination as? ContactUsViewController {
            vc.unauthenticatedExperience = true
        }
    }
}

extension UnauthenticatedUserViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 3 : 4
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TitleTableViewCell.className, for: indexPath) as? TitleTableViewCell else { return UITableViewCell() }
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                cell.configure(image: #imageLiteral(resourceName: "ic_reportoutage"), text: NSLocalizedString("Report Outage", comment: ""))
            case 1:
                cell.configure(image: #imageLiteral(resourceName: "ic_checkoutage"), text: NSLocalizedString("Check My Outage Status", comment: ""))
            case 2:
                cell.configure(image: #imageLiteral(resourceName: "ic_mapoutage"), text: NSLocalizedString("View Outage Map", comment: ""))
            default:
                return UITableViewCell()
            }
        case 1:
            switch indexPath.row {
            case 0:
                cell.configure(image: #imageLiteral(resourceName: "ic_moreupdates"), text: NSLocalizedString("News and Updates", comment: ""))
            case 1:
                cell.configure(image: #imageLiteral(resourceName: "ic_morecontact"), text: NSLocalizedString("Contact Us", comment: ""))
            case 2:
                cell.configure(image: #imageLiteral(resourceName: "ic_morevideo.pdf"), text: NSLocalizedString("Billing Videos", comment: ""))
            case 3:
                cell.configure(image: #imageLiteral(resourceName: "ic_moretos"), text: NSLocalizedString("Policies and Terms", comment: ""))
            default:
                return UITableViewCell()
            }
        default:
            return UITableViewCell()
        }
        
        cell.contentContainerView.rx.touchUpInside.asDriver().drive(onNext: { [weak self] _ in
            self?.tableViewDidSelectRow(at: indexPath)
        }).disposed(by: cell.disposeBag)
        
        return cell
    }
    
    func tableViewDidSelectRow(at indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "reportOutageValidateAccount", sender: nil)
            case 1:
                performSegue(withIdentifier: "checkOutageValidateAccount", sender: nil)
            case 2:
                performSegue(withIdentifier: "outageMapSegue", sender: nil)
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "updatesSegue", sender: nil)
            case 1:
                performSegue(withIdentifier: "contactUsSegue", sender: nil)
            case 2:
                UIApplication.shared.openUrlIfCan(billingVideosUrl)
            case 3:
                performSegue(withIdentifier: "termPoliciesSegue", sender: nil)
            default:
                break
            }
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TitleTableViewHeaderView.className) as? TitleTableViewHeaderView else { return nil }
        
        switch section {
        case 0:
            headerView.configure(text: NSLocalizedString("Outage", comment: ""))
        case 1:
            headerView.configure(text: NSLocalizedString("Help & Support", comment: ""))
        default:
            break
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 21
    }
    
}

