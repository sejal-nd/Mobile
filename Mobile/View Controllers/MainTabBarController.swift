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
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        UserDefaults.standard.set(true, forKey: UserDefaultKeys.inMainApp)
        
        tabBar.barTintColor = .white
        tabBar.tintColor = .primaryColor
        tabBar.isTranslucent = false
        delegate = self
        
        setButtonStates(itemTag: 1)
        
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
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        setButtonStates(itemTag: item.tag)
    }
    
    // Needed for programmatically changing tabs
    override var selectedIndex: Int {
        didSet {
            setButtonStates(itemTag: selectedIndex + 1)
        }
    }
    
    func navigateToUsage(selectedBar: UsageViewModel.BarGraphSelection? = nil, isGas: Bool, isPreviousBill: Bool) {
        selectedIndex = 3
        
        guard let bar = selectedBar,
            let usageNavCtl = viewControllers?[3] as? MainBaseNavigationController,
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
        
        guard let moreNavCtl = viewControllers?[4] as? MainBaseNavigationController,
            let moreVC = moreStoryboard.instantiateInitialViewController(),
            let alertsVC = alertsStoryboard.instantiateInitialViewController()
            else { return }
        
        moreNavCtl.viewControllers = [moreVC, alertsVC]
    }
    
    func navigateToAlertPreferences() {
        selectedIndex = 4
        
        let moreStoryboard = UIStoryboard(name: "More", bundle: nil)
        let alertsStoryboard = UIStoryboard(name: "Alerts", bundle: nil)
        
        guard let moreNavCtl = viewControllers?[4] as? MainBaseNavigationController,
            let moreVC = moreStoryboard.instantiateInitialViewController(),
            let alertsVC = alertsStoryboard.instantiateInitialViewController() as? AlertsViewController
            else { return }
        
        alertsVC.shortcutToPrefs = true
        moreNavCtl.viewControllers = [moreVC, alertsVC]
    }
    
    func setButtonStates (itemTag: Int) {
        for tab in tabBar.items! {
            if tab.tag == itemTag {
                tab.setTitleTextAttributes([.font: selectedTitleFont, .foregroundColor: selectedTitleColor], for: .normal)
            } else {
                tab.setTitleTextAttributes([.font: normalTitleFont, .foregroundColor: normalTitleColor], for: .normal)
            }
        }
    }
}

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let selectedNavVC = viewController as? UINavigationController,
            let selectedVC = selectedNavVC.viewControllers.first,
            selectedNavVC == previousViewController else {
                // Different tab tapped
                previousViewController = viewController
                
                switch selectedIndex {
                case 0:
                    Analytics.log(event: .tabHome)
                case 1:
                    Analytics.log(event: .tabBill)
                case 2:
                    Analytics.log(event: .tabOutage)
                case 3:
                    Analytics.log(event: .tabUsage)
                case 4:
                    Analytics.log(event: .tabMore)
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
