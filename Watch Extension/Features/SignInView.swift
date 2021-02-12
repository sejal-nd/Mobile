//
//  SignInView.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct SignInView: View {
    private let imageName = AppImage.signin.name
    private let text = "Please sign in on your iPhone"
    
    var body: some View {
        ImageTextView(imageName: imageName,
                      text: text)
            .onAppear(perform: logAnalytics)
    }
    
    private func logAnalytics() {
        AnalyticController.logScreenView(.signIn)
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
    }
}
