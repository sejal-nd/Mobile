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
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var cardViewTopConstraint: NSLayoutConstraint!
    
    // TODO
    // - fix tableview scroll on bottom sheet scroll up
    
    
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
                
                tableView.isScrollEnabled = true
            case .half:
                self.cardViewTopConstraint.constant = self.defaultHeight
                self.locationInView = self.defaultHeight
                
                tableView.isScrollEnabled = false
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
    
    private var accounts = AccountsStore.shared.accounts ?? [Account]()
    
    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureDidOccur(_:)))
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        configureTableView()
        
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

        
        panGesture.delegate = self
        tableView.addGestureRecognizer(panGesture)
        
//        let panGesture2 = UIPanGestureRecognizer(target: self, action: #selector(panGestureDidOccur(_:)))
//        gestureView.addGestureRecognizer(panGesture2)
//
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizer(_:)))
        gestureView.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //
        //        // Make the currently selected account the first item in list
        //        let currentAccount = accounts.remove(at: AccountsStore.shared.currentIndex)
        //        accounts.insert(currentAccount, at: 0)
        //
        //        if StormModeStatus.shared.isOn {
        //            navigationController?.setColoredNavBar()
        //        } else {
        //            navigationController?.setWhiteNavBar()
        //        }
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
        
        // Todo: Remove
        var i = 0
        while i < 20 {
            i += 1
            accounts.append(AccountsStore.shared.accounts.first!)
        }

        tableView.reloadData()

        
    }
    
    // todo: see if we can refactor this back into a container VC
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        guard let vc = segue.destination as? AccountListViewController else { return }
//        accountListViewController = vc
//        print("tableview:\(vc) \(vc.tableView)")
//    }
    
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

    
    var initialTableViewContentOffset: CGFloat = 0
    
    var isOverScroll = false
    
    // need to fix the scrolling, can scroll table view, but only when it is max and it is a very weird interaction
    @objc
    private func panGestureDidOccur(_ gestureRecognizer: UIPanGestureRecognizer) {
        print("Pan gesture called")

        let velocity = gestureRecognizer.velocity(in: tableView)
        let state = gestureRecognizer.state
        
        if gestureRecognizer.state == .began {
            // Capture table content offset, prevents jump animation
            initialTableViewContentOffset = tableView.contentOffset.y
        }
        
        switch state {
        case .began, .changed:
            print("Gesture began or changed")
            
            guard let originView = gestureRecognizer.view else { return }
            switch originView {
            case tableView:
                // why does the table view not scroll even when it hits the if statement... makes no sense!
                // is sliderState == .open neccissary?
                if tableView.contentOffset.y > 0 && velocity.y >= 0 && sliderState == .open || (tableView.contentOffset.y >= 0 && isOverScroll) {//  {//&& sliderState == .open {// || tableView.contentOffset.y >= 0 && isOverScroll {// || isOverScroll { // need to take into account direction of gesture
                    
                    // Return from pan gesture: vanilla table view scroll
                    //let trans = gestureRecognizer.translation(in: tableView)
                    //self.tableView.contentOffset.y = trans.y
                    
                    // Test
//                    let translation = gestureRecognizer.translation(in: self.view)
//                    let newLocation = locationInView + translation.y - initialTableViewContentOffset
//                    self.tableView.contentOffset.y = newLocation
                    
                    print("Allow TableView to scroll")
                    let translation2 = gestureRecognizer.translation(in: self.view)
                    print("Metrics: \(translation2.y)...\(tableView.contentOffset.y)...\(tableView.isScrollEnabled)")
                    
                    // why is the table view not scrolling here?  We have set the gestures to recognize simulatneously...
                    
                    print("Test")
                    return
                } else {
                    print("Do not allow tableview to scroll")
                }
            default:
                break
            }

            let translation = gestureRecognizer.translation(in: self.view)
            let newLocation = locationInView + translation.y - initialTableViewContentOffset

            // Animate bottom sheet
            if newLocation > 0 {
                isOverScroll = false

                print("Bottom Sheet Animate")
                print("Metrics (Bottom Sheet): \(translation.y)...\(tableView.contentOffset.y)...\(newLocation)")
                
                tableView.isScrollEnabled = false
                UIView.animate(withDuration: 0.1) { [unowned self] in
                    self.cardViewTopConstraint.constant = newLocation
                }
            } else {
                // WIP
                isOverScroll = true
                tableView.isScrollEnabled = true
                print("Do not animate bottom sheet")
            }
        case .ended:
            print("Pan Gesture Ended")
            let endingLocationInView = cardViewTopConstraint.constant
            
            // Commit the desired state of bottom sheet
            // the signs here are VERY CONFUSING we need to make this code more legible....
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
    
    private func configureTableView() {
        tableView.isScrollEnabled = false
        tableView.tableFooterView = UIView()
    }
    
    func present() {
        UIView.animate(withDuration: 0.3) { [unowned self] in
            self.backgroundView.alpha = 1.0
        }
        
        sliderState = .half
    }
}


// MARK: - Table View Delegate

extension AccountSheetViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let account = accounts[indexPath.row]
        if account.isMultipremise {
            let cell = tableView.cellForRow(at: indexPath) as! AccountListRow
            cell.didPress()
            tableView.beginUpdates()
            tableView.endUpdates()
        } else {
            self.exitWith(selectedAccount: accounts[indexPath.row])
        }
    }
    
    func exitWith(selectedAccount: Account) {
        dismiss(animated: true, completion: nil)
    }
    
}


// MARK: - Table View Data Source

extension AccountSheetViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AccountListRow.className, for: indexPath) as! AccountListRow
        let account = accounts[indexPath.row]
        cell.configure(withAccount: account)
        return cell
    }
}


// MARK: - UIGestureRecognizerDelegate

extension AccountSheetViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // Determines when to use vanilla tableview gesture or the bottom sheet gesture
    // second tableview recognizer conforms to this
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//
//
//    }
    
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        print("shouldRequireFailure")
//        // if statement to reject gesture.
//        guard let gesture = gestureRecognizer as? UIPanGestureRecognizer else {
//            print("FAILED STATEMENT")
//            return true }
//        let velocity = gesture.velocity(in: tableView)
//        print("Metrics: \(tableView.contentOffset.y)...\n\(velocity.y)\n\(sliderState)\n\(isOverScroll)")
//        if gestureRecognizer == self.panGesture && tableView.contentOffset.y > 0 && velocity.y >= 0 && sliderState == .open || (tableView.contentOffset.y >= 0 && isOverScroll) {
//            print("REJECT")
//            return false
//        }
//        print("ALLOW")
//        return true
//    }
}
