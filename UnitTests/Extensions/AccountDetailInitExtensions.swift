//
//  AccountDetailTestInits.swift
//  Mobile
//
//  Created by Sam Francis on 1/17/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Mapper

protocol JSONEncodable {
    func toJSON() -> [String: Any?]
}

private extension Date {
    var apiString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return dateFormatter.string(from: self)
    }
}

extension AccountDetail {
    
    init(accountNumber: String = "1234",
         premiseNumber: String? = nil,
         address: String? = nil,
         serviceType: String = "GAS/ELECTRIC",
         customerInfo: CustomerInfo = CustomerInfo(),
         billingInfo: BillingInfo = BillingInfo(),
         serInfo: SERInfo = SERInfo(),
         isPTSAccount: Bool = false,
         premiseInfo: [Premise] = [],
         isModeledForOpower: Bool = false,
         isPasswordProtected: Bool = false,
         isBudgetBill: Bool = false,
         isBudgetBillEligible: Bool = false,
         budgetBillMessage: Bool = false,
         isEBillEnrollment: Bool = false,
         isEBillEligible: Bool = false,
         hasElectricSupplier: Bool = false,
         isSingleBillOption: Bool = false,
         isDualBillOption: Bool = false,
         isCashOnly: Bool = false,
         isSupplier: Bool = false,
         activeSeverance: Bool = false,
         isHourlyPricing: Bool = false,
         status: String? = nil,
         isAutoPay: Bool = false,
         isBGEasy: Bool = false,
         isAutoPayEligible: Bool = false,
         isCutOutNonPay: Bool = false,
         isLowIncome: Bool = false,
         flagFinaled: Bool = false,
         isAMIAccount: Bool = false,
         isResidential: Bool = false,
         releaseOfInformation: String? = nil,
         peakRewards: String? = nil,
         zipCode: String? = nil) {
        
        if Environment.sharedInstance.environmentName != "AUT" {
            fatalError("init only available for tests")
        }
        
        var map = [String: Any]()
        map["accountNumber"] = accountNumber
        map["premiseNumber"] = premiseNumber
        map["address"] = address
        map["serviceType"] = serviceType
        map["CustomerInfo"] = customerInfo.toJSON()
        map["BillingInfo"] = billingInfo.toJSON()
        map["SERInfo"] = serInfo.toJSON()
        map["PremiseInfo"] = premiseInfo.map(Premise.toJSON)
        
        map["isPTSAccount"] = isPTSAccount
        
        map["isModeledForOpower"] = isModeledForOpower
        map["isPasswordProtected"] = isPasswordProtected
        map["isBudgetBill"] = isBudgetBill
        map["isBudgetBillEligible"] = isBudgetBillEligible
        map["budgetBillMessage"] = budgetBillMessage
        map["isEBillEnrollment"] = isEBillEnrollment
        map["isEBillEligible"] = isEBillEligible
        map["hasElectricSupplier"] = hasElectricSupplier
        map["isSingleBillOption"] = isSingleBillOption
        map["isDualBillOption"] = isDualBillOption
        map["isCashOnly"] = isCashOnly
        map["isSupplier"] = isSupplier
        map["activeSeverance"] = activeSeverance
        map["isHourlyPricing"] = isHourlyPricing
        map["status"] = status
        map["isAutoPay"] = isAutoPay
        map["isBGEasy"] = isBGEasy
        map["isAutoPayEligible"] = isAutoPayEligible
        map["isCutOutNonPay"] = isCutOutNonPay
        map["isLowIncome"] = isLowIncome
        map["flagFinaled"] = flagFinaled
        map["isAMIAccount"] = isAMIAccount
        map["isResidential"] = isResidential
        map["releaseOfInformation"] = releaseOfInformation
        map["peakRewards"] = peakRewards
        map["zipCode"] = zipCode
        
        self = AccountDetail.from(map as NSDictionary)!
    }
}

extension BillingInfo: JSONEncodable {
    
    init(netDueAmount: Double? = nil,
         pastDueAmount: Double? = nil,
         pastDueRemaining: Double? = nil,
         lastPaymentAmount: Double? = nil,
         lastPaymentDate: Date? = nil,
         remainingBalanceDue: Double? = nil,
         restorationAmount: Double? = nil,
         amtDpaReinst: Double? = nil,
         dueByDate: Date? = nil,
         disconnectNoticeArrears: Double? = nil,
         isDisconnectNotice: Bool = false,
         billDate: Date? = nil,
         convenienceFee: Double? = nil,
         scheduledPayment: PaymentItem? = nil,
         pendingPayments: [PaymentItem] = [],
         atReinstateFee: Double? = nil,
         minPaymentAmount: Double? = nil,
         maxPaymentAmount: Double? = nil,
         minPaymentAmountACH: Double? = nil,
         maxPaymentAmountACH: Double? = nil,
         currentDueAmount: Double? = nil,
         residentialFee: Double? = nil,
         commercialFee: Double? = nil,
         turnOffNoticeExtensionStatus: String? = nil,
         turnOffNoticeExtendedDueDate: Date? = nil,
         deliveryCharges: Double? = nil,
         supplyCharges: Double? = nil,
         taxesAndFees: Double? = nil) {
        
        if Environment.sharedInstance.environmentName != "AUT" {
            fatalError("init only available for tests")
        }
        
        var payments = pendingPayments
        if let scheduledPayment = scheduledPayment {
            payments.append(scheduledPayment)
        }
        
        let map: [String: Any?] = [
            "netDueAmount": netDueAmount,
            "pastDueAmount": pastDueAmount,
            "pastDueRemaining": pastDueRemaining,
            "lastPaymentAmount": lastPaymentAmount,
            "lastPaymentDate": lastPaymentDate?.apiString,
            "remainingBalanceDue": remainingBalanceDue,
            "restorationAmount": restorationAmount,
            "amtDpaReinst": amtDpaReinst,
            "dueByDate": dueByDate?.apiString,
            "disconnectNoticeArrears": disconnectNoticeArrears,
            "isDisconnectNotice": isDisconnectNotice,
            "billDate": billDate?.apiString,
            "convenienceFee": convenienceFee,
            "atReinstateFee": atReinstateFee,
            "minPaymentAmount": minPaymentAmount,
            "maxPaymentAmount": maxPaymentAmount,
            "minPaymentAmountACH": minPaymentAmountACH,
            "maxPaymentAmountACH": maxPaymentAmountACH,
            "currentDueAmount": currentDueAmount,
            "residentialFee": residentialFee,
            "commercialFee": commercialFee,
            "turnOffNoticeExtensionStatus": turnOffNoticeExtensionStatus,
            "turnOffNoticeExtendedDueDate": turnOffNoticeExtendedDueDate,
            "deliveryCharges": deliveryCharges,
            "supplyCharges": supplyCharges,
            "taxesAndFees": taxesAndFees,
            "payments" : payments.map(PaymentItem.toJSON)
        ]
        
        self = BillingInfo.from(map as NSDictionary)!
    }
    
    func toJSON() -> [String : Any?] {
        var payments = pendingPayments
        if let scheduledPayment = scheduledPayment {
            payments.append(scheduledPayment)
        }
        
        return [
            "netDueAmount": netDueAmount,
            "pastDueAmount": pastDueAmount,
            "pastDueRemaining": pastDueRemaining,
            "lastPaymentAmount": lastPaymentAmount,
            "lastPaymentDate": lastPaymentDate?.apiString,
            "remainingBalanceDue": remainingBalanceDue,
            "restorationAmount": restorationAmount,
            "amtDpaReinst": amtDpaReinst,
            "dueByDate": dueByDate?.apiString,
            "disconnectNoticeArrears": disconnectNoticeArrears,
            "isDisconnectNotice": isDisconnectNotice,
            "billDate": billDate?.apiString,
            "convenienceFee": convenienceFee,
            "atReinstateFee": atReinstateFee,
            "minPaymentAmount": minPaymentAmount,
            "maxPaymentAmount": maxPaymentAmount,
            "minPaymentAmountACH": minPaymentAmountACH,
            "maxPaymentAmountACH": maxPaymentAmountACH,
            "currentDueAmount": currentDueAmount,
            "residentialFee": residentialFee,
            "commercialFee": commercialFee,
            "turnOffNoticeExtensionStatus": turnOffNoticeExtensionStatus,
            "turnOffNoticeExtendedDueDate": turnOffNoticeExtendedDueDate,
            "deliveryCharges": deliveryCharges,
            "supplyCharges": supplyCharges,
            "taxesAndFees": taxesAndFees,
            "payments" : payments.map(PaymentItem.toJSON)
        ]
    }
}

extension PaymentItem: JSONEncodable {
    
    init(amount: Double, date: Date? = nil, status: PaymentStatus = .scheduled) {
        
        if Environment.sharedInstance.environmentName != "AUT" {
            fatalError("init only available for tests")
        }
        
        let map: [String : Any?] = [
            "paymentAmount": amount,
            "status": status.rawValue,
            "paymentDate": date?.apiString
        ]
        
        self = PaymentItem.from(map as NSDictionary)!
    }
    
    func toJSON() -> [String : Any?] {
        return [
            "paymentAmount": amount,
            "status": status.rawValue,
            "paymentDate": date?.apiString
        ]
    }
}

extension CustomerInfo: JSONEncodable {
    
    init(emailAddress: String? = nil, number: String? = nil, firstName: String? = nil, nameCompressed: String? = nil) {
        
        if Environment.sharedInstance.environmentName != "AUT" {
            fatalError("init only available for tests")
        }
        
        let map: [String: Any?] = [
            "emailAddress" : emailAddress,
            "number" : number,
            "firstName" : firstName,
            "nameCompressed" : nameCompressed
        ]
        
        self = CustomerInfo.from(map as NSDictionary)!
    }
    
    func toJSON() -> [String : Any?] {
        return [
            "emailAddress" : emailAddress,
            "number" : number,
            "firstName" : firstName,
            "nameCompressed" : nameCompressed
        ]
    }
    
}

extension Premise: JSONEncodable {
    
    init(premiseNumber: String, addressGeneral: String? = nil, zipCode: String? = nil, addressLine: [String]? = nil, smartEnergyRewards: String? = nil) {
        
        if Environment.sharedInstance.environmentName != "AUT" {
            fatalError("init only available for tests")
        }
        
        let map: [String: Any?] = [
            "premiseNumber" : premiseNumber,
            "smartEnergyRewards": smartEnergyRewards,
            "mainAddress" : [
                "addressGeneral": addressGeneral as Any,
                "addressLine" : addressLine as Any,
                "townDetail" : [
                    "code" : zipCode
                ]
            ]
        ]
        
        self = Premise.from(map as NSDictionary)!
    }
    
    func toJSON() -> [String : Any?] {
        return [
            "premiseNumber" : premiseNumber,
            "smartEnergyRewards": smartEnergyRewards,
            "mainAddress" : [
                "addressGeneral": addressGeneral as Any,
                "addressLine" : addressLine as Any,
                "townDetail" : [
                    "code" : zipCode
                ]
            ]
        ]
    }
}

extension SERInfo: JSONEncodable {
    init(controlGroupFlag: String? = nil, eventResults: [SERResult] = []) {
        
        if Environment.sharedInstance.environmentName != "AUT" {
            fatalError("init only available for tests")
        }
        
        var map = [String: Any]()
        map["ControlGroupFlag"] = controlGroupFlag
        map["eventResults"] = eventResults.map(SERResult.toJSON)
        self = SERInfo.from(map as NSDictionary)!
    }
    
    func toJSON() -> [String : Any?] {
        return [
            "ControlGroupFlag" : controlGroupFlag,
            "eventResults" : eventResults.map(SERResult.toJSON)
        ]
    }
}

extension SERResult: JSONEncodable {
    init(actualKWH: Double,
         baselineKWH: Double,
         eventStart: String,
         eventEnd: String,
         savingDollar: Double,
         savingKWH: Double) {
        
        if Environment.sharedInstance.environmentName != "AUT" {
            fatalError("init only available for tests")
        }
        
        var map = [String: Any]()
        map["actualKWH"] = actualKWH
        map["baselineKWH"] = baselineKWH
        map["eventStart"] = eventStart
        map["eventEnd"] = eventEnd
        map["savingDollar"] = savingDollar
        map["savingKWH"] = savingKWH
        self = SERResult.from(map as NSDictionary)!
    }
    
    func toJSON() -> [String : Any?] {
        return [
            "actualKWH" : actualKWH,
            "baselineKWH" : baselineKWH,
            "eventStart" : eventStart.apiString,
            "eventEnd" : eventEnd.apiString,
            "savingDollar" : savingDollar,
            "savingKWH" : savingKWH
        ]
    }
}
