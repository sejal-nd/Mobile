//
//  BillAnalysisViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 10/4/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class BillAnalysisViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var electricGasSegmentView: UIView!
    @IBOutlet weak var electricGasSegmentedControl: SegmentedControl!
    
    @IBOutlet weak var barDescriptionView: UIView!
    @IBOutlet weak var barDescriptionDateLabel: UILabel!
    @IBOutlet weak var barDescriptionDetailLabel: UILabel!
    
    
    init() {
        super.init(nibName: BillAnalysisViewController.className, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Bill Analysis", comment: "")
        
        styleViews()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        }
    }
    
    func styleViews() {
        scrollView.backgroundColor = .softGray
        
        electricGasSegmentedControl.items = [NSLocalizedString("Electric", comment: ""), NSLocalizedString("Gas", comment: "")]
        
        barDescriptionView.addShadow(color: .black, opacity: 0.08, offset: .zero, radius: 2)
        barDescriptionDateLabel.font = OpenSans.semibold.of(textStyle: .subheadline)
        barDescriptionDateLabel.textColor = .blackText
        barDescriptionDetailLabel.font = OpenSans.regular.of(textStyle: .footnote)
        barDescriptionDetailLabel.textColor = .blackText
    }
    
    
    
    



}
