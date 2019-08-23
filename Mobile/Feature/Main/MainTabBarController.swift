//
//  MainTabBarController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class MainTabBarController: UITabBarController {
    
    lazy var previousViewController = viewControllers?.first
    
    let disposeBag = DisposeBag()
    
    let normalTitleFont = SystemFont.regular.of(textStyle: .caption2)
    let selectedTitleFont = SystemFont.bold.of(textStyle: .caption2)
    
    let normalTitleColor = UIColor.middleGray
    let selectedTitleColor = UIColor.primaryColorADA
        
    
    // MARK: - View Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        style()
        
        configureTabBar()
    }
        
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let itemIndex = tabBar.items?.firstIndex(of: item), tabBar.subviews.count > itemIndex + 1, let imageView = tabBar.subviews[itemIndex + 1].subviews.compactMap ({ $0 as? UIImageView }).first else {
            return
        }

        animateTabBarItem(imageView: imageView)
    }
    
    
    // MARK: - Helper
    
    private func style() {
        tabBar.barTintColor = .white
        tabBar.tintColor = .primaryColor
        tabBar.isTranslucent = false
    }
    
    private func configureTabBar() {
        UserDefaults.standard.set(true, forKey: UserDefaultKeys.inMainApp)
        
        delegate = self
                
        if UserDefaults.standard.bool(forKey: UserDefaultKeys.pushNotificationReceived) {
            // If push notification was tapped and the user logged in within 5 minutes, take them straight to alerts
            if let timestamp = UserDefaults.standard.object(forKey: UserDefaultKeys.pushNotificationReceivedTimestamp) as? Date, Float(timestamp.timeIntervalSinceNow) >= -300 {
                navigateToAlerts()
            }
            UserDefaults.standard.set(false, forKey: UserDefaultKeys.pushNotificationReceived)
            UserDefaults.standard.removeObject(forKey: UserDefaultKeys.pushNotificationReceivedTimestamp)
        }
        
        NotificationCenter.default.rx.notification(.didTapOnPushNotification, object: nil)
            .asObservable()
            .subscribe(onNext: { [weak self] _ in
                self?.navigateToAlerts()
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(.didTapOnShortcutItem, object: nil)
            .asObservable()
            .subscribe(onNext: { [weak self] notification in
                guard let self = self else { return }
                guard let shortcutItem = notification.object as? ShortcutItem else {
                    return
                }
                
                switch shortcutItem {
                case .payBill:
                    self.selectedIndex = 1
                    if let navVC = self.viewControllers?[1] as? UINavigationController,
                        let billVC = navVC.viewControllers.first as? BillViewController {
                        billVC.shortcutItem = .payBill
                    }
                case .reportOutage:
                    self.selectedIndex = 2
                    if let navVC = self.viewControllers?[2] as? UINavigationController,
                        let outageVC = navVC.viewControllers.first as? OutageViewController {
                        outageVC.shortcutItem = .reportOutage
                    }
                case .viewUsageOptions:
                    self.selectedIndex = 3
                case .alertPreferences:
                    self.navigateToAlertPreferences()
                case .none:
                    break
                }
            })
            .disposed(by: disposeBag)
    }
    
    /// Animate TabBar Item
    private func animateTabBarItem(imageView: UIImageView) {
        // Scale Up Animation
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            imageView.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
            
            // Scale Down Animation
            UIView.animate(withDuration: 0.5, delay: 0.2, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
                imageView.transform = .identity
            }, completion: nil)
        }, completion: nil)
    }

    func navigateToUsage(selectedBar: UsageViewModel.BarGraphSelection? = nil, isGas: Bool, isPreviousBill: Bool) {
        selectedIndex = 3
        
        guard let bar = selectedBar,
            let usageNavCtl = viewControllers?[3] as? UINavigationController,
            let usageVC = usageNavCtl.viewControllers.first as? UsageViewController
            else { return }
        
        // initialSelection is effective if the VC has just been initialized by this navigation.
        // (first time visiting the tab since launch)
        usageVC.initialSelection = (bar, isGas, isPreviousBill)
        
        // this is effective if the user has already visited the tab and the view has already been loaded.
        usageVC.selectLastYearPreviousBill(isPreviousBill: isPreviousBill)
        usageVC.selectBar(bar, gas: isGas)
    }
    
    func navigateToAlerts() {
        selectedIndex = 4
        
        let moreStoryboard = UIStoryboard(name: "More", bundle: nil)
        let alertsStoryboard = UIStoryboard(name: "Alerts", bundle: nil)
        
        guard let moreNavCtl = viewControllers?[4] as? UINavigationController,
            let moreVC = moreStoryboard.instantiateInitialViewController(),
            let alertsVC = alertsStoryboard.instantiateInitialViewController()
            else { return }
        
        moreNavCtl.viewControllers = [moreVC, alertsVC]
    }
    
    func navigateToAlertPreferences() {
        selectedIndex = 4
        
        let moreStoryboard = UIStoryboard(name: "More", bundle: nil)
        let alertsStoryboard = UIStoryboard(name: "Alerts", bundle: nil)
        
        guard let moreNavCtl = viewControllers?[4] as? UINavigationController,
            let moreVC = moreStoryboard.instantiateInitialViewController(),
            let alertsVC = alertsStoryboard.instantiateInitialViewController() as? AlertsViewController
            else { return }
        
        alertsVC.shortcutToPrefs = true
        moreNavCtl.viewControllers = [moreVC, alertsVC]
    }
}


// MARK: - TabBar Delegate

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let selectedNavVC = viewController as? UINavigationController,
            let selectedVC = selectedNavVC.viewControllers.first,
            selectedNavVC == previousViewController else {
                // Different tab tapped
                previousViewController = viewController
                
                switch selectedIndex {
                case 0:
                    GoogleAnalytics.log(event: .tabHome)
                case 1:
                    GoogleAnalytics.log(event: .tabBill)
                case 2:
                    GoogleAnalytics.log(event: .tabOutage)
                case 3:
                    GoogleAnalytics.log(event: .tabUsage)
                case 4:
                    GoogleAnalytics.log(event: .tabMore)
                default:
                    break
                }
                
                return
        }
        
        // Current tab tapped again. Scroll to top.
        previousViewController = selectedNavVC
        
        if let vc = selectedVC as? AccountPickerViewController {
            vc.scrollView?.setContentOffset(.zero, animated: true)
        } else if let vc = selectedVC as? MoreViewController {
            vc.tableView?.setContentOffset(.zero, animated: true)
        }
    }
}
