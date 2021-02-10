//
//  UsageContainerView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct UsageContainerView: View {
    let usageState: UsageState
    let watchUsage: WatchUsage?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AccountInfoBar(accountID: "234783242")
                
                switch usageState {
                case .loading, .loaded:
                    UsageView(usageState: usageState,
                              watchUsage: watchUsage)
                case .unavailable:
                    ImageTextView(imageName: AppImage.usage.name,
                                  text: "Usage is not available for this account")
                }
            }
        }
    }
}

struct UsageContainerView_Previews: PreviewProvider {
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
