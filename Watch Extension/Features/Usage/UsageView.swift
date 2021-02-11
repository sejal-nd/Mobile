//
//  UsageView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct UsageView: View {
    internal init(usage: WatchUsage, account: WatchAccount, isLoading: Bool) {
        self.usage = usage
        self.account = account
        self.isLoading = isLoading
        
        if usage.fuelTypes.count == 2 {
            hasBothFuelTypes = true
        } else {
            if usage.fuelTypes.contains(.electric) {
                isShowingElectric = true
            } else {
                isShowingElectric = false
            }            
        }
    }
    
    let usage: WatchUsage
    let account: WatchAccount
    let isLoading: Bool

    @State private var isShowingElectric = true
    
    private var hasBothFuelTypes = false
    
    private var usageCostText: String {
        if isShowingElectric {
            return usage.electricUsageCost ?? ""
        } else {
            return usage.gasUsageCost ?? ""
        }
    }
    
    private var projectedUsageCostText: String {
        if isShowingElectric {
            return usage.electricProjetedUsageCost ?? ""
        } else {
            return usage.gasProjetedUsageCost ?? ""
        }
    }
    
    private var billPeriodText: String {
        if isShowingElectric {
            return usage.electricBillPeriod ?? ""
        } else {
            return usage.gasBillPeriod ?? ""
        }
    }
    
    private var disclaimerText: String {
        "This is an estimate and the actual amount may vary based on your energy use, taxes, and fees."
    }
    
    #warning("Todo:         self.electricProgress = electricProgress, self.electricTimeToNextForecast = electricTimeToNextForecast")
    
    var body: some View {
        VStack {
            ZStack {
                if !isLoading {
                    Image("usageGraph21") // todo
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                
                VStack {
                    Image(AppImage.gas.name)
                    Text("Spent So Far")
                    Text(usageCostText)
                        .fontWeight(.semibold)
                }
            }
            .padding(.bottom, 16)
            
            if hasBothFuelTypes {
                Button(action: {
                    isShowingElectric.toggle()
                }) {
                    Label(isShowingElectric ? "Electric" : "Gas",
                          image: isShowingElectric ? AppImage.electric.name : AppImage.gas.name)
                }
                .padding(.bottom, 16)
            }
            
            VStack(alignment: .leading,
                   spacing: 16) {
                VStack(alignment: .leading) {
                    Divider()
                    Text("Spent So Far")
                        .foregroundColor(.gray)
                    Text(usageCostText)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading) {
                    Divider()
                    Text("Projected Bill")
                        .foregroundColor(.gray)
                    Text(projectedUsageCostText)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading) {
                    Divider()
                    Text("Bill Period")
                        .foregroundColor(.gray)
                    Text(billPeriodText)
                        .foregroundColor(.gray)
                }
                
                Text(disclaimerText)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.gray)
                    .font(.footnote)
            }
        }
    }
}

struct UsageView_Previews: PreviewProvider {
    static var previews: some View {
        UsageView(usage: PreviewData.usageElectricModeled,
                  account: PreviewData.accounts[0],
                  isLoading: true)
        
        // Electric
        UsageView(usage: PreviewData.usageElectricModeled,
                  account: PreviewData.accounts[0],
                  isLoading: false)
        
        UsageView(usage: PreviewData.usageElectricUnmodeled,
                  account: PreviewData.accounts[0],
                  isLoading: false)
        
        // Gas
        UsageView(usage: PreviewData.usageGasModeled,
                  account: PreviewData.accounts[0],
                  isLoading: false)
        
        UsageView(usage: PreviewData.usageGasUnmodeled,
                  account: PreviewData.accounts[0],
                  isLoading: false)
        
        // Both
        UsageView(usage: PreviewData.usageGasAndElectricModeled,
                  account: PreviewData.accounts[0],
                  isLoading: false)
        
        UsageView(usage: PreviewData.usageGasAndElectricUnmodeled,
                  account: PreviewData.accounts[0],
                  isLoading: false)
    }
}
