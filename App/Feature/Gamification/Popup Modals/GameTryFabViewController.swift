//
//  GameTryFabViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 12/16/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class GameTryFabViewController: UIViewController {
    
    weak var delegate: GameQuizViewControllerDelegate?
    
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel1: UILabel!
    @IBOutlet weak var detailLabel2: UILabel!
    @IBOutlet weak var fabButtonRepresentation: UIView!
    
    static func create() -> GameTryFabViewController {
        let sb = UIStoryboard(name: "Game", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "TryFabPopup") as! GameTryFabViewController
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    
        popupView.layer.cornerRadius = 10
        popupView.layer.masksToBounds = true
        
        closeButton.tintColor = .actionBlue
        closeButton.addTarget(self, action: #selector(dismiss(_:)), for: .touchUpInside)
        
        titleLabel.textColor = .deepGray
        titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        titleLabel.text = NSLocalizedString("Hello!", comment: "")
        
        detailLabel1.textColor = .deepGray
        detailLabel1.font = SystemFont.regular.of(textStyle: .footnote)
        detailLabel1.text = NSLocalizedString("I’m LUMI℠!\n\nI’m here to help you make small changes that lead to big impacts by giving you tips, challenges, and insights to help you lower your energy use.\n\nTo see your old home screen, use the button at the bottom of the previous screen to swap between the two versions. It looks like this:", comment: "")
    
        detailLabel2.textColor = .deepGray
        detailLabel2.font = SystemFont.regular.of(textStyle: .footnote)
        detailLabel2.text = NSLocalizedString("Return to the home screen and try tapping it to receive points toward your first gift!", comment: "")
        
        fabButtonRepresentation.layer.cornerRadius = 27.5
        fabButtonRepresentation.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 5), radius: 10)
        fabButtonRepresentation.backgroundColor = UIColor(red: 17/255, green: 57/255, blue: 112/255, alpha: 1)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismiss(_:)))
        tap.delegate = self
        contentView.addGestureRecognizer(tap)
    }
    
    @objc private func dismiss(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onTryItNowPress() {
        dismiss(self)
    }
}

extension GameTryFabViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == gestureRecognizer.view
    }
}
