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
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let processInfo = ProcessInfo.processInfo
        if processInfo.arguments.contains("UITest") || processInfo.environment["XCTestConfigurationFilePath"] != nil {
            // Clear UserDefaults if Unit or UI testing -- ensures consistent fresh run
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            UserDefaults.standard.synchronize()
        }
        
        if let appInfo = Bundle.main.infoDictionary,
            let shortVersionString = appInfo["CFBundleShortVersionString"] as? String {
            UserDefaults.standard.set(shortVersionString, forKey: "version")
        }
        
        NSLog("Environment %@", Environment.sharedInstance.environmentName)
        NSLog("AppName %@", Environment.sharedInstance.appName)
        
        if Environment.sharedInstance.environmentName == "STAGE" || Environment.sharedInstance.environmentName == "PROD" {
            switch Environment.sharedInstance.opco {
            case .bge: BITHockeyManager.shared().configure(withIdentifier: "bec696e55dec44239187ffc959dec386")
            case .comEd: BITHockeyManager.shared().configure(withIdentifier: "7399eb2b4dc44f91ac86e219d947b7b5")
            case .peco: BITHockeyManager.shared().configure(withIdentifier: "51e89ca780064447b2373609c35e5b68")
            }
            BITHockeyManager.shared().isUpdateManagerDisabled = true
            BITHockeyManager.shared().crashManager.crashManagerStatus = .autoSend
            BITHockeyManager.shared().isFeedbackManagerDisabled = true
            BITHockeyManager.shared().start()
            BITHockeyManager.shared().authenticator.authenticateInstallation()
        }
        
        if Environment.sharedInstance.environmentName == "PROD" {
            OMCMobileBackendManager.shared().logLevel = "none"
        }
        
        setupUserDefaults()
        setupToastStyles()
        setupAppearance()
        setupAnalytics()
        //printFonts()
        
        _ = AlertsStore.sharedInstance.alerts // Triggers the loading of alerts from disk
        
        NotificationCenter.default.addObserver(self, selector: #selector(resetNavigationOnAuthTokenExpire), name: NSNotification.Name.DidReceiveInvalidAuthToken, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showMaintenanceMode), name: NSNotification.Name.DidMaintenanceModeTurnOn, object: nil)
        
        // If app was cold-launched from a push notification
        if let options = launchOptions, let userInfo = options[UIApplicationLaunchOptionsKey.remoteNotification] as? [AnyHashable : Any] {
            self.application(application, didReceiveRemoteNotification: userInfo)
        } else if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            handleShortcut(shortcutItem)
            return false
        }
        
        // Set "Report Outage" quick action for unauthenticated users
        if !UserDefaults.standard.bool(forKey: UserDefaultKeys.IsKeepMeSignedInChecked) &&
            UserDefaults.standard.bool(forKey:  UserDefaultKeys.HasAcceptedTerms) {
            configureQuickActions(isAuthenticated: false)
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        dLog("*-*-*-*-* APNS Device Token: \(token)")
        
        var firstLogin = false
        if let usernamesArray = UserDefaults.standard.array(forKey: UserDefaultKeys.UsernamesRegisteredForPushNotifications) as? [String],
            let loggedInUsername = UserDefaults.standard.string(forKey: UserDefaultKeys.LoggedInUsername) {
            if !usernamesArray.contains(loggedInUsername) {
                firstLogin = true
            }
            
            let alertsService = ServiceFactory.createAlertsService()
            alertsService.register(token: token, firstLogin: firstLogin) { (result: ServiceResult<Void>) in
                switch result {
                case .Success:
                    dLog("*-*-*-*-* Registered token with MCS")
                    if firstLogin { // Add the username to the array
                        var newUsernamesArray = usernamesArray
                        newUsernamesArray.append(loggedInUsername)
                        UserDefaults.standard.set(newUsernamesArray, forKey: UserDefaultKeys.UsernamesRegisteredForPushNotifications)
                    }
                case .Failure(let err):
                    dLog("*-*-*-*-* Failed to register token with MCS with error: \(err.localizedDescription)")
                }
            }
        }
    }
    
    // Only used on iOS 9 and below -- iOS 10+ uses the new UNUserNotificationCenter and handles the analytics in
    // the callback in HomeViewController
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        if UserDefaults.standard.bool(forKey: UserDefaultKeys.InitialPushNotificationPermissionsWorkflowCompleted) == false {
            UserDefaults.standard.set(true, forKey: UserDefaultKeys.InitialPushNotificationPermissionsWorkflowCompleted)
            if notificationSettings.types.isEmpty {
                Analytics().logScreenView(AnalyticsPageView.AlertsiOSPushDontAllowInitial.rawValue)
            } else {
                Analytics().logScreenView(AnalyticsPageView.AlertsiOSPushOKInitial.rawValue)
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        dLog("*-*-*-*-* \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        dLog("*-*-*-*-* \(userInfo)")
        
        guard let aps = userInfo["aps"] as? [String: Any] else { return }
        guard let alert = aps["alert"] as? [String: Any] else { return }
        
        var accountNumbers: [String]
        if let accountIds = userInfo["accountIds"] as? [String] {
            accountNumbers = accountIds
        } else if let accountId = userInfo["accountId"] as? String {
            accountNumbers = [accountId]
        } else {
            return // Did not get account number or array of account numbers
        }
        
        let notification = PushNotification(accountNumbers: accountNumbers, title: alert["title"] as? String, message: alert["body"] as? String)
        AlertsStore.sharedInstance.savePushNotification(notification)
        
        if application.applicationState == .background || application.applicationState == .inactive { // App was in background when PN tapped
            if UserDefaults.standard.bool(forKey: UserDefaultKeys.InMainApp) {
                NotificationCenter.default.post(name: .DidTapOnPushNotification, object: self)
            } else {
                UserDefaults.standard.set(true, forKey: UserDefaultKeys.PushNotificationReceived)
                UserDefaults.standard.set(Date(), forKey: UserDefaultKeys.PushNotificationReceivedTimestamp)
            }
        } else {
            // App was in the foreground when notification received - do nothing
        }
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL else {
            return false
        }
        
        // For now, no deep links require being logged in. So if the user is already in the app, don't do anything special
        if UserDefaults.standard.bool(forKey: UserDefaultKeys.InMainApp) {
            return false
        }
        
        guard let window = self.window else { return false }
        guard let rootNav = window.rootViewController as? UINavigationController else { return false }
        
        if let guid = getQueryStringParameter(url: url, param: "guid") {
            UserDefaults.standard.set(guid, forKey: UserDefaultKeys.AccountVerificationDeepLinkGuid)
        }
        
        if let topMostVC = rootNav.viewControllers.last as? SplashViewController {
            topMostVC.restoreUserActivityState(userActivity)
        } else {
            resetNavigation(sendToLogin: true)
        }
        
        return true
    }
    
    private func getQueryStringParameter(url: URL, param: String) -> String? {
        if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true), let queryItems = urlComponents.queryItems {
            return queryItems.filter({ item in
                item.name == param
            }).first?.value!
        }
        return nil
    }
    
    func setupUserDefaults() {
        let userDefaults = UserDefaults.standard
        userDefaults.register(defaults: [
            UserDefaultKeys.ShouldPromptToEnableBiometrics: true,
            UserDefaultKeys.PaymentDetailsDictionary: [String: NSDictionary](),
            UserDefaultKeys.UsernamesRegisteredForPushNotifications: [String]()
            ])
        
        userDefaults.set(false, forKey: UserDefaultKeys.InMainApp)
        
        if userDefaults.bool(forKey: UserDefaultKeys.HasRunBefore) == false {
            // Clear the secure enclave keychain item on first launch of the app (we found it was persisting after uninstalls)
            let biometricsService = ServiceFactory.createBiometricsService()
            biometricsService.disableBiometrics()
            
            // Log the user out (Oracle SDK appears to be persisting the auth token through uninstalls)
            let auth = OMCApi.sharedInstance.getBackend().authorization
            auth.logoutClearCredentials(true, completionBlock: nil)
            
            userDefaults.set(true, forKey: UserDefaultKeys.HasRunBefore)
        }
        
        userDefaults.synchronize()
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
        let gai = GAI.sharedInstance()
        _ = gai?.tracker(withTrackingId: Environment.sharedInstance.gaTrackingId)
        
        let filePath = Bundle.main.path(forResource: Environment.sharedInstance.firebaseConfigFile, ofType: "plist")
        if let fileopts = FirebaseOptions.init(contentsOfFile: filePath!) {
            FirebaseApp.configure(options: fileopts)
        } else {
            dLog("Failed to load Firebase Analytics")
        }
        
    }
    
    @objc func resetNavigationOnAuthTokenExpire() {
        resetNavigation(sendToLogin: false)
        
        let alertVc = UIAlertController(title: NSLocalizedString("Session Expired", comment: ""), message: NSLocalizedString("To protect the security of your account, your login has been expired. Please sign in again.", comment: ""), preferredStyle: .alert)
        alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
        self.window?.rootViewController?.present(alertVc, animated: true, completion: nil)
        
        UserDefaults.standard.set(false, forKey: UserDefaultKeys.IsKeepMeSignedInChecked)
        configureQuickActions(isAuthenticated: false)
    }
    
    @objc func showMaintenanceMode(){
        DispatchQueue.main.async { [weak self] in
            LoadingView.hide()
            
            if let rootVC = self?.window?.rootViewController {
                var topmostVC = rootVC
                while let presentedVC = topmostVC.presentedViewController {
                    topmostVC = presentedVC
                }
                
                let maintenanceStoryboard = UIStoryboard(name: "Maintenance", bundle: nil)
                let vc = maintenanceStoryboard.instantiateInitialViewController()!
                topmostVC.present(vc, animated: true, completion: nil)
            }
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
            rootNav.view.isUserInteractionEnabled = true // If 401 occured during Login, we need to re-enable
        }
        
        window?.rootViewController?.dismiss(animated: false, completion: nil) // Dismiss the "Main" app (or the registration confirmation modal)
        UserDefaults.standard.set(false, forKey: UserDefaultKeys.InMainApp)
    }
    
    func printFonts() {
        for familyName in UIFont.familyNames {
            print("------------------------------")
            print("Font Family Name = \(familyName)")
            let names = UIFont.fontNames(forFamilyName: familyName)
            print("Font Names = \(names)")
        }
    }
    
    func application(_ application: UIApplication,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handleShortcut(shortcutItem))
    }
    
    @discardableResult
    private func handleShortcut(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard let window = window else { return false }
        
        let shortcutItem = ShortcutItem(identifier: shortcutItem.type)
        
        if UserDefaults.standard.bool(forKey: UserDefaultKeys.InMainApp) {
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let newTabBarController = mainStoryboard.instantiateInitialViewController()
            window.rootViewController = newTabBarController
            NotificationCenter.default.post(name: .DidTapOnShortcutItem, object: shortcutItem)
        } else if let splashVC = (window.rootViewController as? UINavigationController)?.viewControllers.last as? SplashViewController {
            splashVC.shortcutItem = shortcutItem
        } else if shortcutItem == .reportOutage {
            let loginStoryboard = UIStoryboard(name: "Login", bundle: nil)
            let landing = loginStoryboard.instantiateViewController(withIdentifier: "landingViewController")
            let unauthenticatedUser = loginStoryboard.instantiateViewController(withIdentifier: "unauthenticatedUserViewController")
            guard let unauthenticatedOutageValidate = loginStoryboard
                .instantiateViewController(withIdentifier: "unauthenticatedOutageValidateAccountViewController")
                as? UnauthenticatedOutageValidateAccountViewController else {
                return false
            }
            
            let vcArray = [landing, unauthenticatedUser, unauthenticatedOutageValidate]
            
            Analytics().logScreenView(AnalyticsPageView.ReportAnOutageUnAuthOffer.rawValue)
            unauthenticatedOutageValidate.analyticsSource = AnalyticsOutageSource.Report
            
            // Reset the unauthenticated nav stack
            let newNavController = loginStoryboard.instantiateInitialViewController() as! UINavigationController
            newNavController.setViewControllers(vcArray, animated: false)
            window.rootViewController = newNavController
        } else {
            return false
        }
        
        return true
    }
    
    func configureQuickActions(isAuthenticated: Bool, showViewUsageOptions: Bool = false) {
        let reportOutageIcon = UIApplicationShortcutIcon(templateImageName: "ic_quick_outage")
        let reportOutageShortcut = UIApplicationShortcutItem(type: "ReportOutage", localizedTitle: "Report Outage", localizedSubtitle: nil, icon: reportOutageIcon, userInfo: nil)
        
        guard let accounts = AccountsStore.sharedInstance.accounts else {
            // Signed in, but no accounts pulled yet
            if isAuthenticated {
                UIApplication.shared.shortcutItems = []
            }
            
            // Not signed in
            else {
                UIApplication.shared.shortcutItems = [reportOutageShortcut]
            }
            return
        }
        
        let payBillIcon = UIApplicationShortcutIcon(templateImageName: "ic_quick_bill")
        let payBillShortcut = UIApplicationShortcutItem(type: "PayBill", localizedTitle: "Pay Bill", localizedSubtitle: nil, icon: payBillIcon, userInfo: nil)
        
        switch (accounts.count == 1, UserDefaults.standard.bool(forKey: UserDefaultKeys.IsKeepMeSignedInChecked), showViewUsageOptions) {
        case (true, false, _):
            // Single account, no keep me signed in
            UIApplication.shared.shortcutItems = [reportOutageShortcut]
        case (true, true, true):
            // Single account, keep me signed in, show usage
            let usageIcon = UIApplicationShortcutIcon(templateImageName: "ic_quick_usage")
            let usageShortcut = UIApplicationShortcutItem(type: "ViewUsageOptions", localizedTitle: "View Usage", localizedSubtitle: nil, icon: usageIcon, userInfo: nil)
            UIApplication.shared.shortcutItems = [payBillShortcut, reportOutageShortcut, usageShortcut]
        case (true, true, false):
            // Single account, keep me signed in, don't show usage
            UIApplication.shared.shortcutItems = [payBillShortcut, reportOutageShortcut]
        case (false, _, _):
            // Multi-account user
            UIApplication.shared.shortcutItems = []
        }
        
    }
    
}

