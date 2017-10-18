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
    
    @IBOutlet weak var viewUsageButton: UIButton!
    
    fileprivate var viewModel: HomeUsageCardViewModel! {
        didSet {
            disposeBag = DisposeBag() // Clear all pre-existing bindings
            //bindViewModel()
        }
    }

    static func create(withViewModel viewModel: HomeUsageCardViewModel) -> HomeUsageCardView {
        let view = Bundle.main.loadViewFromNib() as HomeUsageCardView
        view.viewModel = viewModel
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

}
