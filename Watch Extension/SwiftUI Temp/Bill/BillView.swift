//
//  BillView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct BillView: View {
    let billState: BillState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Alert
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.orange)
                        Spacer()
                        Text("$150.00 is due immediately") // alert Text
                    }
                }
                .padding()
                .background(CardView())
                
                // Normal Bill
                Group {
                    Text("$1000.00")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Total Amount Due")
                    
                    // Auto Pay
                    ImageTextView(imageName: AppImage.autoPay.name,
                                  text: "You are enrolled in Autopay")
                    
                    // Scheduled Payment
                    ImageTextView(imageName: AppImage.scheduledPayment.name,
                                  text: "Thank you for scheduling your $1000.00 payment for 12/20/2018")
                    
                    // Thank You For Payment
                    VStack(spacing: 2) {
                        ImageTextView(imageName: AppImage.paymentConfirmation.name,
                                      text: "Thank you for your payment")
                        Text("$1000.00")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                
                Group {
                    // Catch Up on Agreement
                    BillCard(value: "$150.00",
                             title: "Catch Up on Agreement Amount",
                             dateText: "Due by 09/25/2020")
                    
                    // Past Due Amount
                    BillCard(value: "$500.00",
                             title: "Past Due Amount",
                             dateText: "Due Immdiately",
                             dateColor: .red)
                    
                    // Current Bill
                    BillCard(value: "$500.00",
                             title: "Current Bill Amount",
                             dateText: "Due by 09/25/2020")
                    
                    // Pending Payments
                    BillCard(value: "-$500.00",
                             title: "Pending Payments")
                    
                    // Remaining Balance Due
                    BillCard(value: "$80.00",
                             title: "Remaining Balance Due",
                             dateText: "Due by 09/25/2020")
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
        BillView(billState: .loaded)
    }
}
