//
//  Date+Parser.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/11/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

extension String {
    func extractDate() -> Date? {
        if let date = DateFormatter.yyyyMMddTHHmmssZFormatter.date(from: self) {
            return date
        }
        
        if let date = DateFormatter.yyyyMMddTHHmmssZZZZZFormatter.date(from: self) {
            return date
        }
        
        if let date = DateFormatter.yyyyMMddTHHmmssSSSZZZZZFormatter.date(from: self) {
            return date
        }
        
        if let date = self.apiFormatDate {
            return date
        }
        
        if let date = DateFormatter.yyyyMMddFormatter.date(from: self) {
            return date
        }
        
        if let date = DateFormatter.yyyyMMddTHHmmssSSSFormatter.date(from: self) {
            return date
        }
        
        if let date = DateFormatter.HHmmFormatter.date(from: self) {
            return date
        }
        
        if let date = DateFormatter.MMSlashyyyyFormatter.date(from: self) {
            return date
        }
        return nil
    }
}
