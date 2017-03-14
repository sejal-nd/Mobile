//
//  OutageService.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

protocol OutageService {
    
    func fetchOutageStatus(account: Account, completion: @escaping (_ result: ServiceResult<OutageStatus>) -> Swift.Void)
}
