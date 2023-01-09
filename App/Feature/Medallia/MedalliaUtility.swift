//
//  MedalliaUtility.swift
//  EUMobile
//
//  Created by Krishnaveni, Eramalla on 06/12/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import Foundation
import MedalliaDigitalSDK
import SwiftUI


enum MedalliaPage {
    // iOS
    case reportOutage
    case stopService
    case moveService
    case payment
    
    var screenName: String {
        switch self {
        case .reportOutage:
            return "ReportOutage"
        case .stopService:
            return "StopService"
        case .moveService:
            return "MoveService"
        case .payment:
            return "Payment"
        }
     }
}

final class MedalliaUtility {
    
    static let shared = MedalliaUtility()
    let isProd = Configuration.shared.environmentName == .release
        || Configuration.shared.environmentName == .rc
    
    var isProdForMedallia: Bool {
        if (Configuration.shared.environmentName == .release
            || Configuration.shared.environmentName == .rc){
            return true
        }else{
            return false
        }
    }
    private init() {

    }
    
    //MARK: - Medallia SDK initilization
    func medalliaSDKInit(){
        MedalliaDigital.sdkInit(token:Configuration.shared.medalliaAPITocken, success: {
            Log.info("Medallia Init Success")
            MedalliaDigital.setCustomParameter(name: "isProd", value: self.isProdForMedallia.description.uppercased())
        }) { (error) in
            Log.error("Medallia Init Failure")
        }
    }
    
    //MARK: - Medallia SetCustomParam
    func medalliaSetCustomParam(pageName:String) {
            MedalliaDigital.setCustomParameter(name: "PageName", value: pageName)
    }
    
    //MARK: - Medallia SetCustomParams
    func medalliaSetCustomParams(params:[String : Any]) {
       MedalliaDigital.setCustomParameters(params)
      Log.info("Medallia Custom Parameters: \(params)")
    }
    
    //MARK: - Medallia StopService
    func medalliaStopService(customerID : String ,accountType : String , lowIncomeStatus : Bool , serviceType : String , amountDue : Double ){
        medalliaSetCustomParams(params: ["PageName" :MedalliaPage.stopService.screenName,"CustomerId​" : customerID, "AccountType" : accountType, "LowIncomeStatus​" : lowIncomeStatus, "ServiceType​" : serviceType, "AmountDue​" : amountDue])
    }
        
    //MARK: - Medallia MoveService
        func medalliaMoveService( customerID : String ,accountType : String , lowIncomeStatus : Bool , serviceType : String , amountDue : Double ){
            medalliaSetCustomParams(params: ["PageName" :MedalliaPage.moveService.screenName,"CustomerId​" : customerID, "AccountType" : accountType, "LowIncomeStatus​" : lowIncomeStatus, "ServiceType​" : serviceType, "AmountDue​" : amountDue])
        }
    
    //MARK: - Medallia MoveServiceAnon
    func medalliaMoveServiceAnon(customerPhoneNumber : String){
        medalliaSetCustomParams(params: ["PageName" :MedalliaPage.moveService.screenName,"CustomerPhoneNumber​" : customerPhoneNumber])
        }
    
    //MARK: - Medallia OutageReporting
    func medalliaOutageReporting( customerID : String ,accountType : String , lowIncomeStatus : Bool , serviceType : String , amountDue : Double ,outageID : String ,outageETR : String){
        medalliaSetCustomParams(params: ["PageName" :MedalliaPage.reportOutage.screenName,"CustomerId​" : customerID, "AccountType" : accountType, "LowIncomeStatus​" : lowIncomeStatus, "ServiceType​" : serviceType, "AmountDue​" : amountDue, "OutageID" : outageID,"OutageETR" : outageETR])
        }
    
    //MARK: - Medallia OutageReportingAnon
        func medalliaOutageReportingAnon(customerPhoneNumber : String ,outageID : String ,outageETR : String ){
            medalliaSetCustomParams(params: ["PageName" :MedalliaPage.reportOutage.screenName,"CustomerPhoneNumber​" : customerPhoneNumber, "OutageID" : outageID,"OutageETR" : outageETR])
        }
    
    //MARK: - Medallia Payment
    func medalliaPayment(customerID : String ,accountType : String , lowIncomeStatus : Bool , serviceType : String , amountDue : Double ){
        medalliaSetCustomParams(params: ["PageName" :MedalliaPage.payment.screenName,"CustomerId​" : customerID, "AccountType" : accountType, "LowIncomeStatus​" : lowIncomeStatus, "ServiceType​" : serviceType, "AmountDue​" : amountDue])
    }
}
