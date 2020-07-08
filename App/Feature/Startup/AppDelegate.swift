//
//  AppDelegate.swift
//  Mobile
//
//  Created by Kenny Roethel on 2/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import Toast_Swift
import AppCenter
import AppCenterCrashes
import RxSwift
import UserNotifications
import PDTSimpleCalendar
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    #if SHOWTOUCHES
        var customWindow: GSTouchesShowingWindow?
        var window: UIWindow? {
            get {
                customWindow = customWindow ?? GSTouchesShowingWindow(frame: UIScreen.main.bounds)
                return customWindow
            }
            set { }
        }
    #else
        var window: UIWindow?
    #endif
    
    let disposeBag = DisposeBag()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        
        // TEMP
        _ = NetworkTest.shared
        //END TEMP
        
        let processInfo = ProcessInfo.processInfo
        if processInfo.arguments.contains("UITest") || processInfo.environment["XCTestConfigurationFilePath"] != nil {
            // Clear UserDefaults if Unit or UI testing -- ensures consistent fresh run
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            //Speed up animations for UI Testing
            UIApplication.shared.keyWindow?.layer.speed = 200
            UIView.setAnimationsEnabled(false)
        }
        
        // Set mock maintenance mode state based on launch argument
        if let key = processInfo.arguments.lazy.compactMap(MockDataKey.init).first,
            processInfo.arguments.contains("UITest") {
            MockAppState.current = MockAppState(maintenanceKey: key)
        }
        
        if let appInfo = Bundle.main.infoDictionary,
            let shortVersionString = appInfo["CFBundleShortVersionString"] as? String {
            UserDefaults.standard.set(shortVersionString, forKey: "version")
        }
        
        dLog("Environment " + Environment.shared.environmentName.rawValue)
        dLog("AppName" + Environment.shared.appName)
        
        if let appCenterId = Environment.shared.appCenterId {
            MSAppCenter.start(appCenterId, withServices:[MSCrashes.self])
        }
        
        setupWatchConnectivity()
        setupUserDefaults()
        setupToastStyles()
        setupAppearance()
        setupAnalytics()
        
        // Fetch Remote Config Values
        let _ = RemoteConfigUtility.shared
        //printFonts()
        
        _ = AlertsStore.shared.alerts // Triggers the loading of alerts from disk
        _ = GameTaskStore.shared.tasks // Triggers the loading of GameTasks.json into memory
        
        NotificationCenter.default.addObserver(self, selector: #selector(resetNavigationOnAuthTokenExpire), name: .didReceiveInvalidAuthToken, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resetNavigationOnFailedAccountsFetch), name: .didReceiveAccountListError, object: nil)
        
        NotificationCenter.default.rx.notification(.didMaintenanceModeTurnOn)
            .subscribe(onNext: { [weak self] notification in
                self?.showMaintenanceMode(notification.object as? MaintenanceMode)
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.addObserver(self, selector: #selector(showIOSVersionWarning), name: .shouldShowIOSVersionWarning, object: nil)
        
        // If app was cold-launched from a push notification
        if let options = launchOptions, let userInfo = options[.remoteNotification] as? [AnyHashable : Any] {
            self.application(application, didReceiveRemoteNotification: userInfo)
        } else if let shortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            handleShortcut(shortcutItem)
            return false
        }
        
        // Set "Report Outage" quick action for unauthenticated users
        if !UserDefaults.standard.bool(forKey: UserDefaultKeys.isKeepMeSignedInChecked) &&
            UserDefaults.standard.bool(forKey:  UserDefaultKeys.hasAcceptedTerms) {
            configureQuickActions(isAuthenticated: false)
        }
        
        RxNotifications.shared.configureQuickActions
            .subscribe(onNext: { [weak self] in
                self?.configureQuickActions(isAuthenticated: $0)
            })
            .disposed(by: disposeBag)
        
        return true
    }
    
    // MARK: - Push Notifications
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        dLog("*-*-*-*-* APNS Device Token: \(token)")
        
        var firstLogin = false
        if let usernamesArray = UserDefaults.standard.array(forKey: UserDefaultKeys.usernamesRegisteredForPushNotifications) as? [String],
            let loggedInUsername = UserDefaults.standard.string(forKey: UserDefaultKeys.loggedInUsername) {
            if !usernamesArray.contains(loggedInUsername) {
                firstLogin = true
            }
            
            let alertsService = ServiceFactory.createAlertsService()
            alertsService.register(token: token, firstLogin: firstLogin)
                .subscribe(onNext: {
                    dLog("*-*-*-*-* Registered token with MCS")
                    if firstLogin { // Add the username to the array
                        var newUsernamesArray = usernamesArray
                        newUsernamesArray.append(loggedInUsername)
                        UserDefaults.standard.set(newUsernamesArray, forKey: UserDefaultKeys.usernamesRegisteredForPushNotifications)
                    }
                }, onError: { err in
                    dLog("*-*-*-*-* Failed to register token with MCS with error: \(err.localizedDescription)")
                })
                .disposed(by: disposeBag)
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
        AlertsStore.shared.savePushNotification(notification)
        
        if application.applicationState == .background || application.applicationState == .inactive { // App was in background when PN tapped
            if UserDefaults.standard.bool(forKey: UserDefaultKeys.inMainApp) || StormModeStatus.shared.isOn {
                NotificationCenter.default.post(name: .didTapOnPushNotification, object: self)
            } else {
                UserDefaults.standard.set(true, forKey: UserDefaultKeys.pushNotificationReceived)
                UserDefaults.standard.set(Date.now, forKey: UserDefaultKeys.pushNotificationReceivedTimestamp)
            }
        } else {
            // App was in the foreground when notification received - do nothing
            dLog("*-*-*-*-* App was in the foreground when notification received - do nothing")
        }
    }
    
    // MARK: - Local Notifications
    
    /* Gamification reminder notifications. When tapped, store the tip ID in memory (tipIdWaitingToBeShown).
     * If app already alive in background with user logged in, resets the root view controller to Home.
     * Then (plus in all other scenarios), when GameHomeViewController loads, tipIdWaitingToBeShown != nil
     * indicates to present the tip. */
    
    var tipIdWaitingToBeShown: String? = nil
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.identifier == "game_weekly_reminder" {
            tipIdWaitingToBeShown = response.notification.request.identifier
            
            UserDefaults.standard.set(true, forKey: UserDefaultKeys.prefersGameHome) // So app launches into Game experience
            
            if UserDefaults.standard.bool(forKey: UserDefaultKeys.inMainApp) {
                guard let window = window else { return }
                if let root = window.rootViewController, let _ = root.presentedViewController {
                    root.dismiss(animated: false) { [weak window] in
                        guard let window = window else { return }
                        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        let newTabBarController = mainStoryboard.instantiateInitialViewController()
                        window.rootViewController = newTabBarController
                    }
                } else {
                    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let newTabBarController = mainStoryboard.instantiateInitialViewController()
                    window.rootViewController = newTabBarController
                }
            }
        } else {
            let userInfo = response.notification.request.content.userInfo
            guard let aps = userInfo["aps"] as? [String: Any] else { return }
            guard let alert = aps["alert"] as? [String: Any] else { return }
            
            var accountNumbers: [String]
            if let accountIds = userInfo["accountIds"] as? [String] {
                accountNumbers = accountIds
            } else if let accountId = userInfo["accountId"] as? String {
                accountNumbers = [accountId]
            } else {
                completionHandler()
                return // Did not get account number or array of account numbers
            }
            
            let notification = PushNotification(accountNumbers: accountNumbers, title: alert["title"] as? String, message: alert["body"] as? String)
            AlertsStore.shared.savePushNotification(notification)
            
            if UserDefaults.standard.bool(forKey: UserDefaultKeys.inMainApp) || StormModeStatus.shared.isOn {
                NotificationCenter.default.post(name: .didTapOnPushNotification, object: self)
            } else {
                UserDefaults.standard.set(true, forKey: UserDefaultKeys.pushNotificationReceived)
                UserDefaults.standard.set(Date.now, forKey: UserDefaultKeys.pushNotificationReceivedTimestamp)
            }
            
            completionHandler()
        }
    }
    
    // MARK: - Deep Links
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL else {
            return false
        }
        
        // For now, no deep links require being logged in. So if the user is already in the app, don't do anything special
        if UserDefaults.standard.bool(forKey: UserDefaultKeys.inMainApp) {
            return false
        }
        
        guard let window = self.window else { return false }
        guard let rootNav = window.rootViewController as? UINavigationController else { return false }
        
        if let guid = getQueryStringParameter(url: url, param: "guid") {
            UserDefaults.standard.set(guid, forKey: UserDefaultKeys.accountVerificationDeepLinkGuid)
            FirebaseUtility.logEvent(.register, parameters: [EventParameter(parameterName: .action, value: .account_verify)])
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
    
    //MARK: - Watch Helper
    private func setupWatchConnectivity() {
        // Watch Connectivity
        WatchSessionManager.shared.start()

        // Send jwt to watch if available
        guard MCSApi.shared.isAuthenticated(), let accessToken = MCSApi.shared.accessToken else { return }
        try? WatchSessionManager.shared.updateApplicationContext(applicationContext: ["authToken" : accessToken])
    }

    // MARK: - Helper
    func setupUserDefaults() {
        let userDefaults = UserDefaults.standard
        userDefaults.register(defaults: [
            UserDefaultKeys.shouldPromptToEnableBiometrics: true,
            UserDefaultKeys.paymentDetailsDictionary: [String: NSDictionary](),
            UserDefaultKeys.usernamesRegisteredForPushNotifications: [String](),
            UserDefaultKeys.gameEnergyBuddyUpdatesAlertPreference: true,
            UserDefaultKeys.gameStreakCount: 1
        ])
        
        userDefaults.set(false, forKey: UserDefaultKeys.inMainApp)
        
        if userDefaults.bool(forKey: UserDefaultKeys.hasRunBefore) == false {
            // Clear the secure enclave keychain item on first launch of the app (we found it was persisting after uninstalls)
            let biometricsService = ServiceFactory.createBiometricsService()
            biometricsService.disableBiometrics()

            MCSApi.shared.logout() // Used to be necessary with Oracle SDK - no harm leaving it here though
            
            userDefaults.set(true, forKey: UserDefaultKeys.hasRunBefore)
        }
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
        _ = gai?.tracker(withTrackingId: Environment.shared.gaTrackingId)
        
        FirebaseUtility.configure()
        
        FirebaseUtility.setUserProperty(.isScreenReaderEnabled, value: UIAccessibility.isVoiceOverRunning.description)
        FirebaseUtility.setUserProperty(.isSwitchAccessEnabled, value: UIAccessibility.isSwitchControlRunning.description)
        FirebaseUtility.setUserProperty(.fontScale, value: UIApplication.shared.preferredContentSizeCategory.rawValue)
    }
    
    @objc func resetNavigationOnAuthTokenExpire() {
        resetNavigation(sendToLogin: true)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let alertVc = UIAlertController(title: NSLocalizedString("Session Expired", comment: ""), message: NSLocalizedString("To protect the security of your account, your login has been expired. Please sign in again.", comment: ""), preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.window?.rootViewController?.present(alertVc, animated: true, completion: nil)
            
            UserDefaults.standard.set(false, forKey: UserDefaultKeys.isKeepMeSignedInChecked)
            self.configureQuickActions(isAuthenticated: false)
        }
    }
    
    @objc func resetNavigationOnFailedAccountsFetch() {
        resetNavigation(sendToLogin: true)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let alertVc = UIAlertController(title: NSLocalizedString("Unable to retrieve account", comment: ""), message: NSLocalizedString("Your account data could not be retrieved. Please sign in again.", comment: ""), preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.window?.rootViewController?.present(alertVc, animated: true, completion: nil)
            
            UserDefaults.standard.set(false, forKey: UserDefaultKeys.isKeepMeSignedInChecked)
            self.configureQuickActions(isAuthenticated: false)
        }
    }
    
    func showMaintenanceMode(_ maintenanceInfo: MaintenanceMode?) {
        DispatchQueue.main.async { [weak self] in
            LoadingView.hide()
            
            if let rootVC = self?.window?.rootViewController {
                var topmostVC = rootVC
                while let presentedVC = topmostVC.presentedViewController {
                    topmostVC = presentedVC
                }
                if topmostVC is MaintenanceModeViewController { return } // Don't present again
                
                let maintenanceStoryboard = UIStoryboard(name: "Maintenance", bundle: nil)
                let vc = maintenanceStoryboard.instantiateInitialViewController() as! MaintenanceModeViewController
                vc.maintenance = maintenanceInfo
                
                topmostVC.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    func showStormMode(){
        StormModeStatus.shared.isOn = true
        DispatchQueue.main.async { [weak self] in
            LoadingView.hide()
            
            if let rootVC = self?.window?.rootViewController {
                var topmostVC = rootVC
                while let presentedVC = topmostVC.presentedViewController {
                    topmostVC = presentedVC
                }
                
                guard let stormModeVC = UIStoryboard(name: "Storm", bundle: nil).instantiateInitialViewController(),
                    let window = self?.window else {
                    StormModeStatus.shared.isOn = false
                    return
                }

                window.rootViewController = stormModeVC
            }
        }
    }
    
    @objc func showIOSVersionWarning() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
            let versionAlert = UIAlertController(title: NSLocalizedString("Warning", comment: ""),
                                                 message: NSLocalizedString("Support for your current operating system will expire in the near future.  Please update to the latest iOS version in the Settings App.", comment: ""),
                                                 preferredStyle: .alert)
            versionAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            versionAlert.addAction(UIAlertAction(title: NSLocalizedString("Don't warn me again", comment: ""), style: .cancel, handler: { _ in
                UserDefaults.standard.set(true, forKey: UserDefaultKeys.doNotShowIOS11VersionWarningAgain)
            }))
            if let rootVC = self.window?.rootViewController {
                var topmostVC = rootVC
                while let presentedVC = topmostVC.presentedViewController {
                    topmostVC = presentedVC
                }
                topmostVC.present(versionAlert, animated: true, completion: nil)
            }
        }
    }
    
    func resetNavigation(sendToLogin: Bool = false) {
        DispatchQueue.main.async {
            LoadingView.hide() // Just in case we left one stranded
            
            let loginStoryboard = UIStoryboard(name: "Login", bundle: nil)
            let landing = loginStoryboard.instantiateViewController(withIdentifier: "landingViewController")
            let login = loginStoryboard.instantiateViewController(withIdentifier: "loginViewController")
            let vcArray = sendToLogin ? [landing, login] : [landing]
            
            self.window?.rootViewController?.dismiss(animated: false, completion: nil) // Dismiss the "Main" app (or the registration confirmation modal)
            
            if let rootNav = self.window?.rootViewController as? UINavigationController {
                rootNav.setViewControllers(vcArray, animated: false)
                rootNav.view.isUserInteractionEnabled = true // If 401 occured during Login, we need to re-enable
            } else {
                let rootNav = loginStoryboard.instantiateInitialViewController() as! UINavigationController
                rootNav.setViewControllers(vcArray, animated: false)
                self.window?.rootViewController = rootNav
            }
            
            UserDefaults.standard.set(false, forKey: UserDefaultKeys.inMainApp)
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
    
    func application(_ application: UIApplication,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handleShortcut(shortcutItem))
    }
    
    @discardableResult
    private func handleShortcut(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard let window = window else { return false }
        
        let shortcutItem = ShortcutItem(identifier: shortcutItem.type)
        
        if UserDefaults.standard.bool(forKey: UserDefaultKeys.inMainApp) {
            let storyboardName = "Main"
            if let root = window.rootViewController, let _ = root.presentedViewController {
                root.dismiss(animated: false) { [weak window] in
                    guard let window = window else { return }
                    let mainStoryboard = UIStoryboard(name: storyboardName, bundle: nil)
                    let newTabBarController = mainStoryboard.instantiateInitialViewController()
                    window.rootViewController = newTabBarController
                    NotificationCenter.default.post(name: .didTapOnShortcutItem, object: shortcutItem)
                }
            } else {
                let mainStoryboard = UIStoryboard(name: storyboardName, bundle: nil)
                let newTabBarController = mainStoryboard.instantiateInitialViewController()
                window.rootViewController = newTabBarController
                NotificationCenter.default.post(name: .didTapOnShortcutItem, object: shortcutItem)
            }
        } else if StormModeStatus.shared.isOn && shortcutItem == .alertPreferences {
            let storyboard = UIStoryboard(name: "Storm", bundle: nil)
            let navCtl = storyboard.instantiateInitialViewController() as! UINavigationController
            window.rootViewController = navCtl
            if let stormHomeVC = navCtl.viewControllers.first as? StormModeHomeViewController {
                stormHomeVC.navigateToAlertPreferences()
            }
        } else if let splashVC = (window.rootViewController as? UINavigationController)?.viewControllers.last as? SplashViewController {
            splashVC.shortcutItem = shortcutItem
        } else if shortcutItem == .reportOutage {
            let loginStoryboard = UIStoryboard(name: "Login", bundle: nil)
            let unauthenticatedStoryboard = UIStoryboard(name: "Unauthenticated", bundle: nil)
            
            let landing = loginStoryboard.instantiateViewController(withIdentifier: "landingViewController")
            let unauthenticatedUser = loginStoryboard.instantiateViewController(withIdentifier: "unauthenticatedUserViewController")
            guard let unauthenticatedOutageValidate = unauthenticatedStoryboard
                .instantiateViewController(withIdentifier: "unauthenticatedOutageValidateAccountViewController")
                as? UnauthenticatedOutageValidateAccountViewController else {
                    return false
            }
            
            let vcArray = [landing, unauthenticatedUser, unauthenticatedOutageValidate]
            
            GoogleAnalytics.log(event: .reportAnOutageUnAuthOffer)
            unauthenticatedOutageValidate.analyticsSource = AnalyticsOutageSource.report
            
            // Reset the unauthenticated nav stack
            let newNavController = loginStoryboard.instantiateInitialViewController() as! UINavigationController
            newNavController.setViewControllers(vcArray, animated: false)
            window.rootViewController?.dismiss(animated: false)
            window.rootViewController = newNavController
        } else if shortcutItem == .alertPreferences {
            let loginStoryboard = UIStoryboard(name: "Login", bundle: nil)
            let landing = loginStoryboard.instantiateViewController(withIdentifier: "landingViewController")
            let login = loginStoryboard.instantiateViewController(withIdentifier: "loginViewController")
            
            // Reset the unauthenticated nav stack
            let newNavController = loginStoryboard.instantiateInitialViewController() as! UINavigationController
            newNavController.setViewControllers([landing, login], animated: false)
            window.rootViewController?.dismiss(animated: false)
            window.rootViewController = newNavController
            
            let alert = UIAlertController(title: NSLocalizedString("You must be signed in to adjust alert preferences.", comment: ""),
                                          message: NSLocalizedString("You can turn the \"Keep me signed in\" toggle ON for your convenience.", comment: ""),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            landing.present(alert, animated: true, completion: nil)
        } else {
            return false
        }
        
        return true
    }
    
    func configureQuickActions(isAuthenticated: Bool) {
        let reportOutageIcon = UIApplicationShortcutIcon(templateImageName: "ic_quick_outage")
        let reportOutageShortcut = UIApplicationShortcutItem(type: "ReportOutage", localizedTitle: "Report Outage", localizedSubtitle: nil, icon: reportOutageIcon, userInfo: nil)
        
        guard let accounts = AccountsStore.shared.accounts else {
            if isAuthenticated {
                // Signed in, but no accounts pulled yet
                UIApplication.shared.shortcutItems = []
            } else {
                // Not signed in
                UIApplication.shared.shortcutItems = [reportOutageShortcut]
            }
            return
        }
        
        if accounts.count != 1 {
            // Multi-account user
            UIApplication.shared.shortcutItems = []
            return
        }
        
        
        if UserDefaults.standard.bool(forKey: UserDefaultKeys.isKeepMeSignedInChecked) {
            // Single account, keep me signed in
            let payBillIcon = UIApplicationShortcutIcon(templateImageName: "ic_quick_bill")
            let payBillShortcut = UIApplicationShortcutItem(type: "PayBill", localizedTitle: "Pay Bill", localizedSubtitle: nil, icon: payBillIcon, userInfo: nil)
            let usageIcon = UIApplicationShortcutIcon(templateImageName: "ic_quick_usage")
            let usageShortcut = UIApplicationShortcutItem(type: "ViewUsageOptions", localizedTitle: "View Usage", localizedSubtitle: nil, icon: usageIcon, userInfo: nil)
            UIApplication.shared.shortcutItems = [payBillShortcut, reportOutageShortcut, usageShortcut]
        } else {
            // Single account, no keep me signed in
            UIApplication.shared.shortcutItems = [reportOutageShortcut]
        }
        
    }
    
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "GameCoreDataModel")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        handleShortcut(UIApplicationShortcutItem(type: ShortcutItem.alertPreferences.rawValue, localizedTitle: ""))
    }
    
}
