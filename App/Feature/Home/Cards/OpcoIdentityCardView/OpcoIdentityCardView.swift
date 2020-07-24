//
//  OpcoIdentityCardView.swift
//  BGE
//
//  Created by Majumdar, Amit on 22/07/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import UIKit

final class OpcoIdentityCardView: UIView {
    // MARK: - IBOutlets
    
    /// `UILabel` instance to show nickname
    @IBOutlet private weak var accountNickname: UILabel!
    
    /// `UIIMageView` instance to show logo for selectetd opco
    @IBOutlet private weak var logo: UIImageView!
    
    static func create() -> OpcoIdentityCardView {
        let view = Bundle.main.loadViewFromNib() as OpcoIdentityCardView
        view.styleViews()
        return view
    }
    
    /// This function styles view
    private func styleViews() {
        backgroundColor = .primaryColor
        accountNickname.textColor = .white
        accountNickname.font = SystemFont.semibold.of(textStyle: .subheadline)
        accountNickname.isAccessibilityElement = true
        accessibilityElements = [accountNickname, logo] as [UIView]
    }
    
    /// This method is used to configure `OpcoIdentityCardView`
    /// - Parameters:
    ///   - nickname: `nickname`
    ///   - opco: `opco`
    ///   - hasMultipleAccounts: `flag` to identify whether the account has multiple accounts tagged to it
    func configure(nickname: String, opco: OpCo, hasMultipleAccounts: Bool) {
        // Account has a nickname and has multiple accounts attached to it
        if !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasMultipleAccounts {
            accountNickname.text = nickname
            setOpcoLogo(opco: opco)
        } else if !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !hasMultipleAccounts {
            // Account has a nickname and has a single account attached to it
            accountNickname.text = nickname
        } else if nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasMultipleAccounts {
            // Account doesn't have a nickname and has multiple accounts attached to it
            setOpcoLogo(opco: opco)
        } else {
            // Account doesn't have a nickname and has a single account
        }
    }
    
    /// This function sets opco logo
    /// - Parameter opco: `opco`
    private func setOpcoLogo(opco: OpCo) {
        switch opco {
        case .ace:
            logo.image = #imageLiteral(resourceName: "img_logo_white_ace")
        case .delmarva:
            logo.image = #imageLiteral(resourceName: "img_logo_white_dpl")
        case .pepco:
            logo.image = #imageLiteral(resourceName: "img_logo_white_pep")
        default:
            break
        }
    }
}
