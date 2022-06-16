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
    var transferEligibility: TransferEligibility!
    var moveResponse: MoveServiceResponse?

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
            
            #warning("todo, implement seamless move eligability after the review screen, and add seamless move parameters into move service?")
            MoveService.moveService(moveFlowData: moveFlowData) { [weak self] (result: Result<MoveServiceResponse, NetworkingError>) in
                guard let `self` = self else { return }
                switch result {
                case .success(let moveResponse):
                    FirebaseUtility.logEvent(.authMoveService(parameters: [moveResponse.isResolved == true ? .complete_resolved : .complete_unresolved]))

                    self.moveResponse = moveResponse
                    self.performSegue(withIdentifier: "showComplete", sender: nil)
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

extension TerminateAgreementViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? MoveServiceConfirmationViewController,
              let moveResponse = moveResponse else {
                  return
              }
            vc.viewModel = MoveServiceConfirmationViewModel(moveServiceResponse: moveResponse,
                                                            isUnauth: false,
                                                            shouldShowSeamlessMove: true,
                                                            transferEligibility: transferEligibility,
                                                            transferOption: .doNotTransfer)
    }
}
