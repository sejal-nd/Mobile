//
//  HomeProjectedBillCardView.swift
//  Mobile
//
//  Created by Marc Shilling on 7/6/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

class HomeProjectedBillCardView: UIView {
    
    var disposeBag = DisposeBag()
    
    @IBOutlet private weak var clippingView: UIView!
    
    @IBOutlet private weak var contentStack: UIStackView!
    @IBOutlet private weak var loadingView: UIView!
    
    @IBOutlet private weak var infoStack: UIStackView!
    
    @IBOutlet private weak var titleLabel: UILabel!
    
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var segmentedControlContainer: UIView!
    @IBOutlet private weak var segmentedControl: BillAnalysisSegmentedControl!
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var projectionLabelTopSpaceConstraint: NSLayoutConstraint!
    @IBOutlet private weak var projectionLabel: UILabel!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet private weak var projectionSubLabel: UILabel!
    @IBOutlet private weak var projectionFooterLabel: UILabel!
    
    @IBOutlet weak var viewMoreButton: ButtonControl!
    @IBOutlet private weak var viewMoreButtonLabel: UILabel!
    
    @IBOutlet private weak var emptyStateView: UIView!
    @IBOutlet private weak var emptyStateTitleLabel: UILabel!
    @IBOutlet private weak var emptyStateDescriptionLabel: UILabel!
    
    @IBOutlet private weak var maintenanceModeView: UIView!
    
    @IBOutlet private weak var errorView: UIView!
    @IBOutlet private weak var errorTitleLabel: UILabel!
    @IBOutlet private weak var errorDescriptionLabel: UILabel!
    
    private var viewModel: HomeProjectedBillCardViewModel! {
        didSet {
            disposeBag = DisposeBag() // Clear all pre-existing bindings
            bindViewModel()
        }
    }
    
    static func create(withViewModel viewModel: HomeProjectedBillCardViewModel) -> HomeProjectedBillCardView {
        let view = Bundle.main.loadViewFromNib() as HomeProjectedBillCardView
        view.viewModel = viewModel
        return view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.cornerRadius = 10
        addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        
        clippingView.layer.cornerRadius = 10
        
        titleLabel.textColor = .blackText
        titleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        
        emptyStateTitleLabel.textColor = .blackText
        emptyStateTitleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        emptyStateDescriptionLabel.textColor = .middleGray
        emptyStateDescriptionLabel.font = OpenSans.regular.of(textStyle: .title1)
        emptyStateDescriptionLabel.attributedText = NSLocalizedString("Projected bill is not available for this account.", comment: "")
            .attributedString(textAlignment: .center, lineHeight: 26)
        
        errorTitleLabel.textColor = .blackText
        errorTitleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        errorDescriptionLabel.textColor = .middleGray
        errorDescriptionLabel.font = OpenSans.regular.of(textStyle: .title1)
        errorDescriptionLabel.attributedText = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
            .attributedString(textAlignment: .center, lineHeight: 26)
        
        segmentedControl.setItems(leftLabel: NSLocalizedString("Electric", comment: ""),
                                  rightLabel: NSLocalizedString("Gas", comment: ""),
                                  initialSelectedIndex: 0)
        stackView.bringSubviewToFront(segmentedControlContainer)
        
        infoButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        projectionLabel.textColor = .blackText
        projectionLabel.font = OpenSans.semiboldItalic.of(size: 34)
        projectionSubLabel.textColor = .deepGray
        projectionSubLabel.font = OpenSans.regular.of(textStyle: .footnote)
        projectionFooterLabel.textColor = .deepGray
        projectionFooterLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        
        viewMoreButtonLabel.textColor = .actionBlue
        viewMoreButtonLabel.font = SystemFont.semibold.of(textStyle: .title1)
        viewMoreButtonLabel.text = NSLocalizedString("View More", comment: "")
        
        viewMoreButton.addTopBorder(color: UIColor(red: 238/255, green: 238/255, blue: 238/255, alpha: 1), width: 1)
        viewMoreButton.roundCorners([.bottomLeft, .bottomRight], radius: 10)
        viewMoreButton.backgroundColorOnPress = .softGray
        viewMoreButton.accessibilityLabel = NSLocalizedString("View More", comment: "")
    }
    
    private func showContent() {
        infoStack.isHidden = false
        emptyStateView.isHidden = true
        errorView.isHidden = true
        maintenanceModeView.isHidden = true
    }
    
    private func showEmptyState() {
        infoStack.isHidden = true
        emptyStateView.isHidden = false
        errorView.isHidden = true
        maintenanceModeView.isHidden = true
    }
    
    private func showErrorState() {
        infoStack.isHidden = true
        emptyStateView.isHidden = true
        errorView.isHidden = false
        maintenanceModeView.isHidden = true
    }
    
    private func showMaintenanceModeState() {
        infoStack.isHidden = true
        emptyStateView.isHidden = true
        errorView.isHidden = true
        maintenanceModeView.isHidden = false
    }
    
    private func bindViewModel() {
        viewModel.showLoadingState.drive(contentStack.rx.isHidden).disposed(by: disposeBag)
        viewModel.showLoadingState.not().drive(loadingView.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.showContent
            .drive(onNext: { [weak self] in
                self?.showContent()
            })
            .disposed(by: disposeBag)
        
        viewModel.showEmptyState
            .drive(onNext: { [weak self] in
                self?.showEmptyState()
            })
            .disposed(by: disposeBag)
        
        viewModel.showError
            .drive(onNext: { [weak self] in
                self?.showErrorState()
            })
            .disposed(by: disposeBag)
        
        viewModel.showMaintenanceModeState
            .drive(onNext: { [weak self] in
                self?.showMaintenanceModeState()
            })
            .disposed(by: disposeBag)
        
        viewModel.showLoadingState
            .drive(onNext: { _ in UIAccessibility.post(notification: .screenChanged, argument: nil) })
            .disposed(by: disposeBag)
        
        viewModel.shouldShowElectricGasSegmentedControl.drive(onNext: { [weak self] shouldShow in
            self?.contentView.backgroundColor = shouldShow ? UIColor.softGray : UIColor.white
            self?.projectionLabelTopSpaceConstraint.constant = shouldShow ? 31 : 16
        }).disposed(by: disposeBag)
        
        viewModel.shouldShowElectricGasSegmentedControl.not().drive(segmentedControlContainer.rx.isHidden).disposed(by: disposeBag)
        segmentedControl.selectedIndex.asObservable().distinctUntilChanged().bind(to: viewModel.electricGasSelectedSegmentIndex).disposed(by: disposeBag)
        
        viewModel.projectionLabelString.drive(projectionLabel.rx.text).disposed(by: disposeBag)
        viewModel.projectionSubLabelString.drive(projectionSubLabel.rx.text).disposed(by: disposeBag)
        viewModel.projectionFooterLabelString.drive(projectionFooterLabel.rx.text).disposed(by: disposeBag)
        
        viewModel.projectionNotAvailable.drive(infoButton.rx.isHidden).disposed(by: disposeBag)
        viewModel.projectionNotAvailable.drive(projectionFooterLabel.rx.isHidden).disposed(by: disposeBag)
    }

}
