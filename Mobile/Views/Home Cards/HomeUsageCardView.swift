//
//  HomeUsageCardView.swift
//  Mobile
//
//  Created by Marc Shilling on 10/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class HomeUsageCardView: UIView {
    
    var disposeBag = DisposeBag()
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var segmentedControl: BillAnalysisSegmentedControl!
    
    @IBOutlet weak var billComparisonContentView: UIView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var errorView: UIView!
    
    @IBOutlet weak var viewUsageButton: UIButton!
    
    fileprivate var viewModel: HomeUsageCardViewModel! {
        didSet {
            disposeBag = DisposeBag() // Clear all pre-existing bindings
            bindViewModel()
        }
    }

    static func create(withViewModel viewModel: HomeUsageCardViewModel) -> HomeUsageCardView {
        let view = Bundle.main.loadViewFromNib() as HomeUsageCardView
        view.viewModel = viewModel
        
        view.segmentedControl.setItems(leftLabel: NSLocalizedString("Electricity", comment: ""),
                                       rightLabel: NSLocalizedString("Gas", comment: ""),
                                       initialSelectedIndex: 0)
        
        return view
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        styleViews()
    }
    
    private func styleViews() {
        addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        layer.cornerRadius = 2
        


    }
    
    private func bindViewModel() {
        // Loading/Error/Content States
        viewModel.shouldShowBillComparisonContentView.not().drive(billComparisonContentView.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.loadingTracker.asDriver().not().drive(loadingView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowErrorView.not().drive(errorView.rx.isHidden).disposed(by: disposeBag)
        
        // Segmented Controls
        segmentedControl.selectedIndex.asObservable().distinctUntilChanged().bind(to: viewModel.electricGasSelectedSegmentIndex).disposed(by: disposeBag)
    }

}
