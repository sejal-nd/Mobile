//
//  AccountListViewController.swift
//  XibTest
//
//  Created by Joseph Erlandson on 6/12/19.
//  Copyright © 2019 Exelon Corp. All rights reserved.
//

import UIKit

class AccountSheetViewController: UIViewController {
    
    // perhaps we use a bool since our 2 valid states are open / half, since closed would dismiss the entire VC
    enum SliderState {
        case open
        case half
        case closed
    }
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var gestureView: UIView!
    @IBOutlet weak var handleView: UIView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    //    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var cardViewTopConstraint: NSLayoutConstraint!
    
    var accountListViewController: AccountListViewController!
    
    // maybe: fix the dismiss animation so the view goes complete off screen
    // implement table View
        // 1.  Inspect how it is currently handled in alert preferences
        // 2.  rework both account table view cells
            // add carrot to main table view cell
            // change press action on main cell if it is multi premise
    
    
    // ***** Leaning towards this option******
    // Table View Other Option
        // Table View cell that is the account table view cell....
        // Nested with another non scrolling table view cell
    // stack view to show/hide the tableView based on: hasUser toggled carrot and hasMultiPremise.
    
    // Fully recreate detail table view cell
    
    
    // implement top over-scroll to dismiss ???? STRETCH
    // This means from collapsed state the user should be able to drag from anywhere on the screen to move the card view, not just the top gesture view.
    
    
    
    /// The default height of the card view (Height of half state)
    let defaultHeight = UIScreen.main.bounds.height * 0.55
    
    /// Determines when to "snap" to the open or half state
    let threshHoldOpen = UIScreen.main.bounds.height * 0.3
    /// Determines when to "snap" to the half or closed state
    let threshHoldClosed = UIScreen.main.bounds.height * 0.7
    
    /// The current Y location of cardView
    var locationInView: CGFloat!
    
    /// Determines location of cardView via cardViewTopConstraint
    var sliderState: SliderState = .half {
        didSet {
            switch self.sliderState {
            case .open:
                self.cardViewTopConstraint.constant = 0
                self.locationInView = 0
                
                accountListViewController.isScrollEnabled = true
            case .half:
                self.cardViewTopConstraint.constant = self.defaultHeight
                self.locationInView = self.defaultHeight
                
                accountListViewController.isScrollEnabled = false
            case .closed:
                let screenHeight = UIScreen.main.bounds.height
                self.cardViewTopConstraint.constant = screenHeight
                self.locationInView = screenHeight
            }
            
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.25, options: .curveEaseInOut, animations: { [unowned self] in
                self.view.layoutIfNeeded()
                }, completion: nil)
            
            guard sliderState == .closed else { return }
            UIView.animate(withDuration: 0.3, animations: { [unowned self] in
                self.backgroundView.alpha = 0.0
                }, completion: { [unowned self] _ in
                    self.dismiss(animated: false, completion: nil)
            })
        }
    }
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Start with view hidden
        let screenHeight = UIScreen.main.bounds.height
        self.cardViewTopConstraint.constant = screenHeight
        self.locationInView = screenHeight
        
        cardView.layer.cornerRadius = 10
        if #available(iOS 11.0, *) {
            cardView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        } else {
            // todo
            // Fallback on earlier versions
        }
        cardView.layer.masksToBounds = true
        
        handleView.layer.cornerRadius = handleView.bounds.height / 2
        
        let backgroundTapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapGesture(_:)))
        backgroundView.addGestureRecognizer(backgroundTapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureDidOccur(_:)))
        gestureView.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizer(_:)))
        gestureView.addGestureRecognizer(tapGesture)
    }
    
    // Logic for advanced account picker presentation
    
    
//    let vc = AdvancedAccountPickerViewController()
//    vc.delegate = self
//    vc.accounts = accounts
//    if let parentVc = parentViewController {
//        if UIDevice.current.userInterfaceIdiom == .pad {
//            vc.modalPresentationStyle = .formSheet
//            parentVc.present(vc, animated: true, completion: nil)
//        } else {
//            parentVc.navigationController?.pushViewController(vc, animated: true)
//        }
//    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        present()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? AccountListViewController else { return }
        accountListViewController = vc
    }
    
    deinit {
        print("deinit")
    }
    
    
    // MARK: - Actions
    
    // FIXME: delete after implementation
    @IBAction func tempToggle(_ sender: Any) {
        sliderState = .closed
    }
    
    @objc
    private func backgroundTapGesture(_ gestureRecognizer: UIGestureRecognizer) {
        sliderState = .closed
    }
    
    @objc
    private func tapGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        sliderState = sliderState == .half ? .open : .half
    }
    
    @objc
    private func panGestureDidOccur(_ gestureRecognizer: UIPanGestureRecognizer) {
        let state = gestureRecognizer.state
        
        switch state {
        case .began, .changed:
            let translation = gestureRecognizer.translation(in: self.view)
            let newLocation = locationInView + translation.y
            
            print("newLocationInView: \(newLocation)")
            
            if newLocation > 0 {
                UIView.animate(withDuration: 0.1) { [unowned self] in
                    self.cardViewTopConstraint.constant = newLocation
                }
            }
        case .ended:
            let endingLocationInView = cardViewTopConstraint.constant
            
            // the signs here are VERY CONFUSING we need to 1.  figure them out, and 2.  make this code more legible....
            if endingLocationInView < threshHoldOpen {
                sliderState = .open
            } else if endingLocationInView > threshHoldOpen && endingLocationInView < defaultHeight || endingLocationInView > defaultHeight  && endingLocationInView < threshHoldClosed {
                sliderState = .half
            } else {
                sliderState = .closed
            }
        default:
            break
        }
        
    }
    
    
    // MARK: - Helper
    
    func present() {
        UIView.animate(withDuration: 0.3) { [unowned self] in
            self.backgroundView.alpha = 1.0
        }
        
        sliderState = .half
    }
    
    // i dont think swipe direction even matters in this instance
    //            if velocity.y < 0 {
    //                // Swipe Up
    //
    //                // is the current location > the 0.3 threshhold? if so, open fully, else collapse back to half state
    //
    //                // something to keep in mind, does the constraint system map directly to screen height system?..... UNSURE...
    //                if endingLocationInView < threshHoldOpen {
    //                    setAccountListSliderState(.open)
    //                } else {
    //                    setAccountListSliderState(.half)
    //                }
    //
    //
    //                // User must be trying to open the fully open state
    //            } else {
    //                // Swipe Down
    //
    //
    //                if endingLocationInView > threshHoldOpen && endingLocationInView < threshHoldClosed {
    //                    setAccountListSliderState(.half)
    //                } else {
    //                    setAccountListSliderState(.closed)
    //                }
    //
    //                // User is either trying to collapse to half way, or the user is trying to collapse to empty
    //            }
    
    // this will actually change based on the enum state that ends up being set
    
    
    
    
    // previously used before we implemented enum state.
    //            locationInView = endingLocationInView
    
    
    
    
    
    // based on value:
    //            setAccountListSliderState(.half)
    
    
    
    //        if gestureRecognizer.state == UIGestureRecognizer.State.began || gestureRecognizer.state == UIGestureRecognizer.State.changed {
    //            //optionsOpenedConstraint.isActive = false
    //            //optionsVisiableConstraint.isActive = false
    //            let translation = gestureRecognizer.translation(in: self.view)
    //            if((distanceFromBottom - translation.y) < 100) {
    //                gestureRecognizer.view!.center = CGPoint(x: gestureRecognizer.view!.center.x, y: gestureRecognizer.view!.center.y + translation.y)
    //                gestureRecognizer.setTranslation(CGPoint(x: 0, y: 0), in: self.view)
    //            }
    //
    //        }
    //        if gestureRecognizer.state == UIGestureRecognizer.State.ended{
    //            if distanceFromBottom > 6{
    //                openOptionsPanel()
    //            }else{
    //                closeOptionsPanel()
    //            }
    //        }
    
    //    private func setAccountListSliderState(_ sliderState: SliderState = .half) {
    //        // why is this being triggered twice?
    //        switch sliderState {
    //        case .open:
    //            print("OPEN")
    //            cardViewTopConstraint.constant = 0
    //            locationInView = 0
    //        case .half:
    //            print("HALF")
    //            cardViewTopConstraint.constant = defaultHeight
    //            locationInView = defaultHeight
    //            break
    //        case .closed:
    //            print("DISMISS VIEW")
    //
    //            // need to figure out a way to get this view completely off screen.
    //            //cardViewTopConstraint.constant = UIScreen.main.bounds.height + 50
    //            // dismiss view.
    //            break
    //        }
    //    }
    
}
