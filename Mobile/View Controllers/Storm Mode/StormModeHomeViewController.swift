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
    @IBOutlet weak var exitButton: UIButton!
    
    
    let viewModel = StormModeHomeViewModel(authService: ServiceFactory.createAuthenticationService())
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        exitButton.isHidden = true
        
        // Show the exit button when storm mode ends
        viewModel.stormModeEnded
            .drive(onNext: { [weak self] in
                self?.stormModeEnded()
            })
            .disposed(by: disposeBag)
        
        exitButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                self?.presentingViewController?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
    
    private func stormModeEnded() {
        let noAction = UIAlertAction(title: NSLocalizedString("No", comment: ""),
                                     style: .cancel,
                                     handler: { [weak self] _ in
                                        self?.exitButton.isHidden = false
        })
        
        let yesAction = UIAlertAction(title: NSLocalizedString("Yes", comment: ""),
                                      style: .default,
                                      handler: { [weak self] _ in
                                        self?.presentingViewController?.dismiss(animated: true, completion: nil)
        })
        
        presentAlert(title: NSLocalizedString("Storm Mode Ended", comment: ""),
                     message: NSLocalizedString("Storm Mode has ended. Would you like to return to the main app?", comment: ""),
                     style: .alert,
                     actions: [noAction, yesAction])
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
