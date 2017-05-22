//
//  RegistrationService.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

protocol RegistrationService {
	
	/*
	opco			String	The OpCo for the request.
	username		String	Username to register. Must be a valid email address.
	password		String	Account password
	identifier		String	Last4ofSSN,TaxIDorBGEPin
	phone			String	Account phone number
	question1		String	First security question
	answer1		String	Answer to first security question
	question2		String	Second security question
	answer2		String	Answer to second security question
	question3		String	Third security question
	answer3		String	Answer to third security question
	set_primary	String	Certain commercial accounts are allowed to have multiple profiles.
	enroll_ebill	String	Set this to true when the customer has elected to enroll in Electronic Billing.
	*/
	func createNewAccount(_ username: String,
	                      password: String,
	                      identifier: String,
	                      phone: String,
	                      question1: String,
	                      answer1: String,
	                      question2: String,
	                      answer2: String,
	                      question3: String,
	                      answer3: String,
	                      isPrimary: Bool,
	                      isEnrollEBill: Bool,
	                      completion: @escaping (_ result: ServiceResult<Void>) -> Void)
	
	/*
	opco		String   The OpCo for the request.
	username	String   Username to check for uniqueness
	*/
	func checkForDuplicateAccount(_ username: String,
	                              completion: @escaping (_ result: ServiceResult<Void>) -> Void)
	
	/*
	opco		String   The OpCo for the request.
	*/
	func loadSecretQuestions(_ completion: @escaping (_ result: ServiceResult<[String]>) -> Void)
	
	
	/*
	opco			String	The OpCo for the request.
	identifier		String	Last 4 of SSN, Tax ID or BGE Pin
	phone			String	Account phone number
	account_num		String	Account number to register (BGE optional)
	*/
	func validateAccountInformation(_ identifier: String,
	                                phone: String,
	                                accountNum: String,
	                                completion: @escaping (_ result: ServiceResult<[String: Any]>) -> Void)
	
	/*
	opco		String   The OpCo for the request.
	username	String   Username to check for uniqueness
	*/
	func resendConfirmationEmail(_ username: String,
	                             completion: @escaping (_ result: ServiceResult<Void>) -> Void)
	
	/*
	opco		String   The OpCo for the request.
	guid		String   The GUID from the email to validate
	*/
	func validateConfirmationEmail(_ guid: String,
	                               completion: @escaping (_ result: ServiceResult<Void>) -> Void)
	
	/*
	opco 		String   The OpCo for the request.
	username	String   The user's email address or username.
	 */
	func recoverPassword(_ username: String,
	                     completion: @escaping (_ result: ServiceResult<Void>) -> Void)
	
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - Reactive Extension to RegistrationService
extension RegistrationService {

	//
	func createNewAccount(_ username: String,
	                      password: String,
	                      identifier: String,
	                      phone: String,
	                      question1: String,
	                      answer1: String,
	                      question2: String,
	                      answer2: String,
	                      question3: String,
	                      answer3: String,
	                      isPrimary: Bool,
	                      isEnrollEBill: Bool) -> Observable<Void> {
		//
		return Observable.create { observer in
			self.createNewAccount(username,
			                      password: password,
			                      identifier: identifier,
			                      phone: phone,
			                      question1: question1,
			                      answer1: answer1,
			                      question2: question2,
			                      answer2: answer2,
			                      question3: question3,
			                      answer3: answer3,
			                      isPrimary: isPrimary,
			                      isEnrollEBill: isEnrollEBill,
			                      completion: { (result: ServiceResult<Void>) in
				//
				switch (result) {
				case ServiceResult.Success:
					observer.onNext()
					observer.onCompleted()
					
				case ServiceResult.Failure(let err):
					observer.onError(err)
				}
			})
			
			return Disposables.create()
		}
	}
	
	//
	func checkForDuplicateAccount(_ username: String) -> Observable<Void> {
		//
		return Observable.create { observer in
			self.checkForDuplicateAccount(username,
			                              completion: { (result: ServiceResult<Void>) in
				//
				switch (result) {
				case ServiceResult.Success:
					observer.onNext()
					observer.onCompleted()
					
				case ServiceResult.Failure(let err):
					observer.onError(err)
				}
			})
			
			return Disposables.create()
		}
	}
	
	//
	func loadSecretQuestions() -> Observable<[String]> {
		//
		return Observable.create { observer in
			self.loadSecretQuestions{ (result: ServiceResult<[String]>) in
				//
				switch (result) {
				case ServiceResult.Success(let questions):
					observer.onNext(questions)
					observer.onCompleted()
					
					print(questions)
					
				case ServiceResult.Failure(let err):
					observer.onError(err)
				}
			}
			
			return Disposables.create()
		}
	}
	
	//
	func validateAccountInformation(_ identifier: String, phone: String, accountNum: String) -> Observable<[String: Any]> {
		return Observable.create { observer in
			self.validateAccountInformation(identifier,
			                                phone: phone,
			                                accountNum: accountNum,
			                                completion: { (result: ServiceResult<[String: Any]>) in
				//
				switch (result) {
				case ServiceResult.Success(let response):
					observer.onNext(response)
					observer.onCompleted()
					
				case ServiceResult.Failure(let err):
					observer.onError(err)
				}
			})
			
			return Disposables.create()
		}
	}

	//
	func resendConfirmationEmail(_ username: String) -> Observable<Void> {
		return Observable.create { observer in
			self.resendConfirmationEmail(username,
										 completion: { (result: ServiceResult<Void>) in
				//
				switch (result) {
				case ServiceResult.Success:
					observer.onNext()
					observer.onCompleted()
					
				case ServiceResult.Failure(let err):
					observer.onError(err)
				}
			})
			
			return Disposables.create()
		}
	}

	//
	func validateConfirmationEmail(_ guid: String) -> Observable<Void> {
		return Observable.create { observer in
			self.validateConfirmationEmail(guid,
			                               completion: { (result: ServiceResult<Void>) in
				//
				switch (result) {
				case ServiceResult.Success:
					observer.onNext()
					observer.onCompleted()
					
				case ServiceResult.Failure(let err):
					observer.onError(err)
				}
			})
			
			return Disposables.create()
		}
	}
	
	func recoverPassword(_ username: String) -> Observable<Void> {
		return Observable.create {observer in
			self.recoverPassword(username,
			                     completion: { (result: ServiceResult<Void>) in
				//
				switch (result) {
				case ServiceResult.Success:
					observer.onNext()
					observer.onCompleted()
					
				case ServiceResult.Failure(let err):
					observer.onError(err)
				}
			})
			
			return Disposables.create()
		}
	}

}





