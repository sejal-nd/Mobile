//
//  PeakSavingsHistoryViewModel.swift
//  EUMobile
//
//  Created by Majumdar, Amit on 28/01/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import RxSwift

final class PeakSavingsHistoryViewModel {
    
    let disposeBag = DisposeBag()
    
    let accountDetail: AccountDetail
    
    required init(accountDetail: AccountDetail) {
        self.accountDetail = accountDetail
    }
    
    func fetchPeakEnegrySavingsHistoryData() -> Observable<SSODataResponse> {
        if let premiseNum = accountDetail.premiseNumber {
            return AccountService.rx.fetchPeakEnergySavingsHistorySSOData(accountNumber: accountDetail.accountNumber, premiseNumber: premiseNum)
        }
        return .empty()
    }
    
    func getWidgetJs(ssoData: SSODataResponse) -> String? {
        if let relayStatePESC = ssoData.relayStatePESC {
            return "var data={SAMLResponse:'\(ssoData.samlResponse)',RelayState:'\(relayStatePESC)'};var form=document.createElement('form');form.setAttribute('method','post'),form.setAttribute('action','\(ssoData.ssoPostURL)');for(var key in data){if(data.hasOwnProperty(key)){var hiddenField=document.createElement('input');hiddenField.setAttribute('type', 'hidden');hiddenField.setAttribute('name', key);hiddenField.setAttribute('value', data[key]);form.appendChild(hiddenField);}}document.body.appendChild(form);form.submit();"
        }
        return nil
    }
}
