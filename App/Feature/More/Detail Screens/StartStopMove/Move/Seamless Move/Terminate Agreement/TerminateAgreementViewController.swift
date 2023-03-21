//
//  TerminateAgreementViewController.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 5/19/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import UIKit
import SwiftUI

class TerminateAgreementViewController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var stickyFooterView: StickyFooterView!
    @IBOutlet weak var ctaButton: PrimaryButton!
    
    private var childView: UIHostingController<TerminateAgreementView>? = nil
    
    var moveFlowData: MoveServiceFlowData!
    var isUnauth = false
    var transferEligibility: TransferEligibility!
    
    private var hasAgreed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Third Party Agreement", comment: "")
        ctaButton.isEnabled = false
        ctaButton.setTitle(transferEligibility.buttonText, for: .normal)
        
        addHostingController()
    }
    
    private func addHostingController() {
        let terminateAgreementView = TerminateAgreementView(didSelectCheckbox: didSelectCheckbox, transferEligibility: transferEligibility)
        childView = UIHostingController(rootView: (terminateAgreementView))
        
        guard let unwrappedChildView = childView else {
            return
        }
        
        containerView.addSubview(unwrappedChildView.view)
        
        // Set constraints
        unwrappedChildView.view.translatesAutoresizingMaskIntoConstraints = false
        
        
        NSLayoutConstraint.activate([
            unwrappedChildView.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            unwrappedChildView.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            unwrappedChildView.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            unwrappedChildView.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
    }
    
    private func didSelectCheckbox(hasAgreed: Bool) {
        self.hasAgreed = hasAgreed
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.ctaButton.isEnabled = hasAgreed
        }
    }
    
    // MARK: Action
    
    @IBAction func ctaButtonPress(_ sender: Any) {
        if hasAgreed {
            ctaButton.setLoading()
            
            if isUnauth {
                MoveService.moveServiceAnon(moveFlowData: moveFlowData) { [weak self] (result: Result<MoveServiceResponse, NetworkingError>) in
                    guard let `self` = self else { return }
                    switch result {
                    case .success(let moveResponse):
                        FirebaseUtility.logEvent(.authMoveService(parameters: [moveResponse.isResolved == true ? .complete_resolved : .complete_unresolved]))
                        
                        let isUnauth = self.moveFlowData.unauthMoveData?.isUnauthMove ?? false
                        let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
                        let moveServiceConfirmationViewController = storyboard.instantiateViewController(withIdentifier: "MoveServiceConfirmationViewController") as! MoveServiceConfirmationViewController
                        moveServiceConfirmationViewController.viewModel = MoveServiceConfirmationViewModel(moveServiceResponse: moveResponse,
                                                                                                           isUnauth: isUnauth,
                                                                                                           shouldShowSeamlessMove: true,
                                                                                                           transferEligibility: self.transferEligibility,
                                                                                                           transferOption: .doNotTransfer)
                        moveServiceConfirmationViewController.viewModel.unAuthAccountDetail = self.moveFlowData.unauthMoveData?.accountDetails
                        self.navigationController?.pushViewController(moveServiceConfirmationViewController, animated: true)
                    case .failure(let error):
                        FirebaseUtility.logEvent(.authMoveService(parameters: [.complete_unresolved]))
                        
                        let alertVc = UIAlertController(title: error.title, message: error.description, preferredStyle: .alert)
                        alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                        self.present(alertVc, animated: true, completion: nil)
                    }
                    
                    self.ctaButton.reset()
                }
            } else {
                MoveService.moveService(moveFlowData: moveFlowData) { [weak self] (result: Result<MoveServiceResponse, NetworkingError>) in
                    guard let `self` = self else { return }
                    switch result {
                    case .success(let moveResponse):
                        FirebaseUtility.logEvent(.authMoveService(parameters: [moveResponse.isResolved == true ? .complete_resolved : .complete_unresolved]))
                        
                        let isUnauth = self.moveFlowData.unauthMoveData?.isUnauthMove ?? false
                        let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
                        let moveServiceConfirmationViewController = storyboard.instantiateViewController(withIdentifier: "MoveServiceConfirmationViewController") as! MoveServiceConfirmationViewController
                        moveServiceConfirmationViewController.viewModel = MoveServiceConfirmationViewModel(moveServiceResponse: moveResponse,
                                                                                                           isUnauth: isUnauth,
                                                                                                           shouldShowSeamlessMove: true,
                                                                                                           transferEligibility: self.transferEligibility,
                                                                                                           transferOption: .doNotTransfer)
                        moveServiceConfirmationViewController.viewModel.accountDetail = self.moveFlowData.currentAccountDetail
                        self.navigationController?.pushViewController(moveServiceConfirmationViewController, animated: true)
                    case .failure(let error):
                        FirebaseUtility.logEvent(.authMoveService(parameters: [.complete_unresolved]))
                        
                        let alertVc = UIAlertController(title: error.title, message: error.description, preferredStyle: .alert)
                        alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                        self.present(alertVc, animated: true, completion: nil)
                    }
                    
                    self.ctaButton.reset()
                }
            }
        }
    }
}
