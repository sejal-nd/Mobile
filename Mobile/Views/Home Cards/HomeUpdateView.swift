//
//  HomeUpdateView.swift
//  Mobile
//
//  Created by Samuel Francis on 8/17/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import UIKit

class HomeUpdateView: UIView {
    
    let disposeBag = DisposeBag()

    @IBOutlet weak var button: ButtonControl! {
        didSet {
            button.layer.cornerRadius = 10
            button.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        }
    }
    
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = .blackText
            titleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        }
    }
    
    @IBOutlet private weak var descriptionLabel: UILabel! {
        didSet {
            descriptionLabel.textColor = .middleGray
            descriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        }
    }
    
    static func create(withUpdate update: OpcoUpdate) -> HomeUpdateView {
        let view = Bundle.main.loadViewFromNib() as HomeUpdateView
        view.titleLabel.text = update.title
        view.descriptionLabel.text = update.message
        return view
    }
    
}
