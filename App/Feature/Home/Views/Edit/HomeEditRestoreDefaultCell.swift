//
//  HomeEditRestoreDefaultCell.swift
//  Mobile
//
//  Created by Samuel Francis on 6/19/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class HomeEditRestoreDefaultCell: UICollectionViewCell {
    @IBOutlet private weak var button: UIButton!
    
    var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        button.setTitleColor(.actionBlue, for: .normal)
        button.setTitleColor(UIColor(red: 74/255, green: 74/255, blue: 74/255, alpha: 0.4), for: .disabled)
        button.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
    }
    
    func configure(isEnabled: Driver<Bool>, isReordering: Driver<Bool>, onTap: @escaping ()->()) {
        button.rx.tap.asDriver()
            .throttle(.milliseconds(250))
            .drive(onNext: onTap)
            .disposed(by: disposeBag)
        
        isEnabled.drive(button.rx.isEnabled).disposed(by: disposeBag)
        isReordering.not().drive(button.rx.isUserInteractionEnabled).disposed(by: disposeBag)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
}
