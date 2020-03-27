//
//  SERWebViewModel.swift
//  BGE
//
//  Created by Cody Dillon on 3/16/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class SERWebViewModel {
    let disposeBag = DisposeBag()
    
    let accountDetail: AccountDetail
    let accountService: AccountService
    
    let isProd = Environment.shared.environmentName == .prod
        || Environment.shared.environmentName == .prodbeta
    
    required init(accountService: AccountService, accountDetail: AccountDetail) {
        self.accountDetail = accountDetail
        self.accountService = accountService
    }
    
    func fetchSSOData() -> Observable<SSOData> {
        if let premiseNum = accountDetail.premiseNumber {
            return accountService.fetchSSOData(accountNumber: accountDetail.accountNumber, premiseNumber: premiseNum)
        }
        
        return .empty()
    }
    
    func scriptUrlForWidget(with ssoData: SSOData) -> String {
        let ptrPath = "/peak-time-rebate?"
        let pattern = "\\/[^\\/]*\\?"
        let ptrUrl = ssoData.relayState.absoluteString.replacingOccurrences(of: pattern, with: ptrPath, options: [.regularExpression])
        
        return ptrUrl
    }
    
    func getWidgetJs(ssoData: SSOData) -> String {
        return "var data={SAMLResponse:'\(ssoData.samlResponse)',RelayState:'\(self.scriptUrlForWidget(with: ssoData))'};var form=document.createElement('form');form.setAttribute('method','post'),form.setAttribute('action','\(ssoData.ssoPostURL.absoluteString)');for(var key in data){if(data.hasOwnProperty(key)){var hiddenField=document.createElement('input');hiddenField.setAttribute('type', 'hidden');hiddenField.setAttribute('name', key);hiddenField.setAttribute('value', data[key]);form.appendChild(hiddenField);}}document.body.appendChild(form);form.submit();"
    }
}
