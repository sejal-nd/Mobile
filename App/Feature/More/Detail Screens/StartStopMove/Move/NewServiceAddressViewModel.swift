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
    var premiseID: String?

    var disposeBag = DisposeBag()
    private let isLoading = BehaviorRelay(value: false)
    private (set) lazy var showLoadingState: Observable<Bool> = isLoading.asObservable()
    
    private var validateZipCode = PublishSubject<Void>()
    var validatedZipCodeResponse = BehaviorRelay<ValidatedZipCodeResponse?>(value: nil)
    var validateZipResponseEvent: Observable<ValidatedZipCodeResponse?> { return validatedZipCodeResponse.asObservable() }

    private var fetchAppartment = PublishSubject<Void>()
    var appartmentResponse = BehaviorRelay<[AppartmentResponse]?>(value: [])
    var appartmentResponseEvent: Observable<[AppartmentResponse]?> { return appartmentResponse.asObservable() }
    var addressLookUpResponseEvent: Observable<[AddressLookupResponse]?> { return addressLookupResponse.asObservable() }

    private var getAddressLookup = PublishSubject<Void>()
    var addressLookupResponse = BehaviorRelay<[AddressLookupResponse]?>(value: nil)


    var isZipValid: Bool {
        guard let zip = zipCode, !zip.isEmpty, zip.count == 5 else { return false}
        return true
    }
    var isZipValidated: Bool {
        if let zip_data = validatedZipCodeResponse.value, let isValidZipCode = zip_data.isValidZipCode {
            return isValidZipCode
        }
        return false
    }
    var isStreetAddressValid: Bool {
        guard let address = streetAddress, !address.isEmpty else { return false}
        return true
    }
    var isValidPremiseID: Bool {
        guard let _premiseID = premiseID, !_premiseID.isEmpty else { return false}
        return true
    }
    var canEnableContinue: Bool {
        return isStreetAddressValid && isZipValid && isZipValidated && isValidPremiseID
    }
    
    var moveServiceFlowData: MoveServiceFlowData
    
    init(moveServiceFlowData: MoveServiceFlowData) {
        
        self.moveServiceFlowData = moveServiceFlowData
        
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


        fetchAppartment.toAsyncRequest { [weak self] _ -> Observable<[AppartmentResponse]> in
            guard let `self` = self else { return Observable.empty() }
            return MoveService.rx.fetchAppartment(address: self.streetAddress!, zipcode: self.zipCode!)
        }.subscribe(onNext: { [weak self] result in
            guard let `self` = self else {return }
            if let appartmentResp = result.element {
                self.appartmentResponse.accept(appartmentResp)
            }
        }).disposed(by: disposeBag)

        getAddressLookup.toAsyncRequest { [weak self] _ -> Observable<[AddressLookupResponse]> in
            guard let `self` = self else { return Observable.empty() }
            return MoveService.rx.lookupAddress(address: self.streetAddress!, zipcode: self.zipCode!, premiseID:self.premiseID!)
        }.subscribe(onNext: { [weak self] result in
            guard let `self` = self else {return }
            
            guard let addressLookupResponse = result.element else {return }
            self.addressLookupResponse.accept(addressLookupResponse)

        }).disposed(by: disposeBag)
    }
    public func getAppartmentIDs() -> [AppartmentResponse]? {
         let premise_id = appartmentResponse.value

        return premise_id;
    }
    func validateZip(){
        validateZipCode.onNext(())
    }

    func fetchAppartmentDetails(){
        fetchAppartment.onNext(())
    }
    func validateAddress(){
        getAddressLookup.onNext(())
    }
    func refreshSession(){
        streetAddress = ""
        premiseID = ""
        validatedZipCodeResponse.accept(nil)
    }
}
