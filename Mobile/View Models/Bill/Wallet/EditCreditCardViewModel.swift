//
//  EditCreditCardViewModel.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/28/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class EditCreditCardViewModel {
    
    let disposeBag = DisposeBag()
    
    let walletService: WalletService!
        
    let expMonth = Variable("")
    let expYear = Variable("")
    let cvv = Variable("")
    let zipCode = Variable("")
    
    var oneTouchPayInitialValue = Variable(false)
    let oneTouchPay = Variable(false)
    
    var accountDetail: AccountDetail! // Passed from WalletViewController
    var walletItem: WalletItem! // Passed from WalletViewController
    
    required init(walletService: WalletService) {
        self.walletService = walletService
    }
    
    func saveButtonIsEnabled() -> Observable<Bool> {
        if Environment.sharedInstance.opco == .bge {
//            return Observable.combineLatest([expMonthIs2Digits(), expMonthIsValidMonth(), expYearIs4Digits(), expYearIsNotInPast(), cvvIsCorrectLength(), zipCodeIs5Digits()]) {
//                return !$0.contains(false)
//            }
            return Observable.combineLatest(oneTouchPayInitialValue.asObservable(), oneTouchPay.asObservable()) {
                return $0 != $1
            }
        } else {
            return Observable.combineLatest(webServicesDataChanged(), oneTouchPayInitialValue.asObservable(), oneTouchPay.asObservable()) {
                return $0 || ($1 != $2)
            }
        }
    }
    
    func webServicesDataChanged() -> Observable<Bool> {
        return Observable.combineLatest(expMonthIs2Digits(), expMonthIsValidMonth(), expYearIs4Digits(), expYearIsNotInPast(), cvvIsCorrectLength(), zipCodeIs5Digits()) {
            return ($0 && $1 && $2 && $3) || $4 || $5
        }
    }
    
    func expMonthIs2Digits() -> Observable<Bool> {
        return expMonth.asObservable().map {
            return $0.characters.count == 2
        }
    }
    
    func expMonthIsValidMonth() -> Observable<Bool> {
        return expMonth.asObservable().map {
            return $0 == "01" || $0 == "02" || $0 == "03" || $0 == "04" || $0 == "05" || $0 == "06" || $0 == "07" || $0 == "08" || $0 == "09" || $0 == "10" || $0 == "11" || $0 == "12"
        }
    }
    
    func expYearIs4Digits() -> Observable<Bool> {
        return expYear.asObservable().map {
            return $0.characters.count == 4
        }
    }
    
    func expYearIsNotInPast() -> Observable<Bool> {
        return expYear.asObservable().map {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            let enteredYear = formatter.date(from: $0)
            let todayYear = formatter.date(from: formatter.string(from: Date()))
            
            if let enteredYear = enteredYear, let todayYear = todayYear {
                return enteredYear >= todayYear
            }
            return false
        }
    }
    
    func cvvIsCorrectLength() -> Observable<Bool> {
        return cvv.asObservable().map {
            return $0.characters.count == 3 || $0.characters.count == 4
        }
    }
    
    func zipCodeIs5Digits() -> Observable<Bool> {
        return zipCode.asObservable().map {
            return $0.characters.count == 5
        }
    }
    
    func editCreditCard(onSuccess: @escaping () -> Void, onError: @escaping (FiservError) -> Void) {
        walletService.updateCreditCard(walletItem.walletItemID!, customerNumber: accountDetail.customerInfo.number!, expirationMonth: expMonth.value.isEmpty ? nil : expMonth.value, expirationYear: expYear.value.isEmpty ? nil : expYear.value, securityCode: cvv.value.isEmpty ? nil : cvv.value, postalCode: zipCode.value.isEmpty ? nil : zipCode.value, nickname: nil)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onSuccess()
            }, onError: { err in
                let error = FiservErrorMapper.sharedInstance.getError(message: err.localizedDescription, context: "wallet")
                onError( error )
            })
            .addDisposableTo(disposeBag)
    }
    
    func deleteCreditCard(onSuccess: @escaping () -> Void, onError: @escaping (FiservError) -> Void) {
        walletService.deletePaymentMethod(walletItem)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onSuccess()
            }, onError: { err in
                let error = FiservErrorMapper.sharedInstance.getError(message: err.localizedDescription, context: "wallet")
                onError( error )
            })
            .addDisposableTo(disposeBag)
    }
}
