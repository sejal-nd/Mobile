//
//  GAUtility.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 10/1/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

class GATracker {
    private var propertyId = Environment.shared.watchGaTrackingId
    private var clientId: String
    private var appName: String
    private var appVersion: String
    private var measurementProtocolVersion = "1"
    private var userAgent = "Mozilla/5.0 (Apple TV; CPU iPhone OS 9_0 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Mobile/13T534YI"
    private var userLanguage: String
    
    static let shared = GATracker()

    /*
     Initialize Tracker with Property Id
     Set up all attributes
     */
    private init() {
        dLog("NOTICE: Google Analytics Tracker Initialized.")

        if let infoDictionary = Bundle.main.infoDictionary, let name = infoDictionary["CFBundleName"] as? String {
            appName = name
        } else {
            appName = "--"
        }
        
        if let infoDictionary = Bundle.main.infoDictionary, let version = infoDictionary["CFBundleShortVersionString"] as? String {
            appVersion = version
        } else {
            appVersion = "0.0"
        }

        let defaults = UserDefaults.standard
        if let id = defaults.string(forKey: "cid") {
            clientId = id
        } else {
            clientId = UUID().uuidString
            defaults.set(clientId, forKey: "cid")
        }
        
        userLanguage = NSLocale.preferredLanguages.first ?? "(not set)"
    }
    
    /*
     Generic hit sender to Measurement Protocol
     Consists out of hit type and a dictionary of other parameters
     */
    func send(type: String, params: Dictionary<String, String>) {
        let endpoint = "https://www.google-analytics.com/collect?"
        var parameters = "v=" + measurementProtocolVersion + "&an=" + appName + "&tid=" + propertyId + "&av=" + appVersion + "&cid=" + clientId + "&t=" + type + "&ua=" + userAgent + "&ul=" + userLanguage
        
        for (key, value) in params {
            parameters += "&" + key + "=" + value
        }
        
        // Encoding all the parameters
        if let paramEndcode = parameters.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
            let urlString = endpoint + paramEndcode
            
            guard let url = URL(string: urlString) else { return }
            
//            dLog("Sending: \(urlString)")

            let task = URLSession.shared.dataTask(with: url) { (data, response, error) -> Void in
                if let error = error {
                    dLog("Error: \(error.localizedDescription)")
                } else if let httpReponse = response as? HTTPURLResponse {
                    let statusCode = httpReponse.statusCode
                    
                    dLog("Status Code: \(statusCode)")
                } else {
                    dLog("Unhandled error in GATracker Send request.")
                }
            }
            task.resume()
        }
    }
    
    /*
     A screenview hit, use screenname
     */
    func screenView(screenName: String, customParameters: Dictionary<String, String>?) {
        var params = ["cd" : "WatchApp_\(screenName)"]
        if (customParameters != nil) {
            for (key, value) in customParameters! {
                params.updateValue(value, forKey: key)
            }
        }
        send(type: "screenview", params: params)
    }
    
    /*
     An event hit with category, action, label
     */
    func event(category: String, action: String, label: String?, customParameters: Dictionary<String, String>?) {

        
        //event parameters category, action and label
        var params = ["ec" : category, "ea" : action, "el" : label ?? ""]
        if (customParameters != nil) {
            for (key, value) in customParameters! {
                params.updateValue(value, forKey: key)
            }
        }
        send(type: "event", params: params)
    }
    
    /*
     An exception hit with exception description (exd) and "fatality"  (Crashed or not) (exf)
     */
    func exception(description: String, isFatal: Bool, customParameters: Dictionary<String, String>?) {
        var fatal = "0"
        if isFatal{
            fatal = "1"
        }
        
        var params = ["exd": description, "exf": fatal]
        if (customParameters != nil) {
            for (key, value) in customParameters! {
                params.updateValue(value, forKey: key)
            }
        }
        send(type: "exception", params: params)
    }
}
