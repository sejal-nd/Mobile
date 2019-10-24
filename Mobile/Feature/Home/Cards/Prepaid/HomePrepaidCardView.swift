//
//  HomePrepaidCardView.swift
//  Mobile
//
//  Created by Samuel Francis on 4/8/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

final class HomePrepaidCardView: UIView {
    @IBOutlet private weak var clippingView: UIView!
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet weak var callToActionButton: UIButton!
    
    private var viewModel: HomePrepaidCardViewModel! {
        didSet {
            bindViewModel()
        }
    }
    
    static func create(withViewModel viewModel: HomePrepaidCardViewModel) -> HomePrepaidCardView {
        let view = Bundle.main.loadViewFromNib() as HomePrepaidCardView
        view.styleViews()
        view.viewModel = viewModel
        return view
    }
    
    func styleViews() {
        layer.cornerRadius = 10
        layer.borderColor = UIColor.accentGray.cgColor
        layer.borderWidth = 1
        clippingView.layer.cornerRadius = 10
        
        headerLabel.textColor = .deepGray
        headerLabel.font = OpenSans.regular.of(textStyle: .callout)
        
        detailLabel.textColor = .deepGray
        detailLabel.font = OpenSans.regular.of(textStyle: .caption1)
        
        callToActionButton.titleLabel?.font = OpenSans.semibold.of(textStyle: .headline)
    }
    
    func bindViewModel() {
        headerLabel.attributedText = viewModel.headerText
        detailLabel.text = viewModel.detailText
        UIView.performWithoutAnimation {
            callToActionButton.setTitle(viewModel.buttonText, for: .normal)
        }
    }
    @IBAction func callToActionPress(_ sender: Any) {
        if viewModel.isActive {
            GoogleAnalytics.log(event: .prePaidEnrolled)
        } else {
            GoogleAnalytics.log(event: .prePaidPending)
        }
        
        UIApplication.shared.openUrlIfCan(viewModel.buttonUrl)
    }
}
