//
//  HomeEditViewController.swift
//  Mobile
//
//  Created by Samuel Francis on 6/14/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class HomeEditViewController: UIViewController {

    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .primaryColor
        navigationBar.barTintColor = .primaryColor
        navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: OpenSans.bold.of(size: 18)
        ]
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        
        cancelButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                self?.presentingViewController?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
