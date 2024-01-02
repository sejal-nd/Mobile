//
//  ContactView.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 11/30/23.
//  Copyright © 2023 Exelon Corporation. All rights reserved.
//

import SwiftUI
import EUDesignSystem

struct ContactView: View {
    @StateObject private var viewModel = ViewModel()
    
    @State private var isContactFormPresented = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Emergency Section
                if let phoneNumber = viewModel.emergencyURL {
                    ContactHeaderView(title: "Emergency",
                                      detail: viewModel.emergencyDetail,
                                      buttonTitle: phoneNumber) {
                        viewModel.open(.phone(phoneNumber))
                    }
                    .padding(.top, 8)
                } else {
                    ContactHeaderView(title: "Emergency",
                                      detail: viewModel.emergencyDetail)
                    .padding(.top, 8)
                }
                
                if let phoneNumber1 = viewModel.gasEmergencyURL1,
                   let phoneNumber2 = viewModel.gasEmergencyURL2 {
                    ContactRow(title: "Gas Emergency",
                               buttonTitle: phoneNumber1,
                               buttonTitleTwo: phoneNumber2) {
                        viewModel.open(.phone(phoneNumber1))
                    } buttonActionTwo: {
                        viewModel.open(.phone(phoneNumber2))
                    }
                } else if let phoneNumber = viewModel.gasEmergencyURL1 {
                    ContactRow(title: "Gas Emergency",
                               buttonTitle: phoneNumber) {
                        viewModel.open(.phone(phoneNumber))
                    }
                }
                
                
                if let phoneNumber1 = viewModel.electricalEmergencyURL1,
                   let phoneNumber2 = viewModel.electricalEmergencyURL2 {
                    ContactRow(title: "Downed Power Lines",
                               buttonTitle: phoneNumber1,
                               buttonTitleTwo: phoneNumber2,
                               isLastRow: true) {
                        viewModel.open(.phone(phoneNumber1))
                    } buttonActionTwo: {
                        viewModel.open(.phone(phoneNumber2))
                    }
                } else if let phoneNumber = viewModel.electricalEmergencyURL1 {
                    ContactRow(title: "Downed Power Lines",
                               buttonTitle: phoneNumber,
                               isLastRow: true) {
                        viewModel.open(.phone(phoneNumber))
                    }
                }
            }
            
            // Section Spacer
            Color.neutralLightest
                .frame(height: 20)
            
            // Contact Us Online Section
            ContactHeaderView(title: "Contact Us Online",
                              detail: "Use our online form to contact us with general questions.  This form is for non-emergency purposes only.",
                              buttonTitle: "Submit Form") {
                isContactFormPresented.toggle()
            }
            
            Color.neutralLightest
                .frame(height: 20)
            
            // Customer Service Section
            ContactHeaderView(title: "Customer Service",
                              accessoryLabel: viewModel.customerServiceAccessoryText)
            
            if let phoneNumber = viewModel.residentialURL {
                ContactRow(title: viewModel.residentialTitle,
                           buttonTitle: phoneNumber) {
                    viewModel.open(.phone(phoneNumber))
                }
            }
            
            if let phoneNumber = viewModel.businessURL {
                ContactRow(title: viewModel.businessTitle,
                           buttonTitle: phoneNumber) {
                    viewModel.open(.phone(phoneNumber))
                }
            }
            
            if let phoneNumber = viewModel.alternativeURL {
                ContactRow(title: viewModel.alternativeTitle,
                           buttonTitle: phoneNumber,
                           isLastRow: true) {
                    viewModel.open(.phone(phoneNumber))
                }
            }
            
            // MARK: Social Media Icons
            LazyVGrid(columns: viewModel.columns, spacing: 20) {
                ForEach(viewModel.socialMediaLinks, id: \.self) { socialMediaLink in
                    Button {
                        viewModel.open(.socialMedia(socialMediaLink))
                    } label: {
                        Image(socialMediaLink.imageName)
                    }
                    .padding(.vertical)
                }
            }
            .padding(.top)
        }
        .navigationTitle("Contact Us")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible)
        .safariSheet(url: viewModel.formURL, isPresented: $isContactFormPresented)
        .logScreenView(.contactUs)
        
    }
}

struct ContactView_Previews: PreviewProvider {
    static var previews: some View {
        ContactView()
    }
}


// MARK: Contact Header View

private struct ContactHeaderView: View {
    let title: String
    var detail: String? = nil
    var accessoryLabel: String? = nil
    var buttonTitle: String? = nil
    var buttonAction: (() -> Void)? = nil
    
    var body: some View {
        Group {
            HStack {
                Text(title)
                    .scaledFont(style: .headline, weight: .semibold)
                    .foregroundStyle(.neutralDarker)
                
                Spacer()
                
                if let accessoryLabel {
                    Text(accessoryLabel)
                        .foregroundStyle(.neutralDark)
                        .scaledFont(style: .callout)
                }
                
                if let buttonTitle,
                   let buttonAction {
                    Button(buttonTitle) {
                        buttonAction()
                    }
                    .scaledFont(style: .callout, weight: .medium)
                    .foregroundStyle(.actionBrand)
                }
            }
            .padding([.horizontal, .top])
            .padding(.top, 4)
            
            Divider()
            
            if let detail,
               let markdownDetail = try? AttributedString(markdown: detail) {
                Text(markdownDetail)
                    .scaledFont(style: .caption)
                    .foregroundStyle(.neutralDark)
                    .padding([.horizontal, .bottom])
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: Contact Row

private struct ContactRow: View {
    let title: String
    let buttonTitle: String
    var buttonTitleTwo: String? = nil
    var isLastRow = false
    let buttonAction: () -> Void
    var buttonActionTwo: (() -> Void)? = nil
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                Text(title)
                    .foregroundStyle(.neutralDark)
                Spacer()
                
                // Links
                VStack(spacing: 20) {
                    Button(buttonTitle, action: buttonAction)
                        .scaledFont(style: .callout, weight: .medium)
                        .foregroundStyle(.actionBrand)
                    
                    if let buttonTitleTwo {
                        Button(buttonTitleTwo) {
                            buttonActionTwo?()
                        }
                        .scaledFont(style: .callout, weight: .medium)
                        .foregroundStyle(.actionBrand)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            if !isLastRow {
                Divider()
                    .padding(.leading)
            }
        }
    }
}
