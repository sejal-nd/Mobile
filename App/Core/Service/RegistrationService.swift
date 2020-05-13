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
     username       String  Username to register. Must be a valid email address.
     password       String  Account password
     accountNum     String  Account number
     identifier     String  Last4ofSSN,TaxIDorBGEPin
     phone          String  Account phone number
     question1      String  First security question
     answer1        String  Answer to first security question
     question2      String  Second security question
     answer2        String  Answer to second security question
     question3      String  Third security question
     answer3        String  Answer to third security question
     set_primary    String  Certain commercial accounts are allowed to have multiple profiles.
     enroll_ebill   String  Set this to true when the customer has elected to enroll in Electronic Billing.
     */
    func createNewAccount(username: String,
                          password: String,
                          accountNum: String?,
                          identifier: String,
                          phone: String,
                          question1: String,
                          answer1: String,
                          question2: String,
                          answer2: String,
                          question3: String,
                          answer3: String,
                          isPrimary: String,
                          isEnrollEBill: String) -> Observable<Void>
    
    /*
     username	String   Username to check for uniqueness
     */
    func checkForDuplicateAccount(_ username: String) -> Observable<Void>
    
    func loadSecretQuestions() -> Observable<[String]>
    
    /*
     identifier		String	Last 4 of SSN, Tax ID or BGE Pin
     phone			String	Account phone number
     account_num	String	Account number to register (BGE optional)
     */
    func validateAccountInformation(_ identifier: String, phone: String, accountNum: String?) -> Observable<[String: Any]>
    
    /*
     username	String   Registered username
     */
    func resendConfirmationEmail(_ username: String) -> Observable<Void>
    
    /*
     guid		String   The GUID from the email to validate
     */
    func validateConfirmationEmail(_ guid: String) -> Observable<Void>
    
}
