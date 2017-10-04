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
    
    init() {
        super.init(nibName: BillAnalysisViewController.className, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Bill Analysis", comment: "")
        
        scrollView.backgroundColor = .softGray
        
        electricGasSegmentedControl.items = [NSLocalizedString("Electric", comment: ""), NSLocalizedString("Gas", comment: "")]
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        }
    }
    
    @IBAction func onXButtonPress() {
        self.dismiss(animated: true, completion: nil)
    }
    
    



}
