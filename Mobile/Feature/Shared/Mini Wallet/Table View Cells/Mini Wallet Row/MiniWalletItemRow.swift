//
//  WalletItemRow.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/25/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class MiniWalletItemRow: UITableViewCell {
    @IBOutlet weak var checkmarkImageView: UIImageView!
    @IBOutlet weak var paymentTypeImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    var isEnabled = true {
        didSet {
            if isEnabled {
                checkmarkImageView.alpha = 1.0
                paymentTypeImageView.alpha = 1.0
                titleLabel.alpha = 1.0
                subtitleLabel.alpha = 1.0
                
                selectionStyle = .default
            } else {
                checkmarkImageView.alpha = 0.4
                paymentTypeImageView.alpha = 0.4
                titleLabel.alpha = 0.4
                subtitleLabel.alpha = 0.4
                
                selectionStyle = .none
            }
        }
    }
    
    
    // MARK: - View Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        style()
    }
    
    // MARK: - Helper
    
    private func style() {
        titleLabel.textColor = .deepGray
        titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        subtitleLabel.textColor = .middleGray
        subtitleLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        // Cell Selection Color
        let backgroundView = UIView()
        backgroundView.backgroundColor = .softGray
        selectedBackgroundView = backgroundView
    }
    
    
    func configure(with walletItem: WalletItem,
                   isCreditCardDisabled: Bool,
                   isBankAccountDisabled: Bool,
                   indexPath: IndexPath,
                   selectedIndexPath: IndexPath?) {

        if !walletItem.isExpired && walletItem.bankOrCard == .card && !isCreditCardDisabled {
            // Card
            isEnabled = true
        } else if !walletItem.isExpired && walletItem.bankOrCard == .bank && !isBankAccountDisabled {
            // Bank
            isEnabled = true
        } else {
            // Enabled
            isEnabled = false
        }
                
        // Checkmark
        if let selectedIndexPath = selectedIndexPath, indexPath == selectedIndexPath {
            checkmarkImageView.isHidden = false
            checkmarkImageView.accessibilityLabel = NSLocalizedString("Selected", comment: "")
        } else {
            checkmarkImageView.isHidden = true
        }
        checkmarkImageView.isAccessibilityElement = false
        
        paymentTypeImageView.image = walletItem.paymentMethodType.imageMini
        titleLabel.text = "**** \(walletItem.maskedWalletItemAccountNumber ?? "")"
        subtitleLabel.text = walletItem.nickName
        
        // Accessibility
        self.accessibilityLabel = "\(checkmarkImageView.accessibilityLabel ?? ""), \(paymentTypeImageView.accessibilityLabel ?? ""), \(titleLabel.accessibilityLabel ?? ""), \(subtitleLabel.accessibilityLabel ?? "")"
    }
}
