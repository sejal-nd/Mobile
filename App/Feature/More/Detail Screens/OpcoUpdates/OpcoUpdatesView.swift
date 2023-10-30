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
        ScrollView {
            RootContainerView(state: viewModel.state) {
                LazyVStack {
                    ForEach(viewModel.updates) { update in
                        OpcoUpdatesRow(update: update)
                    }
                }
                .padding(.top, 20)
            } emptyView: {
                EmptyDataView(imageName: viewModel.emptyImageName,
                              text: viewModel.emptyText)
            } loadingView: {
                LoadingDotView() // is top justified...
            } errorView: {
                ErrorView(text: viewModel.errorText)
            }
        }
        .navigationTitle("Updates")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible)
    }
}


struct OpcoUpdatesView_Previews: PreviewProvider {
    static var previews: some View {
        OpcoUpdatesView()
    }
}
