//
//  TabCollectionViewCell.swift
//  Mobile
//
//  Created by Samuel Francis on 5/3/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

fileprivate let minWidth: CGFloat = 80

class TabCollectionViewCell: UICollectionViewCell {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var highlightBar: UIView!
    @IBOutlet weak var titleLeadingConstraint: NSLayoutConstraint!
    
    var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        highlightBar.backgroundColor = .primaryColor
        styleDeselected()
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
    
    func configure(title: String, isSelected: Driver<Bool>) {
        titleLabel.text = title
        accessibilityLabel = title
        isSelected
            .distinctUntilChanged()
            .drive(onNext: { [weak self] isSelected in
                if isSelected {
                    self?.styleSelected()
                } else {
                    self?.styleDeselected()
                }
            })
            .disposed(by: disposeBag)
    }
    
    override var isHighlighted: Bool {
        didSet {
            contentView.backgroundColor = isHighlighted ? .softGray : .white
        }
    }
    
    private func styleSelected() {
        titleLabel.font = SystemFont.semibold.of(textStyle: .footnote)
        titleLabel.textColor = .actionBlue
        highlightBar.isHidden = false
    }
    
    private func styleDeselected() {
        titleLabel.font = SystemFont.regular.of(textStyle: .footnote)
        titleLabel.textColor = .middleGray
        highlightBar.isHidden = true
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        // return the widest necessary size (semibold title when selected)
        guard let labelWidth = titleLabel.text?
            .boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 0),
                          options: .usesLineFragmentOrigin,
                          attributes: [.font : SystemFont.semibold.of(textStyle: .footnote)],
                          context: nil).size.width else { return .zero }
        let computedWidth = (titleLeadingConstraint.constant + 2) * 2 + labelWidth
        let width = max(minWidth, computedWidth)
        
        return CGSize(width: width, height: 50)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
}
