//
//  GameOptInOutViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/22/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

protocol GameOptInOutViewControllerDelegate: class {
    func gameOptInOutViewController(_ gameOptInOutViewController: GameOptInOutViewController, didOptOut: Bool)
}

class GameOptInOutViewController: UIViewController {
    
    weak var delegate: GameOptInOutViewControllerDelegate?
    
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stickyFooterView: StickyFooterView!
    @IBOutlet var bulletPoints: [UIView]!
    @IBOutlet var labels: [UILabel]!
    @IBOutlet weak var optInOutButton: PrimaryButton!
    
    let gameService = ServiceFactory.createGameService()
    
    let bag = DisposeBag()
    
    let gameAccountNumber = UserDefaults.standard.string(forKey: UserDefaultKeys.gameAccountNumber)! // Can't get to this screen if nil
    var optedOut = false

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("BGE's Play-n-Save Pilot", comment: "")

        for bullet in bulletPoints {
            bullet.backgroundColor = .primaryColor
            bullet.layer.cornerRadius = 2.5
        }
        
        for label in labels {
            label.textColor = .deepGray
            label.font = SystemFont.regular.of(textStyle: .body)
        }
        
        scrollView.isHidden = true
        stickyFooterView.isHidden = true
        gameService.fetchGameUser(accountNumber: gameAccountNumber)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] user in
                guard let self = self, let gameUser = user else { return }
                self.loadingIndicator.isHidden = true
                
                self.optedOut = gameUser.optedOut
                let title = self.optedOut ? NSLocalizedString("Turn On This Feature", comment: "") :
                    NSLocalizedString("Turn Off This Feature", comment: "")
                UIView.performWithoutAnimation { // Prevents ugly setTitle animation
                    self.optInOutButton.setTitle(title, for: .normal)
                    self.optInOutButton.layoutIfNeeded()
                }
                
                self.scrollView.isHidden = false
                self.stickyFooterView.isHidden = false
            }, onError: { _ in
                self.loadingIndicator.isHidden = true
            }).disposed(by: bag)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @IBAction func onOptInOutPress() {
        let updateGameUser = {
            LoadingView.show()
            let optObject = ["optedOut": !self.optedOut]
            self.gameService.updateGameUser(accountNumber: self.gameAccountNumber, keyValues: optObject)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] gameUser in
                    LoadingView.hide()
                    guard let self = self else { return }
                    
                    if gameUser.optedOut {
                        FirebaseUtility.logEvent(.gamificationOptOut, customParameters: [
                            "current_point_total": UserDefaults.standard.double(forKey: UserDefaultKeys.gamePointsLocal)
                        ])
                        NotificationCenter.default.post(name: .gameDidOptOut, object: nil)
                        UNUserNotificationCenter.current().removeAllPendingNotificationRequests() // Ditch all reminder notifications
                    } else {
                        FirebaseUtility.logEvent(.gamification, parameters: [EventParameter(parameterName: .action, value: .opt_in)])
                        RxNotifications.shared.accountDetailUpdated.onNext(()) // So that home reloads and onboarding card shows/hides
                    }
                    
                    self.delegate?.gameOptInOutViewController(self, didOptOut: gameUser.optedOut)
                    self.navigationController?.popViewController(animated: true)
                }, onError: { [weak self] err in
                    LoadingView.hide()
                    let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""),
                                                  message: err.localizedDescription,
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                }).disposed(by: self.bag)
        }
        
        if !optedOut {
            let confirmAlert = UIAlertController(title: NSLocalizedString("Are you sure?", comment: ""),
                                                 message: NSLocalizedString("Are you sure you want to turn off this experience?", comment: ""),
                                                 preferredStyle: .alert)
            confirmAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            confirmAlert.addAction(UIAlertAction(title: NSLocalizedString("Turn Off", comment: ""), style: .default, handler: { _ in
                updateGameUser()
            }))
            present(confirmAlert, animated: true, completion: nil)
        } else {
            updateGameUser()
        }
    }
    
}
