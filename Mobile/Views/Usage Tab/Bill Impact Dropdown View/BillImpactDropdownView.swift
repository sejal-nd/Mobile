//
//  BillImpactDropdownView.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/13/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class BillImpactDropdownView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var billFactorView: UIView!
    
    private var isExpanded = false {
        didSet {
            if isExpanded {
                billFactorView.isHidden = false
            } else {
                billFactorView.isHidden = true
            }
        }
    }
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
        
        prepareViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
        
        prepareViews()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("BillImpactDropdownView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    private func prepareViews() {
        isExpanded = false
    }
    
    
    // MARK: - Configuration
    

    
    // MARK: - Actions
    
    @IBAction func toggleStackView(_ sender: Any) {
        isExpanded = !isExpanded
    }
    

}
