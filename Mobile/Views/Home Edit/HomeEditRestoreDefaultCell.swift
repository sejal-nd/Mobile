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
    @IBOutlet weak var button: UIButton!
    
    var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        button.setTitleColor(.white, for: .normal)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
}
