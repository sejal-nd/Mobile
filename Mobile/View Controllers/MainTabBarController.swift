//
//  MainTabBarController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class MainTabBarController: UITabBarController {
    
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
        
        setButtonStates(itemTag: 1)
        
        if UserDefaults.standard.bool(forKey: UserDefaultKeys.pushNotificationReceived) {
            // If push notification was tapped and the user logged in within 5 minutes, take them straight to alerts
            if let timestamp = UserDefaults.standard.object(forKey: UserDefaultKeys.pushNotificationReceivedTimestamp) as? Date, Float(timestamp.timeIntervalSinceNow) >= -300 {
                selectedIndex = 3
            }
            UserDefaults.standard.set(false, forKey: UserDefaultKeys.pushNotificationReceived)
            UserDefaults.standard.removeObject(forKey: UserDefaultKeys.pushNotificationReceivedTimestamp)
        }
        
        NotificationCenter.default.rx.notification(.DidTapOnPushNotification, object: nil)
            .asObservable()
            .subscribe(onNext: { [weak self] _ in
                self?.selectedIndex = 3
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(.DidTapOnShortcutItem, object: nil)
            .asObservable()
            .subscribe(onNext: { [weak self] notification in
                guard let `self` = self else { return }
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
                    self.selectedIndex = 0
                    if let navVC = self.viewControllers?.first as? UINavigationController,
                        let homeVC = navVC.viewControllers.first as? HomeViewController {
                        homeVC.shortcutItem = .viewUsageOptions
                    }
                case .none:
                    break
                }
            })
            .disposed(by: disposeBag)
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item.title != NSLocalizedString("Outage", comment: "") {
            ServiceFactory.createOutageService().clearReportedOutageStatus(accountNumber: nil) // Passing nil clears all
        }
        setButtonStates(itemTag: item.tag)
    }
    
    // Needed for programmatically changing tabs
    override var selectedIndex: Int {
        didSet {
            setButtonStates(itemTag: selectedIndex + 1)
        }
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
