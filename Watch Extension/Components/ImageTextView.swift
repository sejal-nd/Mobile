//
//  ImageTextView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct ImageTextView: View {
    let imageName: String
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(imageName)
            Text(text)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
        }
    }
}

struct ImageTextView_Previews: PreviewProvider {
    static var previews: some View {
        ImageTextView(imageName: AppImage.maintenanceMode.name,
                      text: "Scheduled Maintenance")
    }
}
