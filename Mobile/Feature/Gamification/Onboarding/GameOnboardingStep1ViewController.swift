//
//  GameOnboardingStep1ViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/13/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class GameOnboardingStep1ViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var howDoYouFeelLabel: UILabel!
    @IBOutlet weak var button1: ButtonControl!
    @IBOutlet weak var button1Label: UILabel!
    @IBOutlet weak var button2: ButtonControl!
    @IBOutlet weak var button2Label: UILabel!
    @IBOutlet weak var button3: ButtonControl!
    @IBOutlet weak var button3Label: UILabel!
    @IBOutlet weak var continueButton: PrimaryButton!
    
    let selectedButton = BehaviorRelay<ButtonControl?>(value: nil)
    
    let bag = DisposeBag()
    
    var accountDetail: AccountDetail! // Passed from GameOnboardingIntroViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.textColor = .deepGray
        titleLabel.font = OpenSans.semibold.of(size: 15)
        titleLabel.text = NSLocalizedString("Step 1 of 2", comment: "")
        
        howDoYouFeelLabel.textColor = .deepGray
        howDoYouFeelLabel.font = OpenSans.semibold.of(textStyle: .title3)
        howDoYouFeelLabel.text = NSLocalizedString("How do you feel about your energy usage?", comment: "")
        
        button1.layer.borderWidth = 1
        button1.layer.borderColor = UIColor.accentGray.cgColor
        button1.layer.cornerRadius = 10
        
        button2.layer.borderWidth = 1
        button2.layer.borderColor = UIColor.accentGray.cgColor
        button2.layer.cornerRadius = 10
        
        button3.layer.borderWidth = 1
        button3.layer.borderColor = UIColor.accentGray.cgColor
        button3.layer.cornerRadius = 10
        
        button1Label.textColor = .deepGray
        button1Label.font = OpenSans.regular.of(textStyle: .headline)
        button1Label.text = NSLocalizedString("I've got it under control.", comment: "")
        
        button2Label.textColor = .deepGray
        button2Label.font = OpenSans.regular.of(textStyle: .headline)
        button2Label.text = NSLocalizedString("I think I can do better.", comment: "")
        
        button3Label.textColor = .deepGray
        button3Label.font = OpenSans.regular.of(textStyle: .headline)
        button3Label.text = NSLocalizedString("I really need help.", comment: "")
        
        selectedButton.asDriver().isNil().not().drive(continueButton.rx.isEnabled).disposed(by: bag)
    }
    
    @IBAction func onBackPress() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onButtonPress(_ sender: ButtonControl) {
        resetAllButtons()
        
        sender.layer.borderWidth = 2
        sender.layer.borderColor = UIColor.actionBlue.cgColor
        
        var label: UILabel
        if sender == button1 {
            label = button1Label
        } else if sender == button2 {
            label = button2Label
        } else {
            label = button3Label
        }
        label.textColor = .actionBlue
        label.font = OpenSans.semibold.of(textStyle: .headline)
        
        selectedButton.accept(sender)
    }
    
    @IBAction func onContinuePress() {
        performSegue(withIdentifier: "goToStep2", sender: self)
    }
    
    private func resetAllButtons() {
        button1.layer.borderWidth = 1
        button1.layer.borderColor = UIColor.accentGray.cgColor
        button2.layer.borderWidth = 1
        button2.layer.borderColor = UIColor.accentGray.cgColor
        button3.layer.borderWidth = 1
        button3.layer.borderColor = UIColor.accentGray.cgColor
        button1Label.textColor = .deepGray
        button1Label.font = OpenSans.regular.of(textStyle: .headline)
        button2Label.textColor = .deepGray
        button2Label.font = OpenSans.regular.of(textStyle: .headline)
        button3Label.textColor = .deepGray
        button3Label.font = OpenSans.regular.of(textStyle: .headline)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let step2 = segue.destination as? GameOnboardingStep2ViewController {
            var selectedResponse: String?
            switch selectedButton.value {
            case button1:
                selectedResponse = button1Label.text
            case button2:
                selectedResponse = button2Label.text
            default:
                selectedResponse = button3Label.text
            }
            step2.step1Response = selectedResponse!
            step2.accountDetail = accountDetail
        }
    }
    
    
}
