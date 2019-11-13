//
//  GameOnboardingStep2ViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/13/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class GameOnboardingStep2ViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var rentOrOwnLabel: UILabel!
    @IBOutlet weak var button1: ButtonControl!
    @IBOutlet weak var button1Label: UILabel!
    @IBOutlet weak var button2: ButtonControl!
    @IBOutlet weak var button2Label: UILabel!
    @IBOutlet weak var doneButton: PrimaryButton!
    
    let selectedButton = BehaviorRelay<ButtonControl?>(value: nil)
    
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.textColor = .deepGray
        titleLabel.font = OpenSans.semibold.of(size: 15)
        titleLabel.text = NSLocalizedString("Step 2 of 2", comment: "")
        
        rentOrOwnLabel.textColor = .deepGray
        rentOrOwnLabel.font = OpenSans.semibold.of(textStyle: .title3)
        rentOrOwnLabel.text = NSLocalizedString("Do you rent or own your home?", comment: "")
        
        button1.layer.borderWidth = 1
        button1.layer.borderColor = UIColor.accentGray.cgColor
        button1.layer.cornerRadius = 10
        
        button2.layer.borderWidth = 1
        button2.layer.borderColor = UIColor.accentGray.cgColor
        button2.layer.cornerRadius = 10
        
        button1Label.textColor = .deepGray
        button1Label.font = OpenSans.regular.of(textStyle: .headline)
        button1Label.text = NSLocalizedString("I own my home.", comment: "")
        
        button2Label.textColor = .deepGray
        button2Label.font = OpenSans.regular.of(textStyle: .headline)
        button2Label.text = NSLocalizedString("I rent my home.", comment: "")

        selectedButton.asDriver().isNil().not().drive(doneButton.rx.isEnabled).disposed(by: bag)
    }
    
    @IBAction func onBackPress() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onButtonPress(_ sender: ButtonControl) {
        resetAllButtons()
        
        sender.layer.borderWidth = 2
        sender.layer.borderColor = UIColor.actionBlue.cgColor
        
        let label = sender === button1 ? button1Label : button2Label
        label?.textColor = .actionBlue
        label?.font = OpenSans.semibold.of(textStyle: .headline)
        
        selectedButton.accept(sender)
    }
    
    
    @IBAction func onDonePress() {
        // TODO: Analytics event
        // TODO: Post their selected answer to server
        
        NotificationCenter.default.post(name: .gameOnboardingComplete, object: nil)
        dismissModal()
    }
    
    private func resetAllButtons() {
        button1.layer.borderWidth = 1
        button1.layer.borderColor = UIColor.accentGray.cgColor
        button2.layer.borderWidth = 1
        button2.layer.borderColor = UIColor.accentGray.cgColor
        button1Label.textColor = .deepGray
        button1Label.font = OpenSans.regular.of(textStyle: .headline)
        button2Label.textColor = .deepGray
        button2Label.font = OpenSans.regular.of(textStyle: .headline)
    }
    
    
}
