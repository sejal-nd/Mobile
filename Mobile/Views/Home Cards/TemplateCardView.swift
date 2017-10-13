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
import SafariServices

class TemplateCardView: UIView {
    
    var bag = DisposeBag()
    @IBOutlet weak var clippingView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var callToActionButton: UIButton!
    
    @IBOutlet weak var errorStack: UIStackView!
    @IBOutlet weak var errorLabel: UILabel!
    
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
        titleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        bodyLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        bodyLabel.setLineHeight(lineHeight: 18)
        callToActionButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .title1)
        
        errorLabel.font = OpenSans.regular.of(textStyle: .title1)
        errorLabel.setLineHeight(lineHeight: 26)
        errorLabel.textAlignment = .center
    }
    
    private func bindViewModel() {
        //grab all the content
        viewModel.templateImage.drive(imageView.rx.image).disposed(by: bag)
        viewModel.titleString.drive(titleLabel.rx.text).disposed(by: bag)
        viewModel.bodyString.drive(bodyLabel.rx.text).disposed(by: bag)
        viewModel.ctaString.drive(callToActionButton.rx.title()).disposed(by: bag)

        //show error state if an error is received
        viewModel.shouldShowErrorState.drive(clippingView.rx.isHidden).disposed(by: bag)
        viewModel.shouldShowErrorState.not().drive(errorStack.rx.isHidden).disposed(by: bag)
        //viewModel.errorLabelText.drive(errorLabel.rx.text).disposed(by: bag)
        viewModel.errorLabelText.drive(onNext: { [weak self] errorText in
            self?.errorLabel.text = errorText
            let localizedAccessibililtyText = NSLocalizedString("%@ OverView, %@", comment: "")
            self?.errorLabel.accessibilityLabel = String(format: localizedAccessibililtyText, Environment.sharedInstance.opco.displayString, errorText ?? "")
        }).disposed(by: bag)
    }
    
    private(set) lazy var callToActionViewController: Driver<UIViewController> = self.callToActionButton.rx.tap.asDriver()
        .do(onNext: { [weak self] in
            guard let `self` = self else { return }
            Analytics().logScreenView(AnalyticsPageView.HomePromoCard.rawValue, dimensionIndex: Dimensions.DIMENSION_LINK.rawValue, dimensionValue: String(describing: self.viewModel.ctaUrl))
        })
        .withLatestFrom(self.viewModel.ctaUrl)
        .map(SFSafariViewController.init)
    
}
