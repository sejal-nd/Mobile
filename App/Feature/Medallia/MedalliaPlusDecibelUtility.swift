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
import DecibelCore

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

final class MedalliaPlusDecibelUtility: DecibelDelegate {
    
    static let shared = MedalliaPlusDecibelUtility()
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
            MedalliaDigital.setLogLevel(MDLogLevel.debug)
            MedalliaDigital.setCustomParameter(name: "isProd", value: self.isProdForMedallia.description.uppercased())
        }) { (error) in
            Log.error("Medallia Init Failure")
        }
    }
    
    func decibelSDKInit() {
        if let decibalAccount = Configuration.shared.decibelTokens["Account"], let decibalPropertyID = Configuration.shared.decibelTokens["Property ID"] {
            DecibelSDK.shared.delegate = self
            DecibelSDK.shared.initialize(account: decibalAccount, property: decibalPropertyID)
            DecibelSDK.shared.setLogLevel(.info)
            DecibelSDK.shared.send(dimension: "isProd", withBool: self.isProdForMedallia)
            DecibelSDK.shared.setAutomaticMask(.labels)
            DecibelSDK.shared.setAutomaticMask(.inputs)
            DecibelSDK.shared.enabledSessionReplay(true)
        }
    }
    
    func getSessionURL(_ sessionUrl: String) {
        MedalliaDigital.setCustomParameter(name: "DecibelSessionUrl",
                                            value: sessionUrl)
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
    func medalliaStopService(customerID: String, accountType: String, lowIncomeStatus: Bool, serviceType: String, currentAmountDue: Double, netAmountDue: Double) {
        MedalliaDigital.setCustomParameter(name: "PageName", value: MedalliaPage.stopService.screenName)
        MedalliaDigital.setCustomParameter(name: "CustomerId", value: customerID)
        MedalliaDigital.setCustomParameter(name: "AccountType", value: accountType)
        MedalliaDigital.setCustomParameter(name: "LowIncomeStatus", value: lowIncomeStatus)
        MedalliaDigital.setCustomParameter(name: "ServiceType", value: serviceType)
        MedalliaDigital.setCustomParameter(name: "CurrentAmountDue", value: currentAmountDue)
        MedalliaDigital.setCustomParameter(name: "NetAmountDue", value: netAmountDue)
    }
        
    //MARK: - Medallia MoveService
        func medalliaMoveService(customerID: String, accountType: String, lowIncomeStatus: Bool, serviceType: String, currentAmountDue: Double, netAmountDue: Double) {
            MedalliaDigital.setCustomParameter(name: "PageName", value: MedalliaPage.moveService.screenName)
            MedalliaDigital.setCustomParameter(name: "CustomerId", value: customerID)
            MedalliaDigital.setCustomParameter(name: "AccountType", value: accountType)
            MedalliaDigital.setCustomParameter(name: "LowIncomeStatus", value: lowIncomeStatus)
            MedalliaDigital.setCustomParameter(name: "ServiceType", value: serviceType)
            MedalliaDigital.setCustomParameter(name: "CurrentAmountDue", value: currentAmountDue)
            MedalliaDigital.setCustomParameter(name: "NetAmountDue", value: netAmountDue)
        }
    
    //MARK: - Medallia MoveServiceAnon
    func medalliaMoveServiceAnon(customerPhoneNumber : String){
        MedalliaDigital.setCustomParameter(name: "PageName", value: MedalliaPage.moveService.screenName)
        MedalliaDigital.setCustomParameter(name: "CustomerPhoneNumber", value: customerPhoneNumber)
        }
    
    //MARK: - Medallia OutageReporting
    func medalliaOutageReporting(customerID: String, accountType: String, lowIncomeStatus: Bool, serviceType: String, currentAmountDue: Double, netAmountDue: Double, outageETR: String, customerPhoneNumber: String) {
        MedalliaDigital.setCustomParameter(name: "PageName", value: MedalliaPage.reportOutage.screenName)
        MedalliaDigital.setCustomParameter(name: "CustomerId", value: customerID)
        MedalliaDigital.setCustomParameter(name: "AccountType", value: accountType)
        MedalliaDigital.setCustomParameter(name: "LowIncomeStatus", value: lowIncomeStatus)
        MedalliaDigital.setCustomParameter(name: "ServiceType", value: serviceType)
        MedalliaDigital.setCustomParameter(name: "CurrentAmountDue", value: currentAmountDue)
        MedalliaDigital.setCustomParameter(name: "NetAmountDue", value: netAmountDue)
        MedalliaDigital.setCustomParameter(name: "OutageEtr", value: outageETR )
        }
    
    //MARK: - Medallia OutageReportingAnon
        func medalliaOutageReportingAnon(outageETR : String, customerPhoneNumber : String ) {
            MedalliaDigital.setCustomParameter(name: "PageName", value: MedalliaPage.reportOutage.screenName)
            MedalliaDigital.setCustomParameter(name: "OutageEtr", value: outageETR)
            MedalliaDigital.setCustomParameter(name: "CustomerPhoneNumber", value: customerPhoneNumber)
            
        }
    
    //MARK: - Medallia Payment
    func medalliaPayment(customerID: String, accountType: String, lowIncomeStatus: Bool, serviceType : String, currentAmountDue: Double, netAmountDue: Double) {
        MedalliaDigital.setCustomParameter(name: "PageName", value: MedalliaPage.payment.screenName)
        MedalliaDigital.setCustomParameter(name: "CustomerId", value: customerID)
        MedalliaDigital.setCustomParameter(name: "AccountType", value: accountType)
        MedalliaDigital.setCustomParameter(name: "LowIncomeStatus", value: lowIncomeStatus)
        MedalliaDigital.setCustomParameter(name: "ServiceType", value: serviceType)
        MedalliaDigital.setCustomParameter(name: "CurrentAmountDue", value: currentAmountDue)
        MedalliaDigital.setCustomParameter(name: "NetAmountDue", value: netAmountDue)
    }

    func showOutageTrackerSurvey(for outage: OutageTracker) {
        MedalliaDigital.setCustomParameters([
            "CustomerId": AccountsStore.shared.customerIdentifier ?? "",
            "OutageEtr": outage.etr ?? "",
            "OutageEtrType": outage.etrType ?? "",
            "OutageCause": outage.cause ?? "",
            "OutageId": outage.outageID ?? "",
            "TrackerStatus": outage.trackerStatus ?? "",
            "OutageValid": outage.isOutageValid
        ])
        
        MedalliaDigital.showForm("988") {
            Log.info("Outage Tracker Survey Displayed Successfully")
        } failure: { error in
            Log.error("Error displaying Outage Tracker Survey: \(error)")
        }
    }
}
