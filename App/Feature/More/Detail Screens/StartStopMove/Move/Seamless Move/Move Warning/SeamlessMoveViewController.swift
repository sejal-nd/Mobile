//
//  SeamlessMoveViewController.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 5/17/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import UIKit
import SwiftUI

class SeamlessMoveViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var stickyFooterView: StickyFooterView!
    @IBOutlet weak var ctaButton: PrimaryButton!
    
    var childView: UIHostingController<SeamlessMoveWarningView>? = nil// = UIHostingController(rootView: SeamlessMoveWarningView())
        
    private var transferOption: TransferServiceOption = .transfer
    
    var moveFlowData: MoveServiceFlowData!
    var moveResponse: MoveServiceResponse?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Third Party Supplier Update", comment: "")
        
        addHostingController()
    }
    
    private func addHostingController() {
        let seamlessMoveView = SeamlessMoveWarningView(stopServiceAddress: moveFlowData.currentPremise?.addressGeneral ?? "",
                                                       startServiceAddress: generateStartServiceAddress(),
                                                       didSelectRadioButton: didSelectRadioButton)
        childView = UIHostingController(rootView: (seamlessMoveView))
                
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
    
    private func generateStartServiceAddress() -> String {
        guard let startAddress = moveFlowData.addressLookupResponse?.first else { return "" }
        return startAddress.compressedAddress
    }
    
    private func didSelectRadioButton(transferOption: TransferServiceOption) {
        self.transferOption = transferOption
        switch transferOption {
        case .transfer:
            ctaButton.setTitle("Submit", for: .normal)
        case .doNotTransfer:
            ctaButton.setTitle("Continue", for: .normal)
        }
    }
    
    // MARK: Action
    
    @IBAction func ctaButtonPress(_ sender: Any) {
        switch transferOption {
        case .transfer:
            ctaButton.setLoading()
            
            #warning("todo, implement seamless move eligability after the review screen, and add seamless move parameters into move service?")
            MoveService.moveService(moveFlowData: moveFlowData) { [weak self] (result: Result<MoveServiceResponse, NetworkingError>) in
                guard let `self` = self else { return }
                switch result {
                case .success(let moveResponse):
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
        case .doNotTransfer:
            performSegue(withIdentifier: "showTerminationAgreement", sender: nil)
        }
    }
    
}

extension SeamlessMoveViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? TerminateAgreementViewController {
            vc.moveFlowData = moveFlowData
            vc.transferEligibility = .eligible
        } else if let vc = segue.destination as? MoveServiceConfirmationViewController,
                  let moveResponse = moveResponse {
            vc.viewModel = MoveServiceConfirmationViewModel(moveServiceResponse: moveResponse,
                                                            isUnauth: false,
                                                            shouldShowSeamlessMove: true,
                                                            transferEligibility: .eligible,
                                                            transferOption: transferOption)
        }
    }
}
