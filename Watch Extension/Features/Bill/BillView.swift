//
//  BillView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct BillView: View {
    let bill: WatchBill
    let account: WatchAccount
    let isLoading: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Alert
                if let alertText = bill.alertText {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.orange)
                            Spacer()
                            Text(alertText)
                        }
                    }
                    .padding()
                    .background(CardView())
                }
                
                // Bill Ready
                if bill.isBillReady {
                    Group {
                        if let totalAmountDueText = bill.totalAmountDueText,
                           let totalAmountDueDateText = bill.totalAmountDueDateText {
                            Text(totalAmountDueText)
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text(totalAmountDueDateText)
                        }
                        
                        // Auto Pay
                        if bill.isEnrolledInAutoPay {
                            ImageTextView(imageName: AppConstant.ImageName.autoPay.rawValue,
                                          text: "You are enrolled in Autopay")
                        }
                        
                        // Scheduled Payment
                        if let scheduledPaymentText = bill.scheduledPaymentAmountText {
                            ImageTextView(imageName: AppConstant.ImageName.scheduledPayment.rawValue,
                                          text: scheduledPaymentText)
                        }
                        
                        // Thank You For Payment
                        if let paymentReceivedAmountText = bill.paymentReceivedAmountText {
                            ImageTextView(imageName: AppConstant.ImageName.thankYouPayment.rawValue,
                                          title: paymentReceivedAmountText,
                                          text: "Thank you for your payment")
                            
                        }
                    }
                } else {
                    // Bill not ready
                    ImageTextView(imageName: AppConstant.ImageName.billNotReady.rawValue,
                                  text: "Your bill will be available here once it is ready")
                }
                
                Group {
                    // Catch Up on Agreement
                    if let catchUpAmountText = bill.catchUpAmountText,
                       let catchUpDateText = bill.catchUpDateText {
                        BillCard(value: catchUpAmountText,
                                 title: "Catch Up on Agreement Amount",
                                 dateText: catchUpDateText)
                    }
                    
                    // Past Due Amount
                    if let pastDueAmountText = bill.pastDueAmountText {
                        BillCard(value: pastDueAmountText,
                                 title: "Past Due Amount",
                                 dateText: "Due Immdiately",
                                 dateColor: .red)
                    }
                    
                    // Current Bill
                    if let currentBillAmountText = bill.currentBillAmountText,
                       let currentBillDateText = bill.currentBillDateText {
                        BillCard(value: currentBillAmountText,
                                 title: "Current Bill Amount",
                                 dateText: currentBillDateText)
                    }
                    
                    // Pending Payments
                    if let pendingPaymentAmountText = bill.pendingPaymentAmountText {
                        BillCard(value: pendingPaymentAmountText,
                                 shouldItalisizeValue: true,
                                 title: "Pending Payments")
                    }
                    
                    // Remaining Balance Due
                    if let remainingBalanceAmountText = bill.remainingBalanceAmountText {
                        BillCard(value: remainingBalanceAmountText,
                                 title: "Remaining Balance Due",
                                 dateText: "Due Immediately",
                                 dateColor: .red)
                    }
                }
                
                Text("If you recently changed your energy supplier, a portion of your balance may have an earlier due date. Please view your previous bills and corresponding due dates.")
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.gray)
                    .font(.footnote)
            }
        }
    }
}

struct BillView_Previews: PreviewProvider {
    static var previews: some View {
        BillView(bill: PreviewData.billDefault,
                 account: PreviewData.accounts[0],
                 isLoading: true)
        
        BillView(bill: PreviewData.billStandard,
                 account: PreviewData.accounts[0],
                 isLoading: false)
        
        BillView(bill: PreviewData.billAutoPay,
                 account: PreviewData.accounts[0],
                 isLoading: false)
        
        BillView(bill: PreviewData.billPrecarious,
                 account: PreviewData.accounts[0],
                 isLoading: false)
    }
}
