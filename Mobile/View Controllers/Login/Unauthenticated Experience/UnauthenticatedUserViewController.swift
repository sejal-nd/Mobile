//
//  UnauthenticatedUserViewController.swift
//  Mobile
//
//  Created by Junze Liu on 7/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import Lottie

class UnauthenticatedUserViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var lottieView: UIView!
    @IBOutlet weak var textLabel: UILabel!

    @IBOutlet weak var loginRegisterButton: UIButton!

    @IBOutlet weak var reportAnOutageButton: DisclosureButton!
    @IBOutlet weak var checkMyOutageStatusButton: DisclosureButton!
    @IBOutlet weak var viewOutageMapButton: DisclosureButton!
    @IBOutlet weak var contactUsButton: DisclosureButton!
    @IBOutlet weak var policiesTermsButton: DisclosureButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .primaryColor

        scrollView.indicatorStyle = .white
        loginRegisterButton.titleLabel!.font =  OpenSans.bold.of(textStyle: .title1)
        textLabel.font =  OpenSans.regular.of(textStyle: .subheadline)

        let animationView = LOTAnimationView(name: "uu_otp")
        animationView.frame = CGRect(x: 0, y: 0, width: 230, height: 180)
        animationView.contentMode = .scaleAspectFill
        animationView.loopAnimation = true

        // put the animation at the center top screen
        var center = lottieView.center
        center.x = self.view.center.x;
        animationView.center = center;

        lottieView.addSubview(animationView)
        animationView.play()

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
        lottieView.isAccessibilityElement = true
        lottieView.accessibilityLabel = NSLocalizedString("Animation showing home screen payment", comment: "")

        textLabel.accessibilityLabel = textLabel.text
        
        reportAnOutageButton.accessibilityLabel = NSLocalizedString("Report an outage", comment: "")
        checkMyOutageStatusButton.accessibilityLabel = NSLocalizedString("Check my outage status", comment: "")
        viewOutageMapButton.accessibilityLabel = NSLocalizedString("View outage map", comment: "")
        contactUsButton.accessibilityLabel = NSLocalizedString("Contact us", comment: "")
        policiesTermsButton.accessibilityLabel = NSLocalizedString("Policies and terms", comment: "")
    }

    @IBAction func onLoginRegisterPress(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UnauthenticatedOutageValidateAccountViewController {
            switch(segue.identifier) {
            case "reportOutageValidateAccount"?:
                Analytics().logScreenView(AnalyticsPageView.ReportAnOutageUnAuthOffer.rawValue)
                vc.analyticsSource = AnalyticsOutageSource.Report
                break
            case "checkOutageValidateAccount"?:
                Analytics().logScreenView(AnalyticsPageView.OutageStatusUnAuthOffer.rawValue)
                vc.analyticsSource = AnalyticsOutageSource.Status
                break
            default:
                break
            }
        } else if let vc = segue.destination as? OutageMapViewController {
            vc.unauthenticatedExperience = true
            Analytics().logScreenView(AnalyticsPageView.ViewOutageMapGuestMenu.rawValue)
        } else if let vc = segue.destination as? ContactUsViewController {
            vc.unauthenticatedExperience = true
        }
    }
}
