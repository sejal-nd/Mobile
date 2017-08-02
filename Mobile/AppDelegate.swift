//
//  AppDelegate.swift
//  Mobile
//
//  Created by Kenny Roethel on 2/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import HockeySDK
import ToastSwiftFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        NSLog("Environment %@", Environment.sharedInstance.environmentName)
        NSLog("AppName %@", Environment.sharedInstance.appName)
        
        if Environment.sharedInstance.environmentName == "STAGE" {
            switch Environment.sharedInstance.opco {
                case .bge: BITHockeyManager.shared().configure(withIdentifier: "bec696e55dec44239187ffc959dec386")
                case .comEd: BITHockeyManager.shared().configure(withIdentifier: "7399eb2b4dc44f91ac86e219d947b7b5")
                case .peco: BITHockeyManager.shared().configure(withIdentifier: "51e89ca780064447b2373609c35e5b68")
            }
            BITHockeyManager.shared().crashManager.crashManagerStatus = .autoSend
            BITHockeyManager.shared().start()
            BITHockeyManager.shared().authenticator.authenticateInstallation()
        }
        
        setupUserDefaults()
        setupToastStyles()
        setupAppearance()
        setupAnalytics()
        jailbreakCheck()
        //printFonts()
        
        NotificationCenter.default.addObserver(self, selector: #selector(resetNavigationOnAuthTokenExpire), name: NSNotification.Name.DidReceiveInvalidAuthToken, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showMaintenanceMode), name: NSNotification.Name.DidMaintenanceModeTurnOn, object: nil)
        
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = userActivity.webpageURL,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                return false
        }
        
        var guid: String?
        if let queryString = components.query {
            if queryString.contains("guid=") {
                let splitArray = queryString.components(separatedBy: "=")
                guid = splitArray[1]
            }
        }
        
        // For now, no deep links require being logged in. So if the user is already in the app, don't do anything special
        if UserDefaults.standard.bool(forKey: UserDefaultKeys.InMainApp) {
            return false
        }
        
        guard let window = self.window else { return false }
        guard let rootNav = window.rootViewController as? UINavigationController else { return false }
        if let topMostVC = rootNav.viewControllers.last as? SplashViewController {
            topMostVC.restoreUserActivityState(userActivity)
        } else {
            resetNavigation(sendToLogin: true)
        }
        
        if let guid = guid {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                // Need delay here for the notification to be properly received by LoginViewController
                NotificationCenter.default.post(name: NSNotification.Name.DidTapAccountVerificationDeepLink, object: self, userInfo: ["guid": guid])
            })
        }

        return true
    }
    
    func setupUserDefaults() {
        UserDefaults.standard.register(defaults: [
            UserDefaultKeys.ShouldPromptToEnableTouchID: true,
            UserDefaultKeys.PaymentDetailsDictionary: [String: NSDictionary]()
        ])
        UserDefaults.standard.set(false, forKey: UserDefaultKeys.InMainApp)
    }
    
    func setupToastStyles() {
        var globalStyle = ToastStyle()
        globalStyle.backgroundColor = UIColor.deepGray.withAlphaComponent(0.8)
        globalStyle.cornerRadius = 17
        globalStyle.messageAlignment = .center
        ToastManager.shared.style = globalStyle
        ToastManager.shared.duration = 5.0
    }
    
    func setupAppearance() {
        PDTSimpleCalendarViewCell.appearance().textDefaultFont = SystemFont.regular.of(size: 19)
        PDTSimpleCalendarViewCell.appearance().textDefaultColor = .blackText
        PDTSimpleCalendarViewCell.appearance().textTodayColor = .blackText
        PDTSimpleCalendarViewCell.appearance().textDisabledColor = UIColor.blackText.withAlphaComponent(0.3)
        PDTSimpleCalendarViewCell.appearance().circleTodayColor = .clear
        PDTSimpleCalendarViewCell.appearance().circleSelectedColor = .actionBlue
    }
    
    func setupAnalytics() {
        //TODO - add tracking id to environment
        let gai = GAI.sharedInstance()
        _ = gai?.tracker(withTrackingId: "UA-76742208-8")
    }
    
    func resetNavigationOnAuthTokenExpire() {
        resetNavigation(sendToLogin: false)
        
        let alertVc = UIAlertController(title: NSLocalizedString("Session Expired", comment: ""), message: NSLocalizedString("Your session has expired. Please sign in again.", comment: ""), preferredStyle: .alert)
        alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
        self.window?.rootViewController?.present(alertVc, animated: true, completion: nil)
    }
    
    func showMaintenanceMode(){
        LoadingView.hide()
    
        if let rootVC = window?.rootViewController {
            var topmostVC = rootVC
            while let presentedVC = topmostVC.presentedViewController {
                topmostVC = presentedVC
            }
            
            let maintenanceStoryboard = UIStoryboard(name: "Maintenance",bundle: nil)
            let vc = maintenanceStoryboard.instantiateInitialViewController()!
            topmostVC.present(vc, animated: true, completion: nil)
        }
    }
    
    func resetNavigation(sendToLogin: Bool = false) {
        LoadingView.hide() // Just in case we left one stranded
        
        if let rootNav = window?.rootViewController as? UINavigationController {
            let loginStoryboard = UIStoryboard(name: "Login", bundle: nil)
            let landing = loginStoryboard.instantiateViewController(withIdentifier: "landingViewController")
            let login = loginStoryboard.instantiateViewController(withIdentifier: "loginViewController")
            let vcArray = sendToLogin ? [landing, login] : [landing]
            rootNav.setViewControllers(vcArray, animated: false)
        }
        
        window?.rootViewController?.dismiss(animated: false, completion: nil) // Dismiss the "Main" app (or the registration confirmation modal)
        UserDefaults.standard.set(false, forKey: UserDefaultKeys.InMainApp)
    }
    
    func jailbreakCheck() {
        let ssBroken = SSJailbreakCheck.jailbroken()
        let dtBroken = DTTJailbreakDetection.isJailbroken()
        if ssBroken != NOTJAIL || dtBroken {
            let message = String(format: NSLocalizedString("The %@ App cannot be used on jailbroken devices.", comment: ""), Environment.sharedInstance.appName)
            let alertVc = UIAlertController(title: "", message: message, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { _ in
                exit(0)
            }))
            
            let deadlineTime = DispatchTime.now() + .seconds(1)
            DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                self.window?.rootViewController?.present(alertVc, animated: true, completion: nil)
            }
        }
    }
    
    func printFonts() {
        for familyName in UIFont.familyNames {
            print("------------------------------")
            print("Font Family Name = \(familyName)")
            let names = UIFont.fontNames(forFamilyName: familyName)
            print("Font Names = \(names)")
        }
    }


}

