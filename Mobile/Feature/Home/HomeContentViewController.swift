//
//  HomeContentViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 10/29/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

class HomeContentViewController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var fab: ButtonControl!
    @IBOutlet weak var fabImageView: UIImageView!
    
    var inGame = false
    var flipping = false
    
    let bag = DisposeBag()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return inGame ? .default : .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        fab.isHidden = true
        
        fab.layer.cornerRadius = 27.5
        fab.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 5), radius: 10)
        let fabColor = UIColor(red: 17/255, green: 57/255, blue: 112/255, alpha: 1)
        fab.normalBackgroundColor = fabColor
        fab.backgroundColorOnPress = fabColor.darker()
        
        setupNotifications()
        //displayInitialView()
    }
    
//    private func displayInitialView() {
//        var viewController: UIViewController
//        if UserDefaults.standard.bool(forKey: UserDefaultKeys.prefersGameHome) {
//            let sb = UIStoryboard(name: "Game", bundle: nil)
//            viewController = sb.instantiateViewController(withIdentifier: "GameHome")
//            fabImageView.image = #imageLiteral(resourceName: "ic_fab_on_game")
//            inGame = true
//        } else {
//            viewController = storyboard!.instantiateViewController(withIdentifier: "Home")
//            fabImageView.image = #imageLiteral(resourceName: "ic_fab_on_home")
//            inGame = false
//        }
//        viewController.view.translatesAutoresizingMaskIntoConstraints = false
//
//        addChild(viewController)
//        containerView.addSubview(viewController.view)
//        view.sendSubviewToBack(viewController.view)
//
//        NSLayoutConstraint.activate([
//            viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant:0),
//            viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
//            viewController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
//            viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
//        ])
//        viewController.didMove(toParent: self)
//
//        containerView = viewController.view
//    }
    
    private func setupNotifications() {
        NotificationCenter.default.rx.notification(.gameOnboardingComplete, object: nil)
            .asObservable()
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.onGameOnboardingComplete()
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(.gameDidOptOut, object: nil)
            .asObservable()
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.onGameOptOut()
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(.gameSwitchToGameView, object: nil)
            .asObservable()
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.inGame = false
                self?.switchViews(animated: false, onCompletion: nil)
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(.gameSwitchToHomeView, object: nil)
            .asObservable()
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.inGame = true
                self?.switchViews(animated: false, onCompletion: nil)
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(.gameSetFabHidden, object: nil)
            .asObservable()
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] noti in
                if let isHidden = noti.object as? Bool {
                    self?.fab.isHidden = isHidden
                }
            })
            .disposed(by: bag)
    }
    
    // Upon onboarding complete, switches to the game view without animation, and shows the FAB
    private func onGameOnboardingComplete() {
        UserDefaults.standard.set(true, forKey: UserDefaultKeys.prefersGameHome)
        switchViews(animated: false, onCompletion: nil)
        fab.isHidden = false
    }
    
    // Upon opt out, switches to the normal home view without animation, and hides the FAB
    private func onGameOptOut() {
        UserDefaults.standard.set(false, forKey: UserDefaultKeys.prefersGameHome)
        inGame = true // Ensure that switchViews will change to home screen
        switchViews(animated: false, onCompletion: nil)
        fab.isHidden = true
    }
    
    @IBAction func onFabPress() {
        if flipping { return }
        
        // Tracking for the 'Try the FAB' task
        if inGame && GameTaskStore.shared.tryFabActivated {
            GameTaskStore.shared.tryFabWentHome = true
        } else if !inGame && GameTaskStore.shared.tryFabActivated && GameTaskStore.shared.tryFabWentHome {
            GameTaskStore.shared.tryFabWentBackToGame = true
        }
        
        UserDefaults.standard.set(!self.inGame, forKey: UserDefaultKeys.prefersGameHome)
        
        flipping = true
        switchViews(animated: true) { [weak self] in
            guard let self = self else { return }
            self.flipping = false
        }
    }
    
    func switchViews(animated: Bool, onCompletion: (() -> Void)?) {
        let duration = animated ? 1.0 : 0.0
        if inGame {
            inGame = false
            let controller = storyboard!.instantiateViewController(withIdentifier: "Home")
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            
            addChild(controller)
            
            fabImageView.image = #imageLiteral(resourceName: "ic_fab_on_home")
            UIView.transition(from: containerView, to: controller.view, duration: duration, options: [.transitionFlipFromRight], completion: { [weak self] _ in
                self?.containerView = controller.view
                onCompletion?()
            })
            
            NSLayoutConstraint.activate([
                controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant:0),
                controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
                controller.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
                controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
            ])
            controller.didMove(toParent: self)
            view.sendSubviewToBack(controller.view)
        } else {
            inGame = true
            let sb = UIStoryboard(name: "Game", bundle: nil)
            let controller = sb.instantiateViewController(withIdentifier: "GameHome")
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            
            addChild(controller)
            
            fabImageView.image = #imageLiteral(resourceName: "ic_fab_on_game")
            UIView.transition(from: containerView, to: controller.view, duration: duration, options: [.transitionFlipFromRight], completion: { [weak self] _ in
                self?.containerView = controller.view
                onCompletion?()
            })
            
            NSLayoutConstraint.activate([
                controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant:0),
                controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
                controller.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
                controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
            ])
            controller.didMove(toParent: self)
            view.sendSubviewToBack(controller.view)
        }
        
        setNeedsStatusBarAppearanceUpdate()
    }

}
