//
//  SmartThermostatDeviceCell.swift
//  Mobile
//
//  Created by Sam Francis on 11/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxSwiftExt

class SmartThermostatDeviceCell: UITableViewCell {
    
    var disposeBag = DisposeBag()
    
    let checkImageView = UIImageView(image: #imageLiteral(resourceName: "icon_check")).usingAutoLayout()
    let nameLabel = UILabel().usingAutoLayout()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        selectionStyle = .none
        
        nameLabel.font = SystemFont.medium.of(textStyle: .headline)
        nameLabel.textColor = .blackText
        nameLabel.numberOfLines = 0
        
        checkImageView.setContentHuggingPriority(.required, for: .horizontal)
        
        let stackView = UIStackView(arrangedSubviews: [checkImageView, nameLabel]).usingAutoLayout()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 5
        
        let separator = UIView().usingAutoLayout()
        contentView.addSubview(separator)
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        separator.backgroundColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1)
        
        contentView.addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 21).isActive = true
        stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20).isActive = true
        stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 17).isActive = true
        stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -17).isActive = true
        
    }
    
    func configure(withDevice device: SmartThermostatDevice, isChecked: Driver<Bool>) {
        isChecked.not().drive(checkImageView.rx.isHidden).disposed(by: disposeBag)
        
        isChecked
            .map { isChecked in
                if isChecked {
                    let localizedText = NSLocalizedString("Selected: %@", comment: "")
                    return String(format: localizedText, device.name)
                } else {
                    return device.name
                }
            }
            .drive(rx.accessibilityLabel)
            .disposed(by: disposeBag)
        
        nameLabel.text = device.name
    }
    
    override func prepareForReuse() {
        disposeBag = DisposeBag()
    }
}
