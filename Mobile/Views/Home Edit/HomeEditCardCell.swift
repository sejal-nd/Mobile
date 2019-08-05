//
//  HomeEditCardCell.swift
//  Mobile
//
//  Created by Samuel Francis on 6/14/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class HomeEditCardCell: UICollectionViewCell {
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var a11yView: UIView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var subLabel: UILabel!
    @IBOutlet private weak var addRemoveButton: UIButton!
    @IBOutlet weak var gripView: UIView!
    
    var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cardView.layer.cornerRadius = 10
        cardView.layer.borderColor = UIColor.accentGray.cgColor
        cardView.layer.borderWidth = 1.0
    }
    
    func configure(withCard card: HomeCard, isActive: Bool, addRemoveTapped: @escaping ()->()) {
        nameLabel.text = card.displayString
        nameLabel.textColor = .deepGray
        nameLabel.font = SystemFont.regular.of(textStyle: .callout)
        
        subLabel.textColor = .middleGray
        subLabel.font = SystemFont.regular.of(textStyle: .caption1)
        subLabel.isHidden = card.isAlwaysAvailable
        
        gripView.isHidden = !isActive
        addRemoveButton.setImage(isActive ? #imageLiteral(resourceName: "ic_remove"):#imageLiteral(resourceName: "ic_add"), for: .normal)
        addRemoveButton.isHidden = !card.isOptional
        addRemoveButton.rx.tap.asDriver()
            .throttle(0.25)
            .drive(onNext: addRemoveTapped)
            .disposed(by: disposeBag)
        
        a11yView.accessibilityLabel = card.displayString + (card.isAlwaysAvailable ? "" : NSLocalizedString(". May not be available for all accounts", comment: ""))
        addRemoveButton.accessibilityLabel = isActive ?
            String(format: NSLocalizedString("Remove %@", comment: ""), card.displayString) :
            String(format: NSLocalizedString("Add %@", comment: ""), card.displayString)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
}
