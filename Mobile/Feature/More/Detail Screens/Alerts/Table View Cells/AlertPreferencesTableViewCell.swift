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
    
    @IBOutlet weak var pickerButton: UIButton!
    @IBOutlet private weak var separatorView: UIView!
    
    @IBOutlet weak var checkbox: Checkbox!
    @IBOutlet weak var textField: FloatLabelTextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        nameLabel.isAccessibilityElement = false
        nameLabel.textColor = .deepGray
        nameLabel.font = SystemFont.regular.of(textStyle: .callout)
        pickerButton.setTitleColor(.actionBlue, for: .normal)
        pickerButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .subheadline)
        detailLabel.textColor = .deepGray
        detailLabel.font = SystemFont.regular.of(textStyle: .footnote)
        contentView.backgroundColor = .softGray
    }
    
    func configure(withPreferenceOption option: AlertPreferencesViewModel.AlertPreferencesOptions,
                   pickerButtonText: Driver<String>? = nil,
                   textFieldOptions: AlertPreferencesViewModel.AlertPrefTextFieldOptions? = nil,
                   isLastItem: Bool) {
        nameLabel.text = option.titleText
        detailLabel.text = option.detailText
        checkbox.accessibilityLabel = option.titleText
        
        pickerButtonText?
            .drive(onNext: { [weak self] buttonText in
                UIView.performWithoutAnimation { // Prevents ugly setTitle animation
                    self?.pickerButton.setTitle("Remind me \(buttonText)", for: .normal)
                    self?.pickerButton.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)
        
        pickerButton.isHidden = pickerButtonText == nil
        separatorView.isHidden = isLastItem
        textField.isHidden = textFieldOptions == nil
        
        if let textFieldOptions = textFieldOptions {
            textFieldOptions.text?.bind(to: textField.textField.rx.text).disposed(by: disposeBag)
            textField.placeholder = textFieldOptions.placeholder
            textField.accessibilityLabel = textFieldOptions.placeholder
            if textFieldOptions.isNumeric {
                textField.textField.keyboardType = .numberPad
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
}
