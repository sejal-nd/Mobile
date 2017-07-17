//
//  BillHomeCard.swift
//  Mobile
//
//  Created by Sam Francis on 7/17/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class BillHomeCard: UIView {
    
    private var viewModel: BillHomeCardViewModel!

    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 303, height: 51)
    }
    
    static func create(withViewModel viewModel: BillHomeCardViewModel) -> BillHomeCard {
        let view = Bundle.main.loadViewFromNib() as BillHomeCard
        view.viewModel = viewModel
        return view
    }

}
