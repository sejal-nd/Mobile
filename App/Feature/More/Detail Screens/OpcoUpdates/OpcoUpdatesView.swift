//
//  OpcoUpdatesView.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 10/26/23.
//  Copyright © 2023 Exelon Corporation. All rights reserved.
//

import SwiftUI
import EUDesignSystem

struct OpcoUpdatesView: View {
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        RootContainerView(state: viewModel.state) {
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.updates) { update in
                        OpcoUpdatesRow(update: update)
                    }
                }
                .padding(.top, 20)
            }
        } emptyView: {
            EmptyDataView(imageName: viewModel.emptyImageName,
                          text: viewModel.emptyText)
        } loadingView: {
            LoadingDotView()
        } errorView: {
            ErrorView(text: viewModel.errorText)
        }
        .navigationTitle("Updates")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible)
        .logScreenView(.opcoUpdates)
    }
}


struct OpcoUpdatesView_Previews: PreviewProvider {
    static var previews: some View {
        OpcoUpdatesView()
    }
}
