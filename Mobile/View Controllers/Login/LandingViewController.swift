//
//  LandingViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa

class LandingViewController: UIViewController {
    
    let disposeBag = DisposeBag()

    @IBOutlet weak var signInButton: SecondaryButton!
    @IBOutlet weak var orLabel: UILabel!
    @IBOutlet weak var registerButton: SecondaryButton!
    @IBOutlet weak var continueAsGuestButon: UIButton!
    @IBOutlet weak var tabletView: UIView!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var videoView: UIView!
    
    var playerLayer: AVPlayerLayer!
    var avPlayer: AVPlayer!
    
    var viewDidAppear = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundVideoSetup()

        signInButton.setTitle(NSLocalizedString("Sign In", comment: ""), for: .normal)
        orLabel.text = NSLocalizedString("OR", comment: "")
        registerButton.setTitle(NSLocalizedString("Register", comment: ""), for: .normal)
        continueAsGuestButon.setTitle(NSLocalizedString("CONTINUE AS GUEST", comment: ""), for: .normal)

        orLabel.font = SystemFont.regular.of(textStyle: .headline)
        continueAsGuestButon.titleLabel?.font = SystemFont.bold.of(textStyle: .title1)

        view.backgroundColor = .primaryColor
        
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            versionLabel.text = String(format: NSLocalizedString("Version %@", comment: ""), version)
        } else {
            versionLabel.text = nil
        }
        
        versionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        
        videoView.alpha = 0
        tabletView.alpha = 0
        versionLabel.alpha = 0
    }
    
    func backgroundVideoSetup() {
        view.sendSubview(toBack: videoView)
        let movieUrl = URL(fileURLWithPath: Bundle.main.path(forResource: "landing_video", ofType: "mp4")!)
        let asset = AVAsset(url: movieUrl)
        let avPlayerItem = AVPlayerItem(asset: asset)
        avPlayer = AVPlayer(playerItem: avPlayerItem)
        avPlayer.isMuted = true
        playerLayer = AVPlayerLayer(player: avPlayer)
        playerLayer.videoGravity = .resizeAspectFill
        
        let videoWidth: CGFloat
        let videoHeight: CGFloat
        if UI_USER_INTERFACE_IDIOM() == .pad {
            let widthAndHeight = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
            videoWidth = widthAndHeight
            videoHeight = widthAndHeight
        } else {
            videoWidth = UIScreen.main.bounds.width
            videoHeight = UIScreen.main.bounds.height
        }
        playerLayer.frame = CGRect(x: 0, y: 0, width: videoWidth, height: videoHeight)
        videoView.layer.addSublayer(playerLayer)
        
        avPlayer.seek(to: kCMTimeZero)
        avPlayer.actionAtItemEnd = .none
        
        NotificationCenter.default.rx.notification(.AVPlayerItemDidPlayToEndTime)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: {
                ($0.object as? AVPlayerItem)?.seek(to: kCMTimeZero)
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(.UIApplicationDidBecomeActive)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] _ in
                self?.avPlayer.play()
            })
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        avPlayer.play()
        
        if (!UserDefaults.standard.bool(forKey: UserDefaultKeys.HasAcceptedTerms)) {
            performSegue(withIdentifier: "termsPoliciesModalSegue", sender: self)
        }
        
        if !viewDidAppear {
            viewDidAppear = true
            UIView.animate(withDuration: 0.5) {
                self.videoView.alpha = 1
                self.tabletView.alpha = 1
                self.versionLabel.alpha = 1
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        avPlayer.pause()
    }
    
    @IBAction func onContinueAsGuestPress(_ sender: UIButton) {
        performSegue(withIdentifier: "UnauthenticatedUserSegue", sender: self)
    }
    
    @IBAction func onSignInPress() {
        performSegue(withIdentifier: "loginSegue", sender: self)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
 
}
