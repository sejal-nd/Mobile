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
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var subLabel: UILabel!
    @IBOutlet weak var addRemoveButton: UIButton!
    @IBOutlet weak var gripImageView: UIImageView!
    
    var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cardView.layer.cornerRadius = 10
        cardView.addShadow(color: .black, opacity: 0, offset: CGSize(width: 0, height: 1), radius: 3)
    }
    
    func configure(withTitle title: String, canReorder: Bool, isAlwaysAvailable: Bool) {
        nameLabel.text = title
        subLabel.isHidden = isAlwaysAvailable
        gripImageView.isHidden = !canReorder
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
}
