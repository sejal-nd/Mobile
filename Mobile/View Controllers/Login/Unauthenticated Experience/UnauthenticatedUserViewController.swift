//
//  UnauthenticatedUserViewController.swift
//  Mobile
//
//  Created by Junze Liu on 7/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

class UnauthenticatedUserViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
    
    @IBOutlet weak var headerView: UIView! {
        didSet {
            headerView.layer.cornerRadius = 10.0
            headerView.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 6)
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(loginRegisterPress(_:)))
            headerView.addGestureRecognizer(tap)
        }
    }
    @IBOutlet weak var headerViewTitleLabel: UILabel! {
        didSet {
            headerViewTitleLabel.font = OpenSans.semibold.of(size: 16)
            headerViewTitleLabel.textColor = .primaryColor
        }
    }
    @IBOutlet weak var headerViewDescriptionLabel: UILabel! {
        didSet {
            headerViewDescriptionLabel.font = OpenSans.regular.of(size: 12)
            headerViewDescriptionLabel.textColor = .blackText
        }
    }
    
    

    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "TitleTableViewHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "TitleTableViewHeaderView")
        tableView.register(UINib(nibName: "HairlineFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: "HairlineFooterView")
        tableView.register(UINib(nibName: "TitleTableViewCell", bundle: nil), forCellReuseIdentifier: "TitleTableViewCell")

        view.backgroundColor = .primaryColor

        accessibilitySetup()
    }

    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.barStyle = .black // Needed for white status bar
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.isTranslucent = true

        setNeedsStatusBarAppearanceUpdate()

        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    private func accessibilitySetup() {
        headerViewTitleLabel.accessibilityLabel = headerViewTitleLabel.text
        headerViewDescriptionLabel.accessibilityLabel = headerViewDescriptionLabel.text
    }

    @objc private func loginRegisterPress(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UnauthenticatedOutageValidateAccountViewController {
            switch(segue.identifier) {
            case "reportOutageValidateAccount"?:
                Analytics.log(event: .reportAnOutageUnAuthOffer)
                vc.analyticsSource = AnalyticsOutageSource.report
                break
            case "checkOutageValidateAccount"?:
                Analytics.log(event: .outageStatusUnAuthOffer)
                vc.analyticsSource = AnalyticsOutageSource.status
                break
            default:
                break
            }
        } else if let vc = segue.destination as? OutageMapViewController {
            vc.unauthenticatedExperience = true
            Analytics.log(event: .viewOutageMapGuestMenu)
        } else if let vc = segue.destination as? ContactUsViewController {
            vc.unauthenticatedExperience = true
        }
    }
}
