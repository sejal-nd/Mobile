//
//  ToggleTableViewCell.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/13/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

class ToggleTableViewCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = .white
            titleLabel.font = SystemFont.medium.of(textStyle: .headline)
        }
    }
    @IBOutlet weak var toggle: UISwitch! {
        didSet {
            toggle.layer.cornerRadius = 16.0
            toggle.layer.masksToBounds = true
            
            toggle.tintColor = .switchBackgroundColor
            toggle.backgroundColor = .switchBackgroundColor
            toggle.thumbTintColor = .primaryColor
            toggle.onTintColor = .white
        }
    }
    
    private var viewController: MoreViewController!
    private var viewModel: MoreViewModel!
    
    private var biometricsPasswordRetryCount = 0
    
    private let disposeBag = DisposeBag()

    
    // MARK: - Configure
    
    public func configure(viewController: MoreViewController, viewModel: MoreViewModel) {
        self.viewController = viewController
        self.viewModel = viewModel
        
        // Style
        backgroundColor = .primaryColor
        
        // Set Data
        if viewModel.biometricsString() == "Face ID" {
            iconImageView.image = #imageLiteral(resourceName: "ic_morefaceid")
            titleLabel.text = NSLocalizedString("Face ID", comment: "")
        } else {
            iconImageView.image = #imageLiteral(resourceName: "ic_moretouchid")
            titleLabel.text = NSLocalizedString("Touch ID", comment: "")
        }
        toggle.isOn = viewModel.isBiometryEnabled()
        
        // Accessibility
        titleLabel.accessibilityLabel = titleLabel.text
        toggle.isAccessibilityElement = true
    }
    
    
    // MARK: - Action
    
    @IBAction func togglePress(_ sender: UISwitch) {
        if sender.isOn {
            presentPasswordAlert(message: viewModel.getConfirmPasswordMessage())
            Analytics.log(event: .touchIDEnable)
        } else {
            viewModel.disableBiometrics()
            Analytics.log(event: .touchIDDisable)
        }
    }
    
    
    // MARK: - Helper
    
    private func presentPasswordAlert(message: String) {
        let pwAlert = UIAlertController(title: NSLocalizedString("Confirm Password", comment: ""), message: message, preferredStyle: .alert)
        pwAlert.addTextField(configurationHandler: { [weak self] (textField) in
            guard let `self` = self else { return }
            textField.placeholder = NSLocalizedString("Password", comment: "")
            textField.isSecureTextEntry = true
            textField.rx.text.orEmpty.bind(to: self.viewModel.password).disposed(by: self.disposeBag)
        })
        pwAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { [weak self] (action) -> Void in
            self?.toggle.isOn = false
        }))
        pwAlert.addAction(UIAlertAction(title: NSLocalizedString("Enable", comment: ""), style: .default, handler: { [weak self] (action) -> Void in
            LoadingView.show()
            self?.viewModel.validateCredentials(onSuccess: { [weak self] in
                guard let `self` = self else { return }
                LoadingView.hide()
                self.viewController.view.showToast(String(format: NSLocalizedString("%@ Enabled", comment: ""), self.viewModel.biometricsString()!))
                }, onError: { [weak self] (error) in
                    LoadingView.hide()
                    guard let `self` = self else { return }
                    self.biometricsPasswordRetryCount += 1
                    if self.biometricsPasswordRetryCount < 3 {
                        self.presentPasswordAlert(message: NSLocalizedString("Error", comment: "") + ": \(error)")
                    } else {
                        self.biometricsPasswordRetryCount = 0
                        self.toggle.isOn = false
                    }
            })
        }))
        viewController.present(pwAlert, animated: true, completion: nil)
    }
    
}
