//
//  AddressSearchModel.swift
//  EUMobile
//
//  Created by Mithlesh Kumar on 24/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
import Foundation
import RxSwift
import RxCocoa

enum SearchType{
    case street
    case appartment
}
class AddressSearchModel {

    var listStreetAddress:[String?] = []

    var disposeBag = DisposeBag()
    var zipcode = ""
    var address = ""


    //MARK: Internal Methods
    func searchAaddress() -> Observable<StreetAddressResponse> {
        return   MoveService.rx.fetchStreetAddress(address: address, zipcode: zipcode)
    }

    func findStreetAddress(at index: Int) -> String{
        return listStreetAddress[index]!
    }

}


