//
//  WalletItemRow.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/25/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class MiniWalletItemRow: UITableViewCell {
    enum CellState {
        case expanded
        case collapsed
    }
    
    @IBOutlet weak var checkmarkImageView: UIImageView!
    @IBOutlet weak var paymentTypeImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    
    // MARK: - View Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        style()
    }
    
    
    // MARK: - Helper
    
    private func style() {
        titleLabel.textColor = .blackText
        titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        subtitleLabel.textColor = .middleGray
        subtitleLabel.font = SystemFont.regular.of(textStyle: .footnote)
    }
    
    func configure(withWalletItem walletItem: WalletItem,
                   indexPath: IndexPath,
                   selectedIndexPath: IndexPath?) {
        // Checkmark
        if let selectedIndexPath = selectedIndexPath, indexPath == selectedIndexPath {
            checkmarkImageView.isHidden = false
            checkmarkImageView.accessibilityLabel = NSLocalizedString("Selected", comment: "")
        } else {
            checkmarkImageView.isHidden = true
        }
        checkmarkImageView.isAccessibilityElement = false
        
        paymentTypeImageView.image = walletItem.paymentMethodType.imageMini
        titleLabel.text = walletItem.maskedWalletItemAccountNumber
        subtitleLabel.text = walletItem.nickName
        
        // Accessibility
        self.accessibilityLabel = "\(checkmarkImageView.accessibilityLabel ?? ""), \(paymentTypeImageView.accessibilityLabel ?? ""), \(titleLabel.accessibilityLabel ?? ""), \(subtitleLabel.accessibilityLabel ?? "")"
    }
}
