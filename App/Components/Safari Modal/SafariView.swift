//
//  SafariView.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 3/8/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> some UIViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
}
