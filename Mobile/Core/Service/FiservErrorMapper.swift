//
//  FiservErrorMapper.swift
//  Mobile
//
//  Created by James Landrum on 7/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

class FiservErrorMapper : NSObject, XMLParserDelegate {
    static let sharedInstance = FiservErrorMapper()
    
    var items = [FiservError]()
    
    static private var fiservError : FiservError?
    
    private override init() {  }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if (elementName as String == "item") {
            FiservErrorMapper.fiservError = FiservError()
            
            FiservErrorMapper.fiservError?.context = attributeDict["context"]!
            FiservErrorMapper.fiservError?.id = attributeDict["id"]!
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if (elementName as String == "item") {
            FiservErrorMapper.fiservError!.text = FiservErrorMapper.fiservError!.text
            items.append(FiservErrorMapper.fiservError!)
            FiservErrorMapper.fiservError = nil
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        FiservErrorMapper.fiservError?.text += string
    }
    
    public func getError(message : String, context : String?) -> FiservError? {
        if self.items.count == 0 {
            var parser: XMLParser?
            let path = Bundle.main.path(forResource: "fiserv_errors", ofType: "xml")
            
            if path != nil {
                parser = XMLParser(contentsOf: URL(fileURLWithPath: path!))
            }
            
            parser?.delegate = FiservErrorMapper.sharedInstance
            parser?.parse()
        }

        let error = items.filter(
                {
                    message.uppercased().contains($0.id) && (context == nil || $0.context == context)
                }
        ).first;

        if error == nil && context != nil { return getError(message: message, context: nil) }
        else { return error }
    }
}

class FiservError : NSObject {
    var id: String = ""
    var context: String = ""
    var text: String = ""
}
