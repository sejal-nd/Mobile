//
//  FiservErrorMapper.swift
//  Mobile
//
//  Created by James Landrum on 7/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

class FiservErrorMapper : NSObject, XMLParserDelegate {
    let sharedInstance = FiservErrorMapper()
    var items = [FiservError]()
    
    private override init() {
        var parser: XMLParser?
        let path = Bundle.main.path(forResource: "fiserv_errors", ofType: "xml")
        
        if (path != nil) {
            parser = XMLParser(contentsOf: URL(fileURLWithPath: path!))
        }
        
        parser?.delegate = sharedInstance
        parser?.parse()
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if (elementName as String == "item") {
            let fiservError = FiservError()
            
            fiservError.context = attributeDict["context"]!
            fiservError.id = attributeDict["id"]!
            fiservError.name = attributeDict["name"]!
            
            items.append(fiservError)
        }
    }
    
    func getError(message : String, context : String?) -> FiservError? {
        return items.filter({message.uppercased().contains($0.name)}).first
    }
}

class FiservError : NSObject {
    var id: String = ""
    var context: String = ""
    var name: String = ""
}
