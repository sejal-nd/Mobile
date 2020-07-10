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
    
    let isProd = Environment.shared.environmentName == .prod
        || Environment.shared.environmentName == .prodbeta
    
    required init(accountDetail: AccountDetail) {
        self.accountDetail = accountDetail
    }
    
    func fetchSSOData() -> Observable<SSODataResponse> {
        if let premiseNum = accountDetail.premiseNumber {
            return AccountService.rx.fetchSSOData(accountNumber: accountDetail.accountNumber, premiseNumber: premiseNum)
        }
        
        return .empty()
    }
    
    func scriptUrlForWidget(with ssoData: SSODataResponse) -> String {
        let ptrPath = "/peak-time-rebate?"
        let regex = "/[^/]*\\?"
        
        return ssoData.relayState.replacingOccurrences(of: regex, with: ptrPath, options: [.regularExpression])
    }
    
    func getWidgetJs(ssoData: SSODataResponse) -> String {
        return "var data={SAMLResponse:'\(ssoData.samlResponse)',RelayState:'\(self.scriptUrlForWidget(with: ssoData))'};var form=document.createElement('form');form.setAttribute('method','post'),form.setAttribute('action','\(ssoData.ssoPostURL)');for(var key in data){if(data.hasOwnProperty(key)){var hiddenField=document.createElement('input');hiddenField.setAttribute('type', 'hidden');hiddenField.setAttribute('name', key);hiddenField.setAttribute('value', data[key]);form.appendChild(hiddenField);}}document.body.appendChild(form);form.submit();"
    }
}
