//
//  MockTest.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/18/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

class URLProtocolMock: URLProtocol {
    // this dictionary maps URLs to test data
    static var testURLs = [URL?: Data]()
    
    // say we want to handle all types of request
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    // ignore this method; just send back what we were given
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        // if we have a valid URL…
        if let url = request.url {
            // …and if we have test data for that URL…
            if let data = URLProtocolMock.testURLs[url] {
                // …load it immediately.
                self.client?.urlProtocol(self, didLoad: data)
            }
        }
        
        // mark that we've finished
        self.client?.urlProtocolDidFinishLoading(self)
    }
    
    // this method is required but doesn't need to do anything
    override func stopLoading() { }
}

extension URLProtocolMock {
    static func createMockURLConfiguration(path: String,
                                           mockDataFileName: String,
                                           mockUser: MockDataKey) -> URLSessionConfiguration {
        // this is the URL we expect to call
        let url = URL(string: path)
        
        guard let path = Bundle.main.path(forResource: mockDataFileName, ofType: "json") else {
            fatalError("Mock data not found for file named: \(mockDataFileName)")
        }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
            
            // make sure this JSON is in the format we expect
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                fatalError("JSON format is incorrect for \(mockDataFileName)")
            }
            guard let nestedJSON = json[mockUser.rawValue] ?? json[MockDataKey.default.rawValue] else {
                fatalError("Mock user key \(mockUser.rawValue) not found in nested json for: \(mockDataFileName)")
            }
            let nestedJsonData = try JSONSerialization.data(withJSONObject: nestedJSON, options: .prettyPrinted)
            
            URLProtocolMock.testURLs = [url: nestedJsonData]
        } catch let error {
            fatalError("Failed to parse mock json file into data: \(error)")
        }
        
        // now set up a configuration to use our mock
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        
        return config
    }
}
