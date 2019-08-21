//
//  AlertPreferencesTableViewCell.swift
//  Mobile
//
//  Created by Samuel Francis on 9/26/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class AlertPreferencesTableViewCell: UITableViewCell {
    
    var disposeBag = DisposeBag()
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    
    @IBOutlet private weak var pickerButtonStack: UIStackView!
    @IBOutlet private weak var pickerLabel: UILabel!
    @IBOutlet weak var pickerButton: UIButton!
    @IBOutlet private weak var separatorView: UIView!
    
    @IBOutlet weak var toggle: Switch!

    override func awakeFromNib() {
        super.awakeFromNib()
        nameLabel.isAccessibilityElement = false
        nameLabel.textColor = .blackText
        nameLabel.font = SystemFont.regular.of(textStyle: .title1)
        pickerLabel.textColor = .deepGray
        pickerLabel.font = SystemFont.regular.of(textStyle: .headline)
        pickerLabel.text = NSLocalizedString("Remind me", comment: "")
        pickerButton.setTitleColor(.actionBlue, for: .normal)
        pickerButton.titleLabel?.font = SystemFont.regular.of(textStyle: .headline)
        detailLabel.textColor = .deepGray
        detailLabel.font = SystemFont.regular.of(textStyle: .footnote)
        contentView.backgroundColor = .softGray
    }
    
    func configure(withPreferenceOption option: AlertPreferencesViewModel.AlertPreferencesOptions,
                   pickerButtonText: Driver<String>? = nil,
                   isLastItem: Bool) {
        nameLabel.text = option.titleText
        detailLabel.text = option.detailText
        toggle.accessibilityLabel = option.titleText
        
        pickerButtonText?
            .drive(onNext: { [weak self] buttonText in
                UIView.performWithoutAnimation { // Prevents ugly setTitle animation
                    self?.pickerButton.setTitle(buttonText, for: .normal)
                    self?.pickerButton.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)
        
        
        pickerButtonStack.isHidden = pickerButtonText == nil
        separatorView.isHidden = isLastItem
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
}
