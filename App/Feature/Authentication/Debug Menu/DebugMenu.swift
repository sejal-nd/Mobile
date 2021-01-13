//
//  DebugMenu.swift
//  DebugMenu
//
//  Created by Joseph Erlandson on 1/11/21.
//

#if canImport(SwiftUI)
import SwiftUI
#endif

@available(iOS 14, *)
struct DebugMenu: View {
    @SwiftUI.Environment(\.presentationMode) private var presentationMode
    
    @AppStorage("selectedProjectURL") private var selectedProjectURL: ProjectURLSuffix = .none
    
    private var versionString: String {
        Bundle.main.versionNumber ?? "N/A"
    }
    
    private var bundleID: String {
        Bundle.main.bundleIdentifier ?? "N/A"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("App Info")) {
                    InfoLabel(title: "OpCo",
                              value: Environment.shared.opco.rawValue)
                    InfoLabel(title: "Tier",
                              value: Environment.shared.environmentName.rawValue)
                    InfoLabel(title: "Version",
                              value: versionString)
                    InfoLabel(title: "Bundle ID",
                              value: bundleID)
                }
                
                Section(header: Text("Azure URL"),
                        footer: Text("Relaunch the app for project URL changes to take affect.").padding(.bottom)) {
                    InfoLabel(title: "Base URL",
                              value: "https://\(Environment.shared.baseUrl)")
                    Picker(selection: $selectedProjectURL, label: Text("Project URL Suffix").fontWeight(.medium)) {
                        ForEach(ProjectURLSuffix.allCases, id: \.self) { value in
                            Text(value.rawValue).tag(value.rawValue)
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                }
                
                Section(header: Text("Other URLs"),
                        footer: Text("Note: This menu is only available at the TEST and STAGE tier.").padding(.bottom)) {
                    InfoLabel(title: "Associated Domaine",
                              value: Environment.shared.associatedDomain)
                    InfoLabel(title: "Account URL",
                              value: Environment.shared.myAccountUrl)
                    InfoLabel(title: "Sharepoint URL",
                              value: Environment.shared.sharepointBaseURL)
                    InfoLabel(title: "oAuth URL",
                              value: Environment.shared.oAuthEndpoint)
                    InfoLabel(title: "Payment URL",
                              value: Environment.shared.paymentusUrl)
                }
            }
            .navigationTitle("Debug Menu")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
            }
        }
    }
}

@available(iOS 14, *)
struct DebugMenu_Previews: PreviewProvider {
    static var previews: some View {
        DebugMenu()
    }
}