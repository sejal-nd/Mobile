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
    @AppStorage("selectedProjectTier") private var selectedProjectTier: ProjectTier = .stage
    @AppStorage("selectedProjectURL") private var selectedProjectURL: ProjectURLSuffix = .none
    
    @State private var isShowingPKCEFlow = false
    
    let dismiss: () -> Void
    
    private var versionString: String {
        Bundle.main.versionNumber ?? "N/A"
    }
    
    private var buildNumber: String {
        Bundle.main.buildNumber ?? "N/A"
    }
    
    private var bundleID: String {
        Bundle.main.bundleIdentifier ?? "N/A"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("App Info")) {
                    InfoLabel(title: "OpCo",
                              value: Configuration.shared.opco.rawValue)
                    InfoLabel(title: "Tier",
                              value: Configuration.shared.environmentName.rawValue)
                    InfoLabel(title: "Version",
                              value: "\(versionString)(\(buildNumber))")
                    InfoLabel(title: "Bundle ID",
                              value: bundleID)
                }
                
                Section(header: Text("Project Settings"),
                        footer: Text("Relaunch the app for changes to take affect.").padding(.bottom)) {
                    InfoLabel(title: "Azure Base URL",
                              value: "https://\(Configuration.shared.baseUrl)")
                    Picker(selection: $selectedProjectTier, label: Text("Project Tier").fontWeight(.medium)) {
                        ForEach(ProjectTier.allCases, id: \.self) { value in
                            Text(value.rawValue).tag(value.rawValue)
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                    Picker(selection: $selectedProjectURL, label: Text("Project Environment").fontWeight(.medium)) {
                        ForEach(ProjectURLSuffix.allCases, id: \.self) { value in
                            Text(value.rawValue).tag(value.rawValue)
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                    Button("Save & Restart App", action: restartApp)
                        .foregroundColor(.green)
                }
                
                Section(header: Text("Other URLs"),
                        footer: Text("Note: This menu is only available at the BETA tier.").padding(.bottom)) {
                    InfoLabel(title: "Associated Domain",
                              value: Configuration.shared.associatedDomain)
                    InfoLabel(title: "Account URL",
                              value: Configuration.shared.myAccountUrl)
                    InfoLabel(title: "oAuth URL",
                              value: Configuration.shared.oAuthEndpoint)
                    InfoLabel(title: "Payment URL",
                              value: Configuration.shared.paymentusUrl)
                }
                
                Section(header: Text("EU Auth (Temp)")) {
                    Button("Launch PKCE Sign In", action: launchPKCESignIn)
                }
                .sheet(isPresented: $isShowingPKCEFlow) {
                    SafariContainerView(url: URL(string: "https://google.com")!)
                }
            }
            .navigationTitle("Debug Menu")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: dismiss) {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset", action: reset)
                        .foregroundColor(.orange)
                }
            }
            .onChange(of: selectedProjectTier) { value in
                sendMessageToWatchSession(projectTier: value, projectURLSuffix: selectedProjectURL)
            }
            .onChange(of: selectedProjectURL) { value in
                sendMessageToWatchSession(projectTier: selectedProjectTier, projectURLSuffix: value)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func reset() {
        selectedProjectTier = .stage
        selectedProjectURL = .none

        sendMessageToWatchSession(projectTier: selectedProjectTier, projectURLSuffix: selectedProjectURL)
    }
    
    private func restartApp() {
        exit(0)
    }
    
    private func launchPKCESignIn() {
        isShowingPKCEFlow.toggle()
    }
    
    private func sendMessageToWatchSession(projectTier: ProjectTier, projectURLSuffix: ProjectURLSuffix) {
        try? WatchSessionController.shared.updateApplicationContext(applicationContext:
                                                                        [WatchSessionController.Key.projectTier : projectTier.rawValue,
                                                                         WatchSessionController.Key.projectURLSuffix : projectURLSuffix.rawValue]
        )
    }
}

@available(iOS 14, *)
struct DebugMenu_Previews: PreviewProvider {
    static var previews: some View {
        DebugMenu(dismiss: { })
    }
}
