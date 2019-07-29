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
    @IBOutlet weak var bottomButton: ButtonControl!
    @IBOutlet private weak var bottomButtonLabel: UILabel!
    
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
        
        detailLabel.textColor = .deepGray
        detailLabel.font = OpenSans.regular.of(textStyle: .footnote)
        
        bottomButtonLabel.textColor = .actionBlue
        bottomButtonLabel.font = OpenSans.semibold.of(textStyle: .title1)
    }
    
    func bindViewModel() {
        headerLabel.attributedText = viewModel.headerText
        detailLabel.text = viewModel.detailText
        bottomButtonLabel.text = viewModel.buttonText
        bottomButton.accessibilityLabel = viewModel.buttonText
        bottomButton.addTarget(self, action: #selector(openUrl), for: .touchUpInside)
    }
    
    @objc private func openUrl() {
        if viewModel.isActive {
            GoogleAnalytics.log(event: .prePaidEnrolled)
        } else {
            GoogleAnalytics.log(event: .prePaidPending)
        }
        
        UIApplication.shared.openUrlIfCan(viewModel.buttonUrl)
    }
}
