//
//  SpeedpayErrorMapper.swift
//  Mobile
//
//  Created by Marc Shilling on 8/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

class SpeedpayErrorMapper : NSObject, XMLParserDelegate {
    static let shared = SpeedpayErrorMapper()
    
    var items = [SpeedpayError]()
    
    static private var speedpayError : SpeedpayError?
    
    private override init() {  }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if (elementName as String == "item") {
            SpeedpayErrorMapper.speedpayError = SpeedpayError(id: attributeDict["id"]!, context: attributeDict["context"]!)
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if (elementName as String == "item") {
            items.append(SpeedpayErrorMapper.speedpayError!)
            SpeedpayErrorMapper.speedpayError = nil
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        SpeedpayErrorMapper.speedpayError?.text += string
    }
    
    public func getError(message : String, context : String?) -> SpeedpayError? {
        if self.items.count == 0 {
            var parser: XMLParser?
            let path = Bundle.main.path(forResource: "speedpay_errors", ofType: "xml")
            
            if path != nil {
                parser = XMLParser(contentsOf: URL(fileURLWithPath: path!))
            }
            
            parser?.delegate = SpeedpayErrorMapper.shared
            parser?.parse()
        }
        
        let error = items.filter {
            message.uppercased().contains($0.id) && (context == nil || $0.context == context)
        }.first
        
        guard let err = error else {
            if context != nil {
                return getError(message: message, context: context)
            }
            return nil
        }
        
        if !err.text.isEmpty {
            return err
        }
        
        return nil
    }
}

class SpeedpayError : NSObject {
    let id: String
    let context: String
    var text: String
    
    init(id: String, context: String = "", text: String = "") {
        self.id = id
        self.context = context
        self.text = text
    }
}
