//
//  AccountListViewController.swift
//  XibTest
//
//  Created by Joseph Erlandson on 6/12/19.
//  Copyright © 2019 Exelon Corp. All rights reserved.
//

import UIKit

class AccountSheetViewController: UIViewController {
    
    enum SheetLevel {
        case top
        case middle
        case closed
    }
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var gestureView: UIView!
    @IBOutlet weak var handleView: UIView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var cardViewTopConstraint: NSLayoutConstraint!

    // this does not recalculate on device rotation, especially problematic for iPad?
    var defaultHeight = UIScreen.main.bounds.height * 0.55
    
    /// Determines when to "snap" to the top or middle state
    let threshHoldTop = UIScreen.main.bounds.height * 0.3
    /// Determines when to "snap" to the middle or closed state
    let threshHoldClosed = UIScreen.main.bounds.height * 0.7
    
    /// The current Y location of cardView
    var locationInView: CGFloat!
    
    /// Determines location of cardView via cardViewTopConstraint
    var lastSheetLevel: SheetLevel = .middle {
        didSet {
            switch self.lastSheetLevel {
            case .top:
                self.cardViewTopConstraint.constant = 0
                self.locationInView = 0
            case .middle:
                self.cardViewTopConstraint.constant = self.defaultHeight
                self.locationInView = self.defaultHeight
                
                // Reset TableView Content
                self.tableView.contentOffset.y = 0
            case .closed:
                let screenHeight = UIScreen.main.bounds.height
                self.cardViewTopConstraint.constant = screenHeight
                self.locationInView = screenHeight
            }
            
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.9, options: .curveEaseOut, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
            
            guard lastSheetLevel == .closed else { return }
            UIView.animate(withDuration: 0.3, animations: { [unowned self] in
                self.backgroundView.alpha = 0.0
                }, completion: { [unowned self] _ in
                    self.dismiss(animated: false, completion: nil)
            })
        }
    }
    
    private var accounts = AccountsStore.shared.accounts ?? [Account]()
    
    var shouldDisableTableScrolling = false

    var initialTableViewContentOffset: CGFloat = 0

    
    
    // MARK: - View Life Cycle
    
    // todo this can cash if accounts store has not loaded in yet -> STORM MODE.
    override func viewDidLoad() {
        super.viewDidLoad()

        configureCardView()
        
        configureTableView()
        
        configureGestures()
        
        // Start with view hidden
        // This is does not react to screen rotation, it should...
        let screenHeight = self.view.bounds.height//UIScreen.main.bounds.height
        self.cardViewTopConstraint.constant = screenHeight
        self.locationInView = screenHeight
        
        
    }

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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        defaultHeight = UIScreen.main.bounds.height * 0.55
        
        if lastSheetLevel == .middle {
            lastSheetLevel = .middle
        }
    }

    deinit {
        print("deinit")
    }
    
    
    // MARK: - Actions

    @objc
    private func backgroundTapGesture(_ gestureRecognizer: UIGestureRecognizer) {
        lastSheetLevel = .closed
    }
    
    @objc
    private func tapGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        lastSheetLevel = lastSheetLevel == .middle ? .top : .middle
    }

    
    // MARK: - Handle gestures
    
    // Prevents TableView from scrolling
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == tableView, shouldDisableTableScrolling else { return }
        tableView.contentOffset.y = 0
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView == tableView, shouldDisableTableScrolling else { return }
        targetContentOffset.pointee = scrollView.contentOffset
        shouldDisableTableScrolling = false
    }
    
    
    @objc
    private func panGestureDidOccur(_ gestureRecognizer: UIPanGestureRecognizer) {
        print("Pan gesture called")

        guard let originView = gestureRecognizer.view else { return }
        let velocityY = gestureRecognizer.velocity(in: tableView).y
        let state = gestureRecognizer.state
        
        switch state {
        case .began:
            // Capture table content offset, prevents jump animation
            if originView == tableView {
                initialTableViewContentOffset = tableView.contentOffset.y
            } else {
                initialTableViewContentOffset = 0
            }
        case .changed:
            let translation = gestureRecognizer.translation(in: cardView)
            var newLocation = locationInView + translation.y - initialTableViewContentOffset
            
            // Determine which view to animate: Table or Sheet
            let shouldAnimateCardView: Bool
            if (tableView.contentOffset.y >= 0 && velocityY <= 0 && cardViewTopConstraint.constant < 0 && originView == tableView) || (velocityY >= 0 && tableView.contentOffset.y >= 0 && originView == tableView) {
                shouldDisableTableScrolling = false
                shouldAnimateCardView = false // allow table scrolling
            } else {
                shouldDisableTableScrolling = true
                shouldAnimateCardView = true
            }

            print("newLocation: \(newLocation)")
            print("Constant: \(cardViewTopConstraint.constant)")
            // Animate bottom sheet
            if shouldAnimateCardView {
                UIView.animate(withDuration: 0.1) { [unowned self] in
                    // Normalize gesture - User could pan from say 2 -> -1 and thus would be stuck at a 2 constraint
                    if newLocation < 3 {
                        newLocation = 0
                    }
                    self.cardViewTopConstraint.constant = newLocation
                }
            }
        case .ended, .failed, .cancelled:
            // Commit the desired state of bottom sheet
            let endingLocationInView = cardViewTopConstraint.constant
            
            // the signs here are VERY CONFUSING we need to make this code more legible....
            if endingLocationInView < threshHoldTop {
                lastSheetLevel = .top
            } else if endingLocationInView > threshHoldTop && endingLocationInView < defaultHeight || endingLocationInView > defaultHeight  && endingLocationInView < threshHoldClosed {
                lastSheetLevel = .middle
            } else {
                lastSheetLevel = .closed
            }
        default:
            break
        }
    }
    
    
    // MARK: - Helper
    
    private func configureCardView() {
        cardView.roundCorners([.topLeft, .topRight], radius: 10.0)
        cardView.layer.masksToBounds = true
        
        handleView.layer.cornerRadius = handleView.bounds.height / 2
    }
    
    private func configureTableView() {
        tableView.tableFooterView = UIView()
    }
    
    private func configureGestures() {
        // Background Dismiss
        let backgroundTapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapGesture(_:)))
        backgroundView.addGestureRecognizer(backgroundTapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureDidOccur(_:)))
        panGesture.delegate = self
        gestureView.addGestureRecognizer(panGesture)
        
        tableView.panGestureRecognizer.addTarget(self, action: #selector(panGestureDidOccur(_:)))
        
        // Tap to Toggle Sheet
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizer(_:)))
        tapGesture.delegate = self
        gestureView.addGestureRecognizer(tapGesture)
    }
    
    private func present() {
        UIView.animate(withDuration: 0.3) { [unowned self] in
            self.backgroundView.alpha = 1.0
        }
        
        lastSheetLevel = .middle
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
            // todo trigger delegate ect...
            lastSheetLevel = .closed
        }
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
}
