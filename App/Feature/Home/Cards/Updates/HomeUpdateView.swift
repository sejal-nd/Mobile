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
            button.layer.borderColor = UIColor.accentGray.cgColor
            button.layer.borderWidth = 1
        }
    }
    
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = .blackText
            titleLabel.font = OpenSans.semibold.of(textStyle: .callout)
        }
    }
    
    @IBOutlet private weak var descriptionLabel: UILabel! {
        didSet {
            descriptionLabel.textColor = .middleGray
            descriptionLabel.font = OpenSans.regular.of(textStyle: .caption1)
        }
    }
    
    static func create(withUpdate update: Alert) -> HomeUpdateView {
        let view = Bundle.main.loadViewFromNib() as HomeUpdateView
        view.configure(withUpdate: update)
        return view
    }
    
    func configure(withUpdate update: Alert) {
        titleLabel.text = update.title
        descriptionLabel.text = update.message
        button.accessibilityLabel = String(format: "%@, %@", update.title, update.message)
    }
}
