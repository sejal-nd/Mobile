//
//  BillingInfo.swift
//  Mobile
//
//  Created by Cody Dillon on 6/30/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct BillingInfo: Decodable {
    let netDueAmount: Double?
    let pastDueAmount: Double?
    let pastDueRemaining: Double?
    let lastPaymentAmount: Double?
    let lastPaymentDate: Date?
    let remainingBalanceDue: Double?
    let restorationAmount: Double?
    let amtDpaReinst: Double?
    let dueByDate: Date?
    let disconnectNoticeArrears: Double?
    let isDisconnectNotice: Bool
    let billDate: Date?
    let convenienceFee: Double
    let scheduledPayment: PaymentItem?
    let pendingPayments: [PaymentItem]
    let atReinstateFee: Double?
    let currentDueAmount: Double?
    let turnOffNoticeExtensionStatus: String?
    let turnOffNoticeExtendedDueDate: Date?
    let turnOffNoticeDueDate: Date?
    let deliveryCharges: Double?
    let supplyCharges: Double?
    let taxesAndFees: Double?
    let documentID: String?
    let isDpaEnrolled: String?
    
    let minPaymentAmount: Double
    // These are both private because the `maxPaymentAmount(bankOrCard:)` function should be used instead
    private let _maxPaymentAmount: Double
    private let _maxPaymentAmountACH: Double
    
    enum CodingKeys: String, CodingKey {
        case netDueAmount
        case pastDueAmount
        case pastDueRemaining
        case lastPaymentAmount
        case lastPaymentDate
        case remainingBalanceDue
        case restorationAmount
        case amtDpaReinst
        case dueByDate
        case disconnectNoticeArrears
        case isDisconnectNotice
        case billDate
        case convenienceFee
        case scheduledPayment
        case pendingPayments
        case atReinstateFee
        case currentDueAmount
        case turnOffNoticeExtensionStatus
        case turnOffNoticeExtendedDueDate
        case turnOffNoticeDueDate
        case deliveryCharges
        case supplyCharges
        case taxesAndFees
        case minPaymentAmount = "minimumPaymentAmount"
        case maxPaymentAmount = "maximumPaymentAmount"
        case maxPaymentAmountACH = "maximumPaymentAmountACH"
        case payments
        case documentID
        case isDpaEnrolled
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        netDueAmount = try container.decodeIfPresent(Double.self, forKey: .netDueAmount)
        pastDueAmount = try container.decodeIfPresent(Double.self, forKey: .pastDueAmount)
        pastDueRemaining = try container.decodeIfPresent(Double.self, forKey: .pastDueRemaining)
        lastPaymentAmount = try container.decodeIfPresent(Double.self, forKey: .lastPaymentAmount)
        lastPaymentDate = try container.decodeIfPresent(Date.self, forKey: .lastPaymentDate)
        remainingBalanceDue = try container.decodeIfPresent(Double.self, forKey: .remainingBalanceDue)
        restorationAmount = try container.decodeIfPresent(Double.self, forKey: .restorationAmount)
        amtDpaReinst = try container.decodeIfPresent(Double.self, forKey: .amtDpaReinst)
        dueByDate = try container.decodeIfPresent(Date.self, forKey: .dueByDate)
        disconnectNoticeArrears = try container.decodeIfPresent(Double.self, forKey: .disconnectNoticeArrears)
        isDisconnectNotice = try container.decodeIfPresent(Bool.self, forKey: .isDisconnectNotice) ?? false
        billDate = try container.decodeIfPresent(Date.self, forKey: .billDate)
        atReinstateFee = try container.decodeIfPresent(Double.self, forKey: .atReinstateFee)
        minPaymentAmount = try container.decodeIfPresent(Double.self, forKey: .minPaymentAmount) ?? 5
        _maxPaymentAmount = try container.decodeIfPresent(Double.self, forKey: .maxPaymentAmount) ?? 5000
        _maxPaymentAmountACH = try container.decodeIfPresent(Double.self, forKey: .maxPaymentAmountACH) ?? 100000
        currentDueAmount = try container.decodeIfPresent(Double.self, forKey: .currentDueAmount)
        convenienceFee = try container.decode(Double.self, forKey: .convenienceFee)
        turnOffNoticeExtensionStatus = try container.decodeIfPresent(String.self, forKey: .turnOffNoticeExtensionStatus)
        documentID = try container.decodeIfPresent(String.self, forKey: .documentID)
        turnOffNoticeExtendedDueDate = try container.decodeIfPresent(Date.self, forKey: .turnOffNoticeExtendedDueDate)
        turnOffNoticeDueDate = try container.decodeIfPresent(Date.self, forKey: .turnOffNoticeDueDate)
        deliveryCharges = try container.decodeIfPresent(Double.self, forKey: .deliveryCharges)
        supplyCharges = try container.decodeIfPresent(Double.self, forKey: .supplyCharges)
        taxesAndFees = try container.decodeIfPresent(Double.self, forKey: .taxesAndFees)
        isDpaEnrolled = try container.decodeIfPresent(String.self, forKey: .isDpaEnrolled)
        
        let paymentItems = try container.decodeIfPresent([PaymentItem].self, forKey: .payments)
        
        scheduledPayment = paymentItems?.filter { $0.status == .scheduled }.last
        pendingPayments = paymentItems?
            .filter { $0.status == .pending || $0.status == .processing } ?? []
    }
    
    var pendingPaymentsTotal: Double {
        return pendingPayments.map(\.amount).reduce(0, +)
    }
    
    func maxPaymentAmount(bankOrCard: BankOrCard) -> Double {
        switch bankOrCard {
        case .bank:
            return _maxPaymentAmountACH
        case .card:
            return _maxPaymentAmount
        }
    }
}
