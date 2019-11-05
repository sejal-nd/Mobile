//
//  HomeContentViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 10/29/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class HomeContentViewController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var fab: ButtonControl!
    
    var inGame = false
    var flipping = false
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return inGame ? .default : .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        fab.layer.cornerRadius = 25
        fab.layer.masksToBounds = false
        fab.normalBackgroundColor = .actionBlue
        fab.backgroundColorOnPress = UIColor.actionBlue.darker()
        
        var viewController: UIViewController
        if UserDefaults.standard.bool(forKey: UserDefaultKeys.prefersGameHome) {
            let sb = UIStoryboard(name: "Game", bundle: nil)
            viewController = sb.instantiateViewController(withIdentifier: "GameHome")
            inGame = true
        } else {
            viewController = storyboard!.instantiateViewController(withIdentifier: "Home")
            inGame = false
        }
        addChild(viewController)
        containerView.addSubview(viewController.view)
        view.sendSubviewToBack(viewController.view)
        
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant:0),
            viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            viewController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
        viewController.didMove(toParent: self)
        
        containerView = viewController.view
    }
    
    @IBAction func onFabPress() {
        if flipping { return }
        
        flipping = true
        if inGame {
            self.inGame = false
            let controller = storyboard!.instantiateViewController(withIdentifier: "Home")
            addChild(controller)
            controller.view.translatesAutoresizingMaskIntoConstraints = false

            UIView.transition(from: containerView, to: controller.view, duration: 1, options: [.transitionFlipFromRight], completion: { [weak self] _ in
                self?.flipping = false
                self?.containerView = controller.view
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
            self.inGame = true
            let controller = storyboard!.instantiateViewController(withIdentifier: "Game")
            addChild(controller)
            controller.view.translatesAutoresizingMaskIntoConstraints = false

            UIView.transition(from: containerView, to: controller.view, duration: 1, options: [.transitionFlipFromRight], completion: { [weak self] _ in
                self?.flipping = false
                self?.containerView = controller.view
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
        
        UserDefaults.standard.set(inGame, forKey: UserDefaultKeys.prefersGameHome)
        setNeedsStatusBarAppearanceUpdate()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
