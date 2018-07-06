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
        titleLabel.font = OpenSans.semibold.of(size: 18)
        titleLabel.text = NSLocalizedString("Projected Bill", comment: "")
        
        viewMoreButtonLabel.textColor = .actionBlue
        viewMoreButtonLabel.font = SystemFont.semibold.of(textStyle: .title1)
        viewMoreButtonLabel.text = NSLocalizedString("View More", comment: "")
        
        viewMoreButton.roundCorners([.bottomLeft, .bottomRight], radius: 10)
    }
    
    private func bindViewModel() {
        
    }

}
