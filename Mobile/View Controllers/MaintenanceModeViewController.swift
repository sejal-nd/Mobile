//
//  MaintenanceModeViewController.swift
//  Mobile
//
//  Created by Constantin Koehler on 7/17/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import ToastSwiftFramework

class MaintenanceModeViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    let viewModel = MaintenanceModeViewModel(authService: ServiceFactory.createAuthenticationService())
    
    @IBOutlet weak var reloadButton: ButtonControl!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var opcoLogo: UIImageView!
    @IBOutlet weak var maintenanceModeBody: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var label1: DataDetectorTextView!
    @IBOutlet weak var label2: DataDetectorTextView!
    @IBOutlet weak var BGEStackView: UIStackView!
    @IBOutlet weak var label3: UILabel!
    @IBOutlet weak var label4: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reloadButton.rx.touchUpInside.asDriver()
            .drive(onNext: onReloadPress)
            .addDisposableTo(disposeBag)
        
        maintenanceModeBody.addShadow(color: .black, opacity: 0.15, offset: .zero, radius: 4)
        maintenanceModeBody.layer.cornerRadius = 2
        
        headerLabel.text = viewModel.getHeaderLabelText()
        headerLabel.font = SystemFont.bold.of(textStyle: .body)
        headerLabel.textColor = .deepGray
        
        label1.text = viewModel.getLabel1Text()
        label1.font = OpenSans.regular.of(textStyle: .body)
        label1.textColor = .black
        
        label2.text = viewModel.getLabel2Text()
        label2.font = OpenSans.regular.of(textStyle: .body)
        label2.textColor = .black
        
        label3.text = viewModel.getLabel3Text()
        label3.font = OpenSans.regular.of(textStyle: .body)
        label3.textColor = .black
        
        label4.text = viewModel.getLabel4Text()
        label4.font = OpenSans.regular.of(textStyle: .body)
        label4.textColor = .black
        
        view.backgroundColor = .primaryColor
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self) // Important for deep linking, do not remove
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.barStyle = .black // Needed for white status bar
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.isTranslucent = true
        
        setNeedsStatusBarAppearanceUpdate()
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        return a + (b - a) * t;
    }
    
    func onReloadPress() {
        viewModel.doReload(onSuccess: { isMaintenance in
            LoadingView.hide()
        }, onError: { errorMessage in
            LoadingView.hide()
            let alertController = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errorMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        })
    }
}

extension MaintenanceModeViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        opcoLogo.alpha = lerp(1, 0, scrollView.contentOffset.y / 50.0)
    }
    
}
