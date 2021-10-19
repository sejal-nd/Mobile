//
//  SafariContainerView.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 3/8/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

public struct SafariContainerView: View {
    let url: URL
    
    public init(url: URL) {
        self.url = url
    }
    
    public var body: some View {
        SafariView(url: url)
            .edgesIgnoringSafeArea(.bottom)
    }
}

struct SafariContainerView_Previews: PreviewProvider {
    static var previews: some View {
        SafariContainerView(url: URL(string: "https://apple.com")!)
    }
}
