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
        
    var inGame = false
    var flipping = false
    
    let bag = DisposeBag()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return inGame ? .default : .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNotifications()
        //displayInitialView()
    }
    
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
                UserDefaults.standard.set(true, forKey: UserDefaultKeys.prefersGameHome)
                self?.switchViews(animated: false, onCompletion: nil)
                FirebaseUtility.logEventV2(.gamification(parameters: [.switch_to_game_view]))
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(.gameSwitchToHomeView, object: nil)
            .asObservable()
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.inGame = true
                UserDefaults.standard.set(false, forKey: UserDefaultKeys.prefersGameHome)
                self?.switchViews(animated: false, onCompletion: nil)
                FirebaseUtility.logEventV2(.gamification(parameters: [.switch_to_home_view]))
            })
            .disposed(by: bag)
    }
    
    // Upon onboarding complete, switches to the game view without animation, and shows the FAB
    private func onGameOnboardingComplete() {
        UserDefaults.standard.set(true, forKey: UserDefaultKeys.prefersGameHome)
        switchViews(animated: false, onCompletion: nil)
    }
    
    // Upon opt out, switches to the normal home view without animation, and hides the FAB
    private func onGameOptOut() {
        UserDefaults.standard.set(false, forKey: UserDefaultKeys.prefersGameHome)
        inGame = true // Ensure that switchViews will change to home screen
        switchViews(animated: false, onCompletion: nil)
    }
    
    override var shouldAutomaticallyForwardAppearanceMethods: Bool {
        return true
    }
    
    func switchViews(animated: Bool, onCompletion: (() -> Void)?) {
        let duration = animated ? 1.0 : 0.0
        if inGame {
            inGame = false
            
            let controller = storyboard!.instantiateViewController(withIdentifier: "Home")
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            addChild(controller)
            controller.beginAppearanceTransition(true, animated: false)
            
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
            controller.beginAppearanceTransition(true, animated: false)
            
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
