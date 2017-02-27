//
//  TableViewCell.swift
//  Mobile
//
//  Created by Marc Shilling on 2/27/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

class TableViewCell: UITableViewCell {

    @IBOutlet private weak var innerContentView: UIView!
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var caretAccessory: UIImageView!
    @IBOutlet private weak var switchAccessory: Switch!
    
    private var highlightDisabled = false
    
    let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.backgroundColor = .clear
        
        innerContentView.layer.shadowColor = UIColor.black.cgColor
        innerContentView.layer.shadowOpacity = 0.2
        innerContentView.layer.shadowRadius = 6
        innerContentView.layer.shadowOffset = CGSize(width: 0, height: 0)
        innerContentView.layer.masksToBounds = false
        
        label.textColor = .darkJungleGreen
    }
    
    func configureWith(label: String, carat: Bool) {
        self.label.text = label
        caretAccessory.isHidden = !carat
    }
    
    func configureWith(label: String, switchOn: Bool, switchObserver: @escaping (Bool) -> Void) {
        self.label.text = label
        
        highlightDisabled = true
        
        switchAccessory.isHidden = false
        switchAccessory.isOn = switchOn
        switchAccessory.rx.isOn.asObservable().bindNext(switchObserver).addDisposableTo(disposeBag)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        // disable selection style
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if !highlightDisabled {
            if highlighted {
                innerContentView.backgroundColor = .secondaryButtonBackgroundHightlightColor
            } else {
                innerContentView.backgroundColor = .white
            }
        }
    }
    
}
