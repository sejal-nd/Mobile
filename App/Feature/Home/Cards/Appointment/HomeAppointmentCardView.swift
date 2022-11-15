//
//  HomeAppointmentCardView.swift
//  Mobile
//
//  Created by Sam Francis on 10/10/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class HomeAppointmentCardView: UIView {
    
    @IBOutlet private weak var clippingView: UIView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var topTextView: ZeroInsetDataDetectorTextView!
    @IBOutlet private weak var apologyLabelContainer: UIView!
    @IBOutlet private weak var apologyLabel: UILabel!
    @IBOutlet weak var bottomButton: ButtonControl!
    @IBOutlet private weak var bottomButtonLabel: UILabel!
    
    var disposeBag = DisposeBag()
    
    private var viewModel: HomeAppointmentCardViewModel! {
        didSet {
            disposeBag = DisposeBag() // Clear all pre-existing bindings
            bindViewModel()
        }
    }
    
    static func create(withViewModel viewModel: HomeAppointmentCardViewModel) -> HomeAppointmentCardView {
        let view = Bundle.main.loadViewFromNib() as HomeAppointmentCardView
        view.styleViews()
        view.viewModel = viewModel
        return view
    }
    
    func styleViews() {
        layer.cornerRadius = 10
        layer.borderColor = UIColor.accentGray.cgColor
        layer.borderWidth = 1
        clippingView.layer.cornerRadius = 10
        
        topTextView.textColor = .blackText
        topTextView.tintColor = .primaryBlue // Color of the phone numbers
        topTextView.font = SystemFont.regular.of(textStyle: .headline)
        
        apologyLabel.textColor = .neutralDark
        apologyLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        bottomButtonLabel.textColor = .primaryBlue
        bottomButtonLabel.font = SystemFont.semibold.of(textStyle: .headline)
    }
    
    func bindViewModel() {
        viewModel.showApologyText.not()
            .drive(apologyLabelContainer.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.icon
            .drive(imageView.rx.image)
            .disposed(by: disposeBag)
        
        viewModel.topText
            .drive(onNext: { [weak self] topText in
                self?.topTextView.attributedText = topText
                self?.topTextView.accessibilityValue = topText.string.replacingOccurrences(of: "-", with: "and")
            })
            .disposed(by: disposeBag)
        
        viewModel.bottomButtonText
            .drive(bottomButtonLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.bottomButtonText
            .drive(bottomButton.rx.accessibilityLabel)
            .disposed(by: disposeBag)
    }
}
