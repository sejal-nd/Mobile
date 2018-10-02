//
//  UpdatesTableViewCell.swift
//  Mobile
//
//  Created by Marc Shilling on 11/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class UpdatesTableViewCell: UITableViewCell {
    
    var disposeBag = DisposeBag()
    
    @IBOutlet weak var innerContentView: ButtonControl!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        innerContentView.layer.cornerRadius = 10.0
        innerContentView.layer.masksToBounds = true
        
        addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 2.0)
        
        titleLabel.textColor = .blackText
        titleLabel.font = SystemFont.bold.of(textStyle: .headline)
        
        detailLabel.textColor = .deepGray
        detailLabel.font = SystemFont.regular.of(textStyle: .subheadline)
    }
    
    
    // MARK: - Cell Selection
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        if highlighted {
            innerContentView.backgroundColor = .softGray
        } else {
            innerContentView.backgroundColor = .white
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            innerContentView.backgroundColor = .softGray
        } else {
            innerContentView.backgroundColor = .white
        }
    }
    
    
    // MARK: - Configure
    
    public func configure(title: String, detail: String) {
        titleLabel.text = title
        detailLabel.text = detail
        
        innerContentView.accessibilityLabel = "\(title): \(detail)"
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
}
