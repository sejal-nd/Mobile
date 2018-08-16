//
//  FiservErrorMapper.swift
//  Mobile
//
//  Created by James Landrum on 7/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

class FiservErrorMapper : NSObject, XMLParserDelegate {
    static let shared = FiservErrorMapper()
    
    var items = [FiservError]()
    
    static private var fiservError : FiservError?
    
    private override init() {  }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if (elementName as String == "item") {
            FiservErrorMapper.fiservError = FiservError(id: attributeDict["id"]!, context: attributeDict["context"]!)
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if (elementName as String == "item") {
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
            
            parser?.delegate = FiservErrorMapper.shared
            parser?.parse()
        }

        let error = items.filter {
            message.uppercased().contains($0.id) && (context == nil || $0.context == context)
        }.first;
        
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

class FiservError : NSObject {
    let id: String
    let context: String
    var text: String

    init(id: String, context: String = "", text: String = "") {
        self.id = id
        self.context = context
        self.text = text
    }
}
