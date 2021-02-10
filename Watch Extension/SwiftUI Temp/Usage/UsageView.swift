//
//  UsageView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct UsageView: View {
    let usageState: UsageState
    let watchUsage: WatchUsage?
    
    var hasBothFuelTypes = false
    @State private var isShowingElectric = true
    
    init(usageState: UsageState,
         watchUsage: WatchUsage?) {
        self.usageState = usageState
        self.watchUsage = watchUsage
        
        if let watchUsage = watchUsage {
            if watchUsage.fuelTypes.count == 2 {
                self.hasBothFuelTypes = true
            } else {
                if watchUsage.fuelTypes.contains(.electric) {
                    isShowingElectric = true
                } else {
                    isShowingElectric = false
                }
            }
        }
    }
    
    private var usageCostText: String {
        if isShowingElectric {
            return watchUsage?.electricUsageCost ?? ""
        } else {
            return watchUsage?.gasUsageCost ?? ""
        }
    }
    
    private var projectedUsageCostText: String {
        if isShowingElectric {
            return watchUsage?.electricProjetedUsageCost ?? ""
        } else {
            return watchUsage?.gasProjetedUsageCost ?? ""
        }
    }
    
    private var billPeriodText: String {
        if isShowingElectric {
            return watchUsage?.electricBillPeriod ?? ""
        } else {
            return watchUsage?.gasBillPeriod ?? ""
        }
    }
    
    private var disclaimerText: String {
        "This is an estimate and the actual amount may vary based on your energy use, taxes, and fees."
    }
    
    #warning("Todo:         self.electricProgress = electricProgress, self.electricTimeToNextForecast = electricTimeToNextForecast")
    
    var body: some View {
        VStack {
            ZStack {
                Image("usageGraph21") // todo
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                
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
                    Label("Electric",
                          image: AppImage.electric.name)
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
        Group {
            UsageContainerView(usageState: .loading,
                               watchUsage: nil)
            
            UsageContainerView(usageState: .unavailable,
                               watchUsage: nil)
        }
        
        // Electric
        Group {
            UsageContainerView(usageState: .loaded,
                               watchUsage: PreviewData.usageElectricModeled)
            
            UsageContainerView(usageState: .loaded,
                               watchUsage: PreviewData.usageElectricUnmodeled)
            
            UsageContainerView(usageState: .loaded,
                               watchUsage: PreviewData.usageElectricUnforecasted)
        }
        
        // Gas
        Group {
            UsageContainerView(usageState: .loaded,
                               watchUsage: PreviewData.usageGasModeled)
            
            UsageContainerView(usageState: .loaded,
                               watchUsage: PreviewData.usageGasUnmodeled)
            
            UsageContainerView(usageState: .loaded,
                               watchUsage: PreviewData.usageGasUnforecasted)
        }
        
        // Both
        Group {
            UsageContainerView(usageState: .loaded,
                               watchUsage: PreviewData.usageGasAndElectricModeled)
            
            UsageContainerView(usageState: .loaded,
                               watchUsage: PreviewData.usageGasAndElectricUnmodeled)
            
            UsageContainerView(usageState: .loaded,
                               watchUsage: PreviewData.usageGasAndElectricUnforecasted)
        }
    }
}
