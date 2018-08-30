//
//  StormModeHomeViewController.swift
//  Mobile
//
//  Created by Samuel Francis on 8/28/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class StormModeHomeViewController: UIViewController {
    
    @IBOutlet private weak var exitButton: UIButton!
    
    private let viewModel = StormModeHomeViewModel(authService: ServiceFactory.createAuthenticationService())
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        exitButton.isHidden = true
        
        viewModel.stormModeEnded
            .drive(onNext: { [weak self] in self?.stormModeEnded() })
            .disposed(by: disposeBag)
        
        exitButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in self?.returnToMainApp() })
            .disposed(by: disposeBag)
    }
    
    private func stormModeEnded() {
        let noAction = UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .cancel)
        { [weak self] _ in self?.exitButton.isHidden = false }
        
        let yesAction = UIAlertAction(title: NSLocalizedString("Return", comment: ""), style: .default)
        { [weak self] _ in
            self?.returnToMainApp()
        }
        
        presentAlert(title: NSLocalizedString("Storm Mode Has Ended", comment: ""),
                     message: NSLocalizedString("Would you like to return to the main app?", comment: ""),
                     style: .alert,
                     actions: [noAction, yesAction])
    }
    
    private func returnToMainApp() {
        guard let window = (UIApplication.shared.delegate as? AppDelegate)?.window else { return }
        window.rootViewController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateInitialViewController()
    }
    
}
