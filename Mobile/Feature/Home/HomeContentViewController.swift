//
//  HomeContentViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 10/29/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class HomeContentViewController: UIViewController {
    
    @IBOutlet weak var homeContainer: UIView!
    @IBOutlet weak var gameContainer: UIView!
    
    @IBOutlet weak var fab: ButtonControl!
    
    var inGame = false
    var flipping = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        fab.layer.cornerRadius = 25
        fab.layer.masksToBounds = false
        fab.normalBackgroundColor = .actionBlue
        fab.backgroundColorOnPress = UIColor.actionBlue.darker()

        gameContainer.isHidden = true
        // Do any additional setup after loading the view.
    }
    
    @IBAction func onFabPress() {
        if flipping { return }
        
        flipping = true
        if inGame {
            let controller = storyboard!.instantiateViewController(withIdentifier: "Home")
            addChild(controller)
            controller.view.translatesAutoresizingMaskIntoConstraints = false

            UIView.transition(from: homeContainer, to: controller.view, duration: 1, options: [.transitionFlipFromRight], completion: { [weak self] _ in
                self?.inGame = false
                self?.flipping = false
                self?.homeContainer = controller.view
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
            let controller = storyboard!.instantiateViewController(withIdentifier: "Game")
            addChild(controller)
            controller.view.translatesAutoresizingMaskIntoConstraints = false

            UIView.transition(from: homeContainer, to: controller.view, duration: 1, options: [.transitionFlipFromRight], completion: { [weak self] _ in
                self?.inGame = true
                self?.flipping = false
                self?.homeContainer = controller.view
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
