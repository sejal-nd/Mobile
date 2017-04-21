//
//  PaperlessEBillViewController.swift
//  Mobile
//
//  Created by Sam Francis on 4/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PaperlessEBillViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    // Background
    @IBOutlet weak var topBackgroundView: UIView!
    @IBOutlet weak var gradientBackgroundView: UIView!
    private var gradientLayer: CALayer = CAGradientLayer()
    
    // Content
    @IBOutlet weak var whatIsButtonView: UIView!
    @IBOutlet weak var whatIsButton: UIButton!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var enrollAllAccountsView: UIView!
    @IBOutlet weak var enrollAllAccountsSwitch: UISwitch!
    
    @IBOutlet weak var detailsLabel: UILabel!
    
    var accounts:[Account]!
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        whatIsButtonView.layer.shadowColor = UIColor.black.cgColor
        whatIsButtonView.layer.shadowOpacity = 0.2
        whatIsButtonView.layer.shadowRadius = 3
        whatIsButtonView.layer.shadowOffset = CGSize(width: 0, height: 0)
        whatIsButtonView.layer.cornerRadius = 2
        
        topBackgroundView.layer.shadowColor = UIColor.black.cgColor
        topBackgroundView.layer.shadowOpacity = 0.08
        topBackgroundView.layer.shadowRadius = 1
        topBackgroundView.layer.shadowOffset = CGSize(width: 0, height: 2)
        
        enrollAllAccountsSwitch.onTintColor = .primaryColor
        
        enrollAllAccountsView.isHidden = accounts.count <= 1
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.removeFromSuperlayer()
        
        let gLayer = CAGradientLayer()
        gLayer.frame = gradientBackgroundView.frame
        gLayer.colors = [UIColor.whiteSmoke.cgColor, UIColor.white.cgColor]
        
        gradientLayer = gLayer
        gradientBackgroundView.layer.addSublayer(gLayer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.barTintColor = .primaryColor
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.isTranslucent = false
        
        let titleDict: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: UIFont(name: "OpenSans-Bold", size: 18)!
        ]
        navigationController?.navigationBar.titleTextAttributes = titleDict
    }

}
