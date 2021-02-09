//
//  ErrorViewContainer.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct ErrorContainerView: View {
    var errorState: ErrorState
    
    private var imageName: String {
        switch errorState {
        case .maintenanceMode:
            return AppImage.maintenanceMode.name
        case .passwordProtected:
            return AppImage.passwordProtected.name
        case .other:
            return AppImage.error.name
        }
    }
    
    private var text: String {
        switch errorState {
        case .maintenanceMode:
            return "Scheduled Maintenance"
        case .passwordProtected:            
            return "Password protected accounts cannot be accessed via app"
        case .other:
            return "Unable to retrieve data at this time. Please try again later."
        }
    }
    
    var body: some View {
        ImageTextView(imageName: imageName,
                      text: text)
    }
}

struct ErrorContainerView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorContainerView(errorState: .maintenanceMode)
    }
}
