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
    
    var childView: UIHostingController<SeamlessMoveWarningView>? = nil
    
    private var transferOption: TransferServiceOption = .transfer
    
    var moveFlowData: MoveServiceFlowData!
    var isUnauth = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Third Party Supplier Update", comment: "")
        
        addHostingController()
    }
    
    private func addHostingController() {
        let seamlessMoveView: SeamlessMoveWarningView
        if let unauthMoveData = moveFlowData.unauthMoveData,
           unauthMoveData.isUnauthMove,
           let unauthAccountDetails = unauthMoveData.accountDetails {
            seamlessMoveView = SeamlessMoveWarningView(stopServiceAddress: "\(unauthAccountDetails.addressLine)",
                                                       stopServiceCountyStateZip: "\(unauthAccountDetails.city), \(unauthAccountDetails.state) \(unauthAccountDetails.zipCode)",
                                                       startServiceAddress: moveFlowData.addressLookupResponse?.first?.address ?? "",
                                                       startServiceCountyStateZip: "\(moveFlowData.addressLookupResponse?.first?.city ?? ""), \(moveFlowData.addressLookupResponse?.first?.state ?? "") \(moveFlowData.addressLookupResponse?.first?.zipCode ?? "")",
                                                       didSelectRadioButton: didSelectRadioButton)
            
        } else {
            seamlessMoveView = SeamlessMoveWarningView(stopServiceAddress: moveFlowData.currentPremise?.addressLineString ?? "",
                                                       stopServiceCountyStateZip: "\(moveFlowData.currentPremise?.townDetail.name ?? ""), \(moveFlowData.currentPremise?.townDetail.stateOrProvince ?? "") \(moveFlowData.currentPremise?.townDetail.code ?? "")",
                                                       startServiceAddress: moveFlowData.addressLookupResponse?.first?.address ?? "",
                                                       startServiceCountyStateZip: "\(moveFlowData.addressLookupResponse?.first?.city ?? ""), \(moveFlowData.addressLookupResponse?.first?.state ?? "") \(moveFlowData.addressLookupResponse?.first?.zipCode ?? "")",
                                                       didSelectRadioButton: didSelectRadioButton)
        }
        
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
                                                                                                           transferEligibility: .eligible,
                                                                                                           transferOption: self.transferOption)
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
                                                                                                           transferEligibility: .eligible,
                                                                                                           transferOption: self.transferOption)
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
        case .doNotTransfer:
            performSegue(withIdentifier: "showTerminationAgreement", sender: nil)
        }
    }
    
}

extension SeamlessMoveViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? TerminateAgreementViewController {
            vc.moveFlowData = moveFlowData
            vc.isUnauth = isUnauth
            vc.transferEligibility = .eligible
        }
    }
}
