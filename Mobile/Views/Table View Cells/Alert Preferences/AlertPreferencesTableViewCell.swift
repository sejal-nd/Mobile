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
    @IBOutlet private weak var pickerButton: UIButton!
    
    @IBOutlet private weak var toggle: Switch!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        nameLabel.textColor = .blackText
        nameLabel.font = SystemFont.regular.of(textStyle: .title1)
        pickerLabel.textColor = .deepGray
        pickerLabel.font = SystemFont.regular.of(textStyle: .headline)
        pickerLabel.text = NSLocalizedString("Remind me", comment: "")
        pickerButton.setTitleColor(.actionBlue, for: .normal)
        pickerButton.titleLabel?.font = SystemFont.regular.of(textStyle: .headline)
        detailLabel.textColor = .deepGray
        detailLabel.font = SystemFont.regular.of(textStyle: .footnote)
    }
    
    func configure(withPreferenceOption option: AlertPreferencesViewModel.AlertPreferencesOptions,
                   toggleValue: Variable<Bool>,
                   pickerButtonText: Driver<String>? = nil,
                   onPickerButtonPress: (() -> ())? = nil) {
        nameLabel.text = option.titleText
        detailLabel.text = option.detailText
        
        toggle.rx.isOn.asDriver().distinctUntilChanged().drive(toggleValue).disposed(by: disposeBag)
        toggleValue.asDriver().distinctUntilChanged().drive(toggle.rx.isOn).disposed(by: disposeBag)
        
        pickerButtonText?
            .drive(onNext: { [weak self] buttonText in
                UIView.performWithoutAnimation { // Prevents ugly setTitle animation
                    self?.pickerButton.setTitle(buttonText, for: .normal)
                    self?.pickerButton.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)
        
        if let onPickerButtonPress = onPickerButtonPress {
            pickerButtonStack.isHidden = false
            pickerButton.rx.tap.asDriver()
                .drive(onNext: onPickerButtonPress)
                .disposed(by: disposeBag)
        } else {
            pickerButtonStack.isHidden = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
}
