//
//  DateParser.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/30/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Mapper

struct DateParser {
    
    public func extractDate(object: Any?) throws -> Date {
        guard let dateString = object as? String else {
            throw MapperError.convertibleError(value: object, type: Date.self)
        }
        
        if let date = DateFormatter.yyyMMddTHHmmssFormatter.date(from: dateString) {
            return date
        }
        
        if let date = DateFormatter.yyyMMddTHHmmssZZZZZFormatter.date(from: dateString) {
            return date
        }
        
        if let date = dateString.apiFormatDate {
            return date
        }
        
        if let date = DateFormatter.yyyMMddFormatter.date(from: dateString) {
            return date
        }

        throw MapperError.convertibleError(value: object, type: Date.self)
    }
    
}
