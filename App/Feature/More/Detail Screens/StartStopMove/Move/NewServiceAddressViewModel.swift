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
    var suiteNumber: String?

    var disposeBag = DisposeBag()
    private let isLoading = BehaviorRelay(value: false)
    private (set) lazy var showLoadingState: Observable<Bool> = isLoading.asObservable()
    
    var validatedZipCodeResponse = BehaviorRelay<ValidatedZipCodeResponse?>(value: nil)
    var validateZipResponseEvent: Observable<ValidatedZipCodeResponse?> { return validatedZipCodeResponse.asObservable() }

    var appartmentResponse = BehaviorRelay<[AppartmentResponse]?>(value: [])
    var appartmentResponseEvent: Observable<[AppartmentResponse]?> { return appartmentResponse.asObservable() }
    var addressLookUpResponseEvent: Observable<[AddressLookupResponse]?> { return addressLookupResponse.asObservable() }

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
    
    var isUnauth: Bool {
        return moveServiceFlowData.unauthMoveData?.isUnauthMove ?? false
    }

    init( moveServiceFlowData: MoveServiceFlowData) {
        self.moveServiceFlowData = moveServiceFlowData
    }
    
    public func getAppartmentIDs() -> [AppartmentResponse]? {
        let premise_id = appartmentResponse.value
        return premise_id;
    }
    
    func refreshSession(){
        streetAddress = ""
        premiseID = nil
        suiteNumber = nil
        validatedZipCodeResponse.accept(nil)

    }
    func refreshAppartmentSession(){
        premiseID = nil
        suiteNumber = nil
        self.appartmentResponse.accept(nil)
    }
    func setAddressData(movepDataFlow: MoveServiceFlowData) {

        if let addressResponse_lookUp = movepDataFlow.addressLookupResponse, let addresss = addressResponse_lookUp.first {
            self.addressLookupResponse.accept(movepDataFlow.addressLookupResponse)

            self.zipCode = addresss.zipCode
            self.premiseID = addresss.premiseID
        }
        if let suiteNumber = movepDataFlow.selected_appartment?.suiteNumber,let premiseID =   movepDataFlow.selected_appartment?.premiseID{
            self.premiseID = premiseID
            self.suiteNumber = suiteNumber
        }
        if let str_Add = movepDataFlow.selected_StreetAddress{
            self.streetAddress = str_Add
        }
        if let apprt_list = moveServiceFlowData.appartment_List {
            appartmentResponse.accept(apprt_list)
        }
    }

    func setStreetAddress(_ address:String){
        self.streetAddress = address
        self.moveServiceFlowData.selected_StreetAddress =  self.streetAddress
    }
    func setAppartment(_ appartment:AppartmentResponse?){
        self.premiseID = appartment?.premiseID
        self.suiteNumber = appartment?.suiteNumber
        self.moveServiceFlowData.selected_appartment = appartment
    }
    
    func validateZipCode(onSuccess: @escaping ((ValidatedZipCodeResponse)-> Void), onFailure: @escaping ((Error)-> Void)) {
        
        if !self.isLoading.value {
            self.isLoading.accept(true)
        }
        if let unauthMoveData = moveServiceFlowData.unauthMoveData, unauthMoveData.isUnauthMove {
            validateZipCodeUnauthentication(onSuccess: onSuccess, onFailure: onFailure)
        } else {
            validateZipCodeAuthentication(onSuccess: onSuccess, onFailure: onFailure)
        }
    }
    
    private func validateZipCodeAuthentication(onSuccess: @escaping ((ValidatedZipCodeResponse)-> Void), onFailure: @escaping ((Error)-> Void)) {
        MoveService.validateZip(code: self.zipCode!) { [weak self] (result: Result<ValidatedZipCodeResponse, NetworkingError>) in
            guard let `self` = self else { return }
            switch result {
            case .success(let validatedZipCodeResponse):
                self.validatedZipCodeResponse.accept(validatedZipCodeResponse)
                if self.isLoading.value {
                    self.isLoading.accept(false)
                }
                onSuccess(validatedZipCodeResponse)
            case .failure(let error):
                self.isLoading.accept(false)
                onFailure(error)
            }
        }
    }

    private func validateZipCodeUnauthentication(onSuccess: @escaping ((ValidatedZipCodeResponse)-> Void), onFailure: @escaping ((Error)-> Void)) {
        MoveService.validateZipAnon(code: self.zipCode!) { [weak self] (result: Result<ValidatedZipCodeResponse, NetworkingError>) in
            guard let `self` = self else { return }
            switch result {
            case .success(let validatedZipCodeResponse):
                self.validatedZipCodeResponse.accept(validatedZipCodeResponse)
                if self.isLoading.value {
                    self.isLoading.accept(false)
                }
                onSuccess(validatedZipCodeResponse)
            case .failure(let error):
                self.isLoading.accept(false)
                onFailure(error)
            }
        }
    }

    
    func fetchAppartment(onSuccess: @escaping(([AppartmentResponse])-> Void), onFailure: @escaping((Error) -> Void)) {
        
        if !self.isLoading.value {
            self.isLoading.accept(true)
        }
        if let unauthMoveData = moveServiceFlowData.unauthMoveData, unauthMoveData.isUnauthMove {
            fetchAppartmentUnauthentication(onSuccess: onSuccess, onFailure: onFailure)

        } else {
            fetchAppartmentAuthentication(onSuccess: onSuccess, onFailure: onFailure)
        }
    }
    
    private func fetchAppartmentAuthentication(onSuccess: @escaping(([AppartmentResponse])-> Void), onFailure: @escaping((Error) -> Void)) {
        MoveService.fetchAppartment(address: self.streetAddress!, zipcode: self.zipCode!) { [weak self] (result: Result<[AppartmentResponse], NetworkingError>) in
            guard let `self` = self else { return }
            switch result {
            case .success(let appartmentResp):
                if self.isLoading.value {
                    self.isLoading.accept(false)
                }
                self.appartmentResponse.accept(appartmentResp)
                self.moveServiceFlowData.appartment_List = appartmentResp
                onSuccess(appartmentResp)
            case .failure(let error):
                self.isLoading.accept(false)
                onFailure(error)
            }
        }
    }
    
    private func fetchAppartmentUnauthentication(onSuccess: @escaping(([AppartmentResponse])-> Void), onFailure: @escaping((Error) -> Void)) {
        MoveService.fetchAppartmentAnon(address: self.streetAddress!, zipcode: self.zipCode!) { [weak self] (result: Result<[AppartmentResponse], NetworkingError>) in
            guard let `self` = self else { return }
            switch result {
            case .success(let appartmentResp):
                if self.isLoading.value {
                    self.isLoading.accept(false)
                }
                self.appartmentResponse.accept(appartmentResp)
                self.moveServiceFlowData.appartment_List = appartmentResp
                onSuccess(appartmentResp)
            case .failure(let error):
                self.isLoading.accept(false)
                onFailure(error)
            }
        }
    }

    
    func lookupAddress(onSuccess: @escaping(([AddressLookupResponse]) -> Void), onFailure: @escaping((Error) -> Void)) {
        
        if !self.isLoading.value {
            self.isLoading.accept(true)
        }
        if let unauthMoveData = moveServiceFlowData.unauthMoveData, unauthMoveData.isUnauthMove {
            lookupAddressUnauthentication(onSuccess: onSuccess, onFailure: onFailure)
        } else {
            lookupAddressAuthentication(onSuccess: onSuccess, onFailure: onFailure)
        }
    }
    
    private func lookupAddressAuthentication(onSuccess: @escaping(([AddressLookupResponse]) -> Void), onFailure: @escaping((Error) -> Void)) {
        MoveService.lookupAddress(address: self.streetAddress!, zipcode: self.zipCode!, premiseID:self.premiseID!) { [weak self] (result: Result<[AddressLookupResponse], NetworkingError>) in
            guard let `self` = self else { return }
            switch result {
            case .success(let addressLookupResponse):
                if self.isLoading.value {
                    self.isLoading.accept(false)
                }
                self.addressLookupResponse.accept(addressLookupResponse)
                onSuccess(addressLookupResponse)
            case .failure( let error):
                self.isLoading.accept(false)
                onFailure(error)
            }
        }
    }
    
    private func lookupAddressUnauthentication(onSuccess: @escaping(([AddressLookupResponse]) -> Void), onFailure: @escaping((Error) -> Void)) {
        MoveService.lookupAddressAnon(address: self.streetAddress!, zipcode: self.zipCode!, premiseID:self.premiseID!) { [weak self] (result: Result<[AddressLookupResponse], NetworkingError>) in
            guard let `self` = self else { return }
            switch result {
            case .success(let addressLookupResponse):
                if self.isLoading.value {
                    self.isLoading.accept(false)
                }
                self.addressLookupResponse.accept(addressLookupResponse)
                onSuccess(addressLookupResponse)
            case .failure( let error):
                self.isLoading.accept(false)
                onFailure(error)
            }
        }
    }
}

