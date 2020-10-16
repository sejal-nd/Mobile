//
//  URLSessionConfiguration.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/22/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
#if os(watchOS)
import WatchKit
#endif

extension URLSession {
    static let `default`: URLSession = {
        let configuration = URLSession.createURLSessionConfiguration()
        return URLSession(configuration: configuration)
    }()
    
    private static func createURLSessionConfiguration() -> URLSessionConfiguration {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 120.0
        sessionConfiguration.timeoutIntervalForResource = 120.0
        
        #if os(iOS)
        let systemVersion = UIDevice.current.systemVersion
        #elseif os(watchOS)
        let systemVersion = WKInterfaceDevice.current().systemVersion
        #endif
        
        // Model Identifier
        var modelIdentifier = "Unknown"
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
            modelIdentifier = "\(simulatorModelIdentifier) [Simulator]"
        }
        var sysinfo = utsname()
        uname(&sysinfo)
        modelIdentifier = String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)?.trimmingCharacters(in: .controlCharacters) ?? ""
        
        // Set User Agent Headers
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            let userAgentString = "\(Environment.shared.opco.displayString) Mobile App/\(version).\(build) (iOS \(systemVersion); Apple \(modelIdentifier))"
            sessionConfiguration.httpAdditionalHeaders = ["User-Agent": userAgentString]
        }
        
        return sessionConfiguration
    }
}
