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
import Toast_Swift

class MaintenanceModeViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    var maintenance: Maintenance?
    
    private lazy var viewModel = MaintenanceModeViewModel(authService: ServiceFactory.createAuthenticationService(),
                                                          maintenance: maintenance)
    
    @IBOutlet weak var reloadButton: ButtonControl!
    @IBOutlet weak var reloadLabel: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var opcoLogo: UIImageView!
    @IBOutlet weak var maintenanceModeBody: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var bodyTextView: ZeroInsetDataDetectorTextView!
    @IBOutlet weak var footerTextView: ZeroInsetDataDetectorTextView!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            isModalInPresentation = true
        }
        
        reloadButton.isAccessibilityElement = true
        reloadButton.accessibilityLabel = NSLocalizedString("Reload", comment: "")
        
        reloadLabel.font = SystemFont.bold.of(textStyle: .headline)
        
        reloadButton.rx.touchUpInside.asDriver()
            .drive(onNext: { [weak self] in self?.onReloadPress() })
            .disposed(by: disposeBag)
        
        maintenanceModeBody.addShadow(color: .black, opacity: 0.15, offset: .zero, radius: 4)
        maintenanceModeBody.layer.cornerRadius = 10
        
        headerLabel.text = viewModel.headerLabelText
        headerLabel.textColor = .deepGray
        headerLabel.font = SystemFont.bold.of(textStyle: .subheadline)
        
        bodyTextView.font = OpenSans.regular.of(textStyle: .footnote)
        bodyTextView.attributedText = viewModel.labelBody
        bodyTextView.accessibilityLabel = viewModel.labelBody.string
        
        bodyTextView.textColor = .blackText
        bodyTextView.tintColor = .actionBlue // Color of the phone numbers
        
        footerTextView.font = OpenSans.regular.of(textStyle: .footnote)
        footerTextView.tintColor = .actionBlue
        footerTextView.attributedText = viewModel.footerLabelText
        
        view.backgroundColor = .primaryColor
    }
    
    func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        return a + (b - a) * t
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func onReloadPress() {
        LoadingView.show()
        viewModel.doReload(onSuccess: { [weak self] isMaintenance in
            LoadingView.hide()
            guard let self = self else { return }
            self.presentingViewController?.view.isUserInteractionEnabled = true
            if !isMaintenance {
                NotificationCenter.default.post(name: .didMaintenanceModeTurnOff, object: nil)
                self.presentingViewController?.dismiss(animated: true, completion: {
                    dLog("Dismissed MM")
                })
            } else {
                self.headerLabel.text = self.viewModel.headerLabelText
            }
        }, onError: { [weak self] errorMessage in
            LoadingView.hide()
            let alertController = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errorMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self?.present(alertController, animated: true, completion: nil)
        })
    }
}

extension MaintenanceModeViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        opcoLogo.alpha = lerp(1, 0, scrollView.contentOffset.y / 50.0)
    }
    
}
