//
//  AlertsStore.swift
//  Mobile
//
//  Created by Marc Shilling on 11/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

final class AlertsStore {
    static let sharedInstance = AlertsStore()
    
    var alerts: [String: [PushNotification]] = [:]
    
    // Private init protects against another instance being accidentally instantiated
    private init() {
        if let storedAlerts = NSKeyedUnarchiver.unarchiveObject(withFile: self.filePath) as? [String: [PushNotification]] {
            self.alerts = storedAlerts
        }
    }
    
    var filePath: String {
        let manager = FileManager.default
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
        return (url!.appendingPathComponent("AlertsStore").path)
    }
    
    func savePushNotification(_ notification: PushNotification) {
        if Environment.sharedInstance.opco == .bge {
            if let array = alerts["bge"] {
                var arrayCopy = array
                arrayCopy.append(notification)
                alerts["bge"] = arrayCopy
            } else {
                let newArray = [notification]
                alerts["bge"] = newArray
            }
        } else {
            for accountNumber in notification.accountNumbers {
                if let array = alerts[accountNumber] {
                    var arrayCopy = array
                    arrayCopy.append(notification)
                    alerts[accountNumber] = arrayCopy
                } else {
                    let newArray = [notification]
                    alerts[accountNumber] = newArray
                }
            }
        }
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            NSKeyedArchiver.archiveRootObject(self.alerts, toFile: self.filePath)
        }
    }
    
    func getAlerts(forAccountNumber accountNumber: String) -> [PushNotification] {
        let accountNum = Environment.sharedInstance.opco == .bge ? "bge" : accountNumber
        guard let notificationsArray = alerts[accountNum] else { return [] }
        return notificationsArray
    }
}
