//
//  OpcoUpdatesViewModel.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 10/30/23.
//  Copyright © 2023 Exelon Corporation. All rights reserved.
//

import SwiftUI
import EUDesignSystem

extension OpcoUpdatesView {
    @MainActor class ViewModel: ObservableObject {
        @Published var state: ViewState = .loading
        @Published var updates = [Alert]()
        
        let emptyImageName = "ic_alerts_empty"
        let emptyText = "There are no updates at this time."
        
        // These may be app global, so we may want to eventually extract them
        let errorText = "Unable to retrieve data at this time. Please try again later."
        
        init() {
            fetchOpcoUpdates()
        }
        
        private func fetchOpcoUpdates() {
            withAnimation {
                state = .loading
            }
            
            AlertService.fetchAlertBanner(bannerOnly: false,
                                          stormOnly: false) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let updates):
                    self.updates = updates
                    
                    withAnimation {
                        if updates.isEmpty {
                            self.state = .empty
                        } else {
                            self.state = .loaded
                        }
                    }
                case .failure(let error):
                    Log.error("Error fetching opco updates: \(error)")
                    withAnimation {
                        self.state = .error
                    }
                }
            }
        }
    }
}
