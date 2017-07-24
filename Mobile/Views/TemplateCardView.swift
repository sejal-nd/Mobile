//
//  TemplateCardView.swift
//  Mobile
//
//  Created by Dan Jorquera on 7/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxSwiftExt

class TemplateCardView: UIView {
    
    var bag = DisposeBag()
    @IBOutlet weak var clippingView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var callToActionButton: UIButton!
    
    @IBOutlet weak var errorStateView: UIView!
    
    private var callToActionLabel = ""
    
    private var viewModel: TemplateCardViewModel! {
        didSet {
            bag = DisposeBag() // Clear all pre-existing bindings
            bindViewModel()
        }
    }
    
    static func create(withViewModel viewModel: TemplateCardViewModel) -> TemplateCardView {
        let view = Bundle.main.loadViewFromNib() as TemplateCardView
        view.styleViews()
        view.viewModel = viewModel
        return view
    }
    
    private func styleViews() {
        layer.cornerRadius = 2
        addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        clippingView.layer.cornerRadius = 2
    }
    
    private func bindViewModel() {
        
        //grab all the content
        viewModel.templateImage.drive(imageView.rx.image).addDisposableTo(bag)
        viewModel.titleString.drive(titleLabel.rx.text).addDisposableTo(bag)
        viewModel.bodyString.drive(bodyLabel.rx.text).addDisposableTo(bag)
        viewModel.ctaString.drive(callToActionButton.rx.title()).addDisposableTo(bag)
        //TODO:
        //open URL from viewModel.ctaUrl
        
        //show error state if an error is received
        viewModel.shouldShowErrorState.drive(clippingView.rx.isHidden).addDisposableTo(bag)
        viewModel.shouldShowErrorState.not().drive(errorStateView.rx.isHidden).addDisposableTo(bag)
    }
    
}
