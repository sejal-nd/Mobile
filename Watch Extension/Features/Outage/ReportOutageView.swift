//
//  ReportOutageView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct ReportOutageView: View {
    private let imageName = AppImage.reportOutageSignIn.name
    private let text = "To report an outage, please use the mobile app"
    
    var body: some View {
        ImageTextView(imageName: imageName,
                      text: text)
            .onAppear(perform: logAnalytics)
    }
    
    private func logAnalytics() {
        AnalyticController.logScreenView(.reportOuage)
    }
}

struct ReportOutageView_Previews: PreviewProvider {
    static var previews: some View {
        ReportOutageView()
    }
}
