//
//  CheckBoxView.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 5/19/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import SwiftUI

extension Color {
    static var primaryDarkBlue: Color {
        return Color("primaryBlue")
    }
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
                        .foregroundColor(.primaryDarkBlue)
                        .font(Font.headline.weight(.semibold))
                    Text(text)
                        .foregroundColor(.neutralDark)
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
