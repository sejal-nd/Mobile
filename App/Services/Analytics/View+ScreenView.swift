//
//  View+ScreenView.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 11/21/23.
//  Copyright © 2023 Exelon Corporation. All rights reserved.
//

import SwiftUI
import FirebaseAnalytics

struct AnalyticScreenView: ViewModifier {
    let name: String
    func body(content: Content) -> some View {
        content
            .analyticsScreen(name: name)
    }
}

extension View {
    func logScreenView(_ firebaseScreen: FirebaseScreenView) -> some View {
        ModifiedContent(content: self, modifier: AnalyticScreenView(name: firebaseScreen.name))
    }
}
