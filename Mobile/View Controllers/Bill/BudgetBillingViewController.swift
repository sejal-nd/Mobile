//
//  BudgetBillingViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/20/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class BudgetBillingViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var whatIsBudgetBillingButtonView: UIView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .whiteSmoke
        
        whatIsBudgetBillingButtonView.layer.cornerRadius = 2
        whatIsBudgetBillingButtonView.layer.shadowOffset = CGSize(width: 0, height: 0)
        whatIsBudgetBillingButtonView.layer.shadowOpacity = 0.3
        whatIsBudgetBillingButtonView.layer.shadowColor = UIColor.black.cgColor
        whatIsBudgetBillingButtonView.layer.shadowRadius = 3
        whatIsBudgetBillingButtonView.layer.masksToBounds = false
    }
    
    @IBAction func onButtonTouchDown(_ sender: Any) {
        let button = sender as! UIButton
        button.superview?.backgroundColor = .whiteButtonHighlight
    }
    
    @IBAction func onButtonTouchCancel(_ sender: Any) {
        let button = sender as! UIButton
        button.superview?.backgroundColor = .white
    }

}
