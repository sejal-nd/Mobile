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
            UIView.transition(from: gameContainer, to: homeContainer, duration: 1, options: [.transitionFlipFromRight, .showHideTransitionViews], completion: { [weak self] _ in
                self?.inGame = false
                self?.flipping = false
            })
        } else {
            UIView.transition(from: homeContainer, to: gameContainer, duration: 1, options: [.transitionFlipFromRight, .showHideTransitionViews], completion: { [weak self] _ in
                self?.inGame = true
                self?.flipping = false
            })
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
