//
//  HomeDiscoverCardView.swift
//  EUMobile
//
//  Created by Cody Dillon on 12/13/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class HomeDiscoverCardView: UIView {

    @IBOutlet weak var contentStack: UIStackView!
    @IBOutlet weak var clippingView: UIView!
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!

    @IBOutlet weak var row1: UIView!
    @IBOutlet weak var row2: UIView!
    @IBOutlet weak var row3: UIView!
    @IBOutlet weak var row4: UIView!
    @IBOutlet weak var row5: UIView!
    @IBOutlet weak var row6: UIView!
    @IBOutlet weak var row7: UIView!
    @IBOutlet weak var row8: UIView!
    @IBOutlet weak var row9: UIView!
    @IBOutlet weak var row10: UIView!

    static func create() -> HomeDiscoverCardView {
        let view = Bundle.main.loadViewFromNib() as HomeDiscoverCardView
        view.styleViews()
//        view.viewModel = viewModel
        return view
    }

    func styleViews() {
        layer.cornerRadius = 10
        layer.borderColor = UIColor.accentGray.cgColor
        layer.borderWidth = 1
            clippingView.layer.cornerRadius = 10
//        clippingView.heightAnchor.constraint(equalToConstant: 164.0).isActive = true
    }
}
