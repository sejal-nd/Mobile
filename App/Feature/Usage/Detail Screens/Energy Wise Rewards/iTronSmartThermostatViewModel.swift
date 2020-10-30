//
//  iTronSmartThermostatViewModel.swift
//  EUMobile
//
//  Created by Majumdar, Amit on 28/10/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class iTronSmartThermostatViewModel {
    let disposeBag = DisposeBag()
    
    let accountDetail: AccountDetail
        
    required init(accountDetail: AccountDetail) {
        self.accountDetail = accountDetail
    }
    
    func fetchiTronSSOData() -> Observable<SSODataResponse> {
        if let premiseNum = accountDetail.premiseNumber {
            return AccountService.rx.fetchiTronSSOData(accountNumber: accountDetail.accountNumber, premiseNumber: premiseNum)
        }
        return .empty()
    }
    
    func getWidgetJs(ssoData: SSODataResponse) -> String {
        return "var data={SAMLResponse:'\(ssoData.samlResponse)',RelayState:'\(ssoData.relayState)'};var form=document.createElement('form');form.setAttribute('method','post'),form.setAttribute('action','\(ssoData.ssoPostURL)');for(var key in data){if(data.hasOwnProperty(key)){var hiddenField=document.createElement('input');hiddenField.setAttribute('type', 'hidden');hiddenField.setAttribute('name', key);hiddenField.setAttribute('value', data[key]);form.appendChild(hiddenField);}}document.body.appendChild(form);form.submit();"
    }
}

