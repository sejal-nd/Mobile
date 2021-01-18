//
//  InfoLabel.swift
//  DebugMenu
//
//  Created by Joseph Erlandson on 1/11/21.
//

#if canImport(SwiftUI)
import SwiftUI
#endif

@available(iOS 14, *)
struct InfoLabel: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.gray)
                .multilineTextAlignment(.trailing)
        }
        .contextMenu {
            // Copy Value
            Button(action: {
                UIPasteboard.general.string = value
            }) {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
    }
}

@available(iOS 14, *)
struct InfoLabel_Previews: PreviewProvider {
    static var previews: some View {
        InfoLabel(title: "Base URL",
                  value: "https://www.test.com")
    }
}
