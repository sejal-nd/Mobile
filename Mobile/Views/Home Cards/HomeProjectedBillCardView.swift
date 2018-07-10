//
//  HomeProjectedBillCardView.swift
//  Mobile
//
//  Created by Marc Shilling on 7/6/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class HomeProjectedBillCardView: UIView {
    
    var disposeBag = DisposeBag()
    
    @IBOutlet weak var clippingView: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var segmentedControlContainer: UIView!
    @IBOutlet weak var segmentedControl: BillAnalysisSegmentedControl!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var projectionLabelTopSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var projectionLabel: UILabel!
    @IBOutlet weak var projectionSubLabel: UILabel!
    @IBOutlet weak var projectionFooterLabel: UILabel!
    
    @IBOutlet weak var viewMoreButton: ButtonControl!
    @IBOutlet weak var viewMoreButtonLabel: UILabel!
    
    fileprivate var viewModel: HomeProjectedBillCardViewModel! {
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
        titleLabel.text = NSLocalizedString("Projected Bill", comment: "")
        
        segmentedControl.setItems(leftLabel: NSLocalizedString("Electric", comment: ""),
                                  rightLabel: NSLocalizedString("Gas", comment: ""),
                                  initialSelectedIndex: 0)
        stackView.bringSubview(toFront: segmentedControlContainer)
        
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
    
    private func bindViewModel() {
        viewModel.shouldShowElectricGasSegmentedControl.drive(onNext: { [weak self] shouldShow in
            self?.contentView.backgroundColor = shouldShow ? UIColor.softGray : UIColor.white
            self?.projectionLabelTopSpaceConstraint.constant = shouldShow ? 31 : 16
        }).disposed(by: disposeBag)
        
        viewModel.shouldShowElectricGasSegmentedControl.not().drive(segmentedControlContainer.rx.isHidden).disposed(by: disposeBag)
        segmentedControl.selectedIndex.asObservable().distinctUntilChanged().bind(to: viewModel.electricGasSelectedSegmentIndex).disposed(by: disposeBag)
        
        viewModel.projectionLabelString.drive(projectionLabel.rx.text).disposed(by: disposeBag)
        viewModel.projectionSubLabelString.drive(projectionSubLabel.rx.text).disposed(by: disposeBag)
        viewModel.projectionFooterLabelString.drive(projectionFooterLabel.rx.text).disposed(by: disposeBag)
    }

}
