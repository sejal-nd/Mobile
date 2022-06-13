//
//  CheckBoxView.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 5/19/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import SwiftUI

extension Color {
    @nonobjc static var actionBlue = Color(red: 0/255, green: 89/255, blue: 164/255)
    @nonobjc static var deepGray = Color(red: 74/255, green: 74/255, blue: 74/255)
}

struct CheckBoxView: View {
    @Binding var isSelected: Bool
    
    let text: String
    
    var didSelect: () -> ()
    
    var body: some View {
        HStack {
            Button(action: didSelectCheckbox) {
                HStack {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .foregroundColor(.actionBlue)
                        .font(Font.headline.weight(.semibold))
                    Text(text)
                        .foregroundColor(.deepGray)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }
    
    private func didSelectCheckbox() {
        isSelected = !isSelected
        didSelect()
    }
}

struct CheckBoxView_Previews: PreviewProvider {
    static var previews: some View {
        CheckBoxView(isSelected: .constant(true), text: "Hello World") {
            
        }
    }
}
