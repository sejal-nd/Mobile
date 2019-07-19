//
//  AlertPreferencesLanguageCell.swift
//  Mobile
//
//  Created by Samuel Francis on 9/28/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class AlertPreferencesLanguageCell: UITableViewCell {
    
    var disposeBag = DisposeBag()

    @IBOutlet private weak var label: UILabel!
    @IBOutlet weak var englishRadioSelectControl: RadioSelectControl!
    @IBOutlet weak var spanishRadioSelectControl: RadioSelectControl!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        label.textColor = .blackText
        label.font = SystemFont.bold.of(textStyle: .subheadline)
        
        englishRadioSelectControl.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { GoogleAnalytics.log(event: .alertsEnglish) })
            .disposed(by: disposeBag)
        
        spanishRadioSelectControl.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { GoogleAnalytics.log(event: .alertsSpanish) })
            .disposed(by: disposeBag)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
}
