//
//  BillHomeCard.swift
//  Mobile
//
//  Created by Sam Francis on 7/17/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxSwiftExt

class HomeBillCardView: UIView {
    
    var bag = DisposeBag()
    @IBOutlet weak var billNotReadyStack: UIStackView!
    @IBOutlet weak var errorStack: UIStackView!
    @IBOutlet weak var infoStack: UIStackView!
    
    @IBOutlet weak var dueDateStack: UIStackView!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var dueDateTooltip: UIButton!
    
    private var viewModel: HomeBillCardViewModel! {
        didSet {
            bag = DisposeBag() // Clear all pre-existing bindings
            bindViewModel()
        }
    }
    
    static func create(withViewModel viewModel: HomeBillCardViewModel) -> HomeBillCardView {
        let view = Bundle.main.loadViewFromNib() as HomeBillCardView
        view.styleViews()
        view.viewModel = viewModel
        return view
    }
    
    private func styleViews() {
        // set fonts, colors, etc. that aren't dependent on data
    }
    
    private func bindViewModel() {
        viewModel.billNotReady.not().drive(billNotReadyStack.rx.isHidden).addDisposableTo(bag)
        viewModel.errorOccurred.not().drive(errorStack.rx.isHidden).addDisposableTo(bag)
    }

}
