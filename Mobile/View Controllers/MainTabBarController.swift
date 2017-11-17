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
        
        UserDefaults.standard.set(true, forKey: UserDefaultKeys.InMainApp)
        
        tabBar.barTintColor = .white
        tabBar.tintColor = .primaryColor
        tabBar.isTranslucent = false
        
        setButtonStates(itemTag: 1)
        
        if UserDefaults.standard.bool(forKey: UserDefaultKeys.PushNotificationReceived) {
            // If push notification was tapped and the user logged in within 5 minutes, take them straight to alerts
            if let timestamp = UserDefaults.standard.object(forKey: UserDefaultKeys.PushNotificationReceivedTimestamp) as? Date, Float(timestamp.timeIntervalSinceNow) >= -300 {
                selectedIndex = 3
            }
            UserDefaults.standard.set(false, forKey: UserDefaultKeys.PushNotificationReceived)
            UserDefaults.standard.removeObject(forKey: UserDefaultKeys.PushNotificationReceivedTimestamp)
        }
        
        NotificationCenter.default.rx.notification(.DidTapOnPushNotification, object: nil)
            .asObservable()
            .subscribe(onNext: { [weak self] _ in
                self?.selectedIndex = 3
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
                tab.setTitleTextAttributes([NSFontAttributeName: selectedTitleFont, NSForegroundColorAttributeName: selectedTitleColor], for: .normal)
            } else {
                tab.setTitleTextAttributes([NSFontAttributeName: normalTitleFont, NSForegroundColorAttributeName: normalTitleColor], for: .normal)
            }
        }
    }
    
}
