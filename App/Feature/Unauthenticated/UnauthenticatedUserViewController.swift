//
//  UnauthenticatedUserViewController.swift
//  Mobile
//
//  Created by Junze Liu on 7/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import SwiftUI

class UnauthenticatedUserViewController: UIViewController, UIGestureRecognizerDelegate {
    
    let startServiceWebURL: URL? = {
        switch Configuration.shared.opco {
        case .bge:
            return URL(string: "https://\(Configuration.shared.associatedDomain)/CustomerServices/service/landing?flowtype=startservice&utm_source=startlink&utm_medium=mobileapp&utm_campaign=ssmredirect")
        default:
            return nil
        }
    }()

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
            headerContentView.accessibilityLabel = NSLocalizedString("Sign in / Register to pay. Includes features like the ability to effortlessly pay your bill from the home screen, auto pay, and payment activity.", comment: "")
        }
    }
    
    @IBOutlet weak var headerViewTitleLabel: UILabel! {
        didSet {
            headerViewTitleLabel.font = SystemFont.semibold.of(textStyle: .callout)
            headerViewTitleLabel.textColor = .primaryBlue
        }
    }
    
    @IBOutlet weak var headerViewDescriptionLabel: UILabel! {
        didSet {
            headerViewDescriptionLabel.font = .caption1
            headerViewDescriptionLabel.textColor = .blackText
        }
    }
    
    let billingVideosUrl: URL? = {
        return URL(string: FeatureFlagUtility.shared.string(forKey: .billingVideoURL))
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // Feature Flag Value
    private var outageMapURLString = FeatureFlagUtility.shared.string(forKey: .outageMapURL)
    
    private var streetlightOutageMapURLString = FeatureFlagUtility.shared.string(forKey: .streetlightMapURL)
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
        
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
        FirebaseUtility.logEvent(.unauth(parameters: [.sign_in_register_press]))

        navigationController?.popViewController(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? OutageMapViewController {
            vc.unauthenticatedExperience = true
            vc.hasPressedStreetlightOutageMapButton = segue.identifier == "streetlightOutageMapSegue" ? true : false
        }
    }
    
    
    // MARK: - Helper
    
    private func configureTableView() {
        tableView.register(UINib(nibName: TitleTableViewHeaderView.className, bundle: nil), forHeaderFooterViewReuseIdentifier: TitleTableViewHeaderView.className)
        tableView.register(UINib(nibName: TitleTableViewCell.className, bundle: nil), forCellReuseIdentifier: TitleTableViewCell.className)
        tableView.accessibilityLabel = "guestTableView"
        
        FeatureFlagUtility.shared.loadingDoneCallback = { [weak self] in
            self?.outageMapURLString = FeatureFlagUtility.shared.string(forKey: .outageMapURL)
            self?.streetlightOutageMapURLString = FeatureFlagUtility.shared.string(forKey: .streetlightMapURL)
            self?.tableView.reloadRows(at: [IndexPath(row: 2, section: 0), IndexPath(row: 3, section: 0)], with: .automatic)
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate Method Implementations
extension UnauthenticatedUserViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
                
        return FeatureFlagUtility.shared.bool(forKey: .hasUnauthenticatedISUM) ? 3 : 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if FeatureFlagUtility.shared.bool(forKey: .hasUnauthenticatedISUM) && section == 1 {
            return 2
        }
        return 4
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0, indexPath.row == 2, outageMapURLString.isEmpty {
            return 0
        } else if indexPath.section == 0, indexPath.row == 3, Configuration.shared.opco == .peco {
            return 0
        } else if indexPath.section == 0, indexPath.row == 3, streetlightOutageMapURLString.isEmpty {
            return 0
        } else if indexPath.section == 1, indexPath.row == 2, Configuration.shared.opco.isPHI, billingVideosUrl == nil {
            return 0
        }
        
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TitleTableViewCell.className, for: indexPath) as? TitleTableViewCell else { return UITableViewCell() }
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                cell.configure(image: UIImage(named: "ic_reportoutagewhite"), text: NSLocalizedString("Report Outage", comment: ""))
            case 1:
                cell.configure(image: UIImage(named: "ic_checkoutage"), text: NSLocalizedString("Check My Outage Status", comment: ""))
            case 2:
                cell.configure(image: UIImage(named: "ic_mapoutagewhite"), text: NSLocalizedString("View Outage Map", comment: ""))
            case 3:
                let text = Configuration.shared.opco.isPHI ? NSLocalizedString("Report Street Light Problem", comment: "") : NSLocalizedString("Report Street Light Outage", comment: "")
                cell.configure(image: UIImage(named: "ic_streetlightoutage_white"), text: text)
            default:
                return UITableViewCell()
            }
        case 1:
            switch indexPath.row {
            case 0:
                if FeatureFlagUtility.shared.bool(forKey: .hasUnauthenticatedISUM) {
                    cell.configure(image: UIImage(named: "ic_more_isum_start"), text: NSLocalizedString("Start Service", comment: ""))
                } else {
                    cell.configure(image: UIImage(named: "ic_moreupdates"), text: NSLocalizedString("News and Updates", comment: ""))
                }
            case 1:
                if FeatureFlagUtility.shared.bool(forKey: .hasUnauthenticatedISUM) {
                    cell.configure(image: UIImage(named: "ic_more_isum_move"), text: NSLocalizedString("Move Service", comment: ""))
                } else {
                    cell.configure(image: UIImage(named: "ic_morecontact"), text: NSLocalizedString("Contact Us", comment: ""))
                }
            case 2:
                cell.configure(image: UIImage(named: "ic_morevideo"), text: NSLocalizedString("Billing Videos", comment: ""))
            case 3:
                cell.configure(image: UIImage(named: "ic_moretos"), text: NSLocalizedString("Policies and Terms", comment: ""))
            default:
                return UITableViewCell()
            }
        case 2:
            switch indexPath.row {
            case 0:
                cell.configure(image: UIImage(named: "ic_moreupdates"), text: NSLocalizedString("News and Updates", comment: ""))
            case 1:
                cell.configure(image: UIImage(named: "ic_morecontact"), text: NSLocalizedString("Contact Us", comment: ""))
            case 2:
                cell.configure(image: UIImage(named: "ic_morevideo"), text: NSLocalizedString("Billing Videos", comment: ""))
            case 3:
                cell.configure(image: UIImage(named: "ic_moretos"), text: NSLocalizedString("Policies and Terms", comment: ""))
            default:
                return UITableViewCell()
            }
        default:
            return UITableViewCell()
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                FirebaseUtility.logEvent(.unauth(parameters: [.report_outage_press]))
                performSegue(withIdentifier: "reportOutageValidateAccount", sender: nil)
            case 1:
                FirebaseUtility.logEvent(.unauth(parameters: [.view_outage_press]))
                performSegue(withIdentifier: "checkOutageValidateAccount", sender: nil)
            case 2:
                performSegue(withIdentifier: "outageMapSegue", sender: nil)
            case 3:
                performSegue(withIdentifier: "streetlightOutageMapSegue", sender: nil)
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                if FeatureFlagUtility.shared.bool(forKey: .hasUnauthenticatedISUM) {
                    UIApplication.shared.openUrlIfCan(startServiceWebURL)
                } else {
                    navigationController?.pushViewController(UIHostingController(rootView: OpcoUpdatesView()), animated: true)
                }
            case 1:
                if FeatureFlagUtility.shared.bool(forKey: .hasUnauthenticatedISUM) {
                    performSegue(withIdentifier: "unauthIDVerificationSegue", sender: nil)
                } else {
                    navigationController?.pushViewController(OpcoUpdatesHostingController(rootView: ContactView(), shouldShowLargeTitle: true), animated: true)
                }
            case 2:
                FirebaseUtility.logEvent(.unauth(parameters: [.billing_videos]))
                
                UIApplication.shared.openUrlIfCan(billingVideosUrl)
            case 3:
                performSegue(withIdentifier: "termPoliciesSegue", sender: nil)
            default:
                break
            }
            
        case 2:
            switch indexPath.row {
            case 0:
                navigationController?.pushViewController(UIHostingController(rootView: OpcoUpdatesView()), animated: true)
            case 1:
                navigationController?.pushViewController(OpcoUpdatesHostingController(rootView: ContactView(), shouldShowLargeTitle: true), animated: true)
            case 2:
                FirebaseUtility.logEvent(.unauth(parameters: [.billing_videos]))
                
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
            if FeatureFlagUtility.shared.bool(forKey: .hasUnauthenticatedISUM) {
                headerView.configure(text: NSLocalizedString("Moving", comment: ""))
            } else {
                headerView.configure(text: NSLocalizedString("Help & Support", comment: ""))
            }
        case 2:
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

