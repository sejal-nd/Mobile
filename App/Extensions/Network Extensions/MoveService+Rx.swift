//
//  MoveService+Rx.swift
//  EUMobile
//
//  Created by Mithlesh Kumar on 01/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift
extension MoveService: ReactiveCompatible {}

extension Reactive where Base == MoveService {
    static func validateZip(code: String = "") -> Observable<ValidatedZipCodeResponse> {
        return Observable.create { observer -> Disposable in
            MoveService.validateZip(code: code) { observer.handle(result: $0) }

            return Disposables.create()
        }
    }
    static func fetchStreetAddress(address: String = "",zipcode:String = "") -> Observable<StreetAddressResponse> {
        return Observable.create { observer -> Disposable in
            MoveService.fetchStreetAddress(address: address, zipcode: zipcode){ observer.handle(result: $0) }
            return Disposables.create()
        }
    }

    static func fetchAppartment(address: String = "",zipcode:String = "") -> Observable<[AppartmentResponse]>  {
        return Observable.create { observer -> Disposable in
            MoveService.fetchAppartment(address: address, zipcode: zipcode){ observer.handle(result: $0) }
            return Disposables.create()
        }
    }

    static func lookupAddress(address: String = "",zipcode:String = "", premiseID:String = "") -> Observable<[AddressLookupResponse]> {
        return Observable.create { observer -> Disposable in
            MoveService.lookupAddress(address: address, zipcode: zipcode, premiseID: premiseID){ observer.handle(result: $0) }
            return Disposables.create()
        }
    }
}

