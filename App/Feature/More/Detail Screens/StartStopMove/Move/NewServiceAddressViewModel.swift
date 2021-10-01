//
//  NewServiceAddressViewModel.swift
//  EUMobile
//
//  Created by Mithlesh Kumar on 30/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class NewServiceAddressViewModel{
    var zipCode: String?
    var streetAddress: String?
    var disposeBag = DisposeBag()
    private let isLoading = BehaviorRelay(value: false)
    private (set) lazy var showLoadingState: Observable<Bool> = isLoading.asObservable()
    
    private var validateZipCode = PublishSubject<Void>()
    var validatedZipCodeResponse = BehaviorRelay<ValidatedZipCodeResponse?>(value: nil)
    
    
    var isZipValid: Bool {
        guard let zip = zipCode, !zip.isEmpty, zip.count == 5 else { return false}
        return true
    }
    var isZipValidated: Bool {
        guard let zip_data = validatedZipCodeResponse.value?.data else { return false}
        return zip_data.value
    }
    var isStreetAddressValid: Bool {
        guard let address = streetAddress, !address.isEmpty else { return false}
        return true
    }
    var canEnableContinue: Bool {
        return isStreetAddressValid && isZipValid
    }
    init() {
        validateZipCode.toAsyncRequest { [weak self] _ -> Observable<ValidatedZipCodeResponse> in
            
            guard let `self` = self else { return Observable.empty() }
            if !self.isLoading.value {
                self.isLoading.accept(true)
            }
            return MoveService.rx.validateZip(code: self.zipCode!)
        }.subscribe(onNext: { [weak self] result in
            guard let `self` = self else {return }
            if result.error != nil {
                if self.isLoading.value {
                    self.isLoading.accept(false)
               }
            }
            if let validatedZipCodeResponse = result.element {
                self.validatedZipCodeResponse.accept(validatedZipCodeResponse)
                if self.isLoading.value {
                    self.isLoading.accept(false)
               }
            }

        }).disposed(by: disposeBag)
    }
    func validateZip(){
        validateZipCode.onNext(())
    }
}
