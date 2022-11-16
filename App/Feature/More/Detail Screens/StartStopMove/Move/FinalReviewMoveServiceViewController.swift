//
//  FinalReviewMoveServiceViewController.swift
//  EUMobile
//
//  Created by Mithlesh Kumar on 25/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift


class FinalReviewMoveServiceViewController: UIViewController {

    @IBOutlet weak var renterOwnerStackView: UIStackView!
    @IBOutlet weak var finalBillAddressStackView: UIStackView!

    @IBOutlet weak var idVerificationStackView: UIStackView!

    @IBOutlet weak var ebillStackView: UIStackView!

    @IBOutlet weak var renterOwnerStaticLabel: UILabel!

    @IBOutlet weak var renterOwnerLabel: UILabel!


    @IBOutlet weak var finalBillAddressStaticLabel: UILabel!
    @IBOutlet weak var finalBillAddressLabel: UILabel!


    @IBOutlet weak var ssnTaxIDStaticLabel: UILabel!

    @IBOutlet weak var ssnTaxIDLabel: UILabel!

    @IBOutlet weak var dlStateIDStaticLabel: UILabel!

    @IBOutlet weak var dlStateIDLabel: UILabel!
    @IBOutlet weak var employementStatusStaticLabel: UILabel!

    @IBOutlet weak var employementStatusLabel: UILabel!
    @IBOutlet weak var dobStaticLabel: UILabel!

    @IBOutlet weak var dobLabel: UILabel!

    @IBOutlet weak var changeRenterOwnerButton: UIButton!

    @IBOutlet weak var changeMailingAddressButton: UIButton!
    
    @IBOutlet weak var changeIDVerificationButton: UIButton!
    @IBOutlet weak var ebillUserInfoLabel: UILabel!

    var viewModel = ReviewMoveServiceViewModel()

    @IBOutlet weak var submitBtn: PrimaryButton!

    var moveFlowData: MoveServiceFlowData!
    var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        initialUIBinding()
    }

    override func viewWillAppear(_ animated: Bool) {
        if viewModel.isUnauth {
            FirebaseUtility.logScreenView(.unauthMoveReviewSubmitView(className: self.className))
        } else {
            FirebaseUtility.logScreenView(.moveReviewSubmitView(className: self.className))
        }
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    func initialUIBinding() {

        viewModel.moveFlowData = self.moveFlowData
        refreshData()

        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(image: UIImage(named: "ic_back"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(FinalReviewMoveServiceViewController.back(sender:)))
        newBackButton.accessibilityLabel = NSLocalizedString("Back", comment: "")
        self.navigationItem.leftBarButtonItem = newBackButton

        renterOwnerStaticLabel.font = .footnote
        finalBillAddressStaticLabel.font = .footnote
        ssnTaxIDStaticLabel.font = .footnote
        dlStateIDStaticLabel.font = .caption1
        employementStatusStaticLabel.font = .footnote
        dobStaticLabel.font = .footnote


        submitBtn.roundCorners(.allCorners, radius: 27.5, borderColor: UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0), borderWidth: 1.0)

        changeRenterOwnerButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.showAlertRenterOwner()
            }).disposed(by: disposeBag)

        changeMailingAddressButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
                let finalMailingAddressViewController = storyboard.instantiateViewController(withIdentifier: "MoveFinalMailingAddressViewController") as! MoveFinalMailingAddressViewController
                finalMailingAddressViewController.isLaunchedFromReviewScreen = true
                finalMailingAddressViewController.delegate = self
                finalMailingAddressViewController.moveFlowData = self.moveFlowData
                let navigationController = LargeTitleNavigationController(rootViewController: finalMailingAddressViewController)
                navigationController.modalPresentationStyle = .fullScreen
                self.present(navigationController, animated: true, completion: nil)
            }).disposed(by: disposeBag)

        changeIDVerificationButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                  guard let `self` = self else { return }
                let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
                let idVerificationViewController = storyboard.instantiateViewController(withIdentifier: "IdVerificationViewController") as! IdVerificationViewController
                idVerificationViewController.viewModel = IdVerificationViewModel(moveDataFlow: self.moveFlowData)
                idVerificationViewController.delegate = self
                idVerificationViewController.isLaunchedFromReviewScreen = true
                let navigationController = LargeTitleNavigationController(rootViewController: idVerificationViewController)
                navigationController.modalPresentationStyle = .fullScreen
                self.present(navigationController, animated: true, completion: nil)

            }).disposed(by: disposeBag)

        self.submitBtn.isUserInteractionEnabled = true
        self.submitBtn.backgroundColor = UIColor(red: 0, green: 89.0/255.0, blue: 164.0/255.0, alpha: 1.0)
        self.submitBtn.setTitleColor(UIColor.white, for: .normal)
        
        if self.viewModel.moveFlowData.currentAccountDetail?.hasThirdPartySupplier ?? false || self.viewModel.moveFlowData.unauthMoveData?.accountDetails?.hasThirdPartySupplier ?? false {
            submitBtn.setTitle("Continue", for: .normal)
        } else {
            submitBtn.setTitle("Submit", for: .normal)
        }
        
        submitBtn.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.logMoveServiceEvent(isUnauth: self.viewModel.isUnauth, parameters: [.submit])
                self.navigationController?.view.isUserInteractionEnabled = false
                LoadingView.show()
                
                if self.viewModel.moveFlowData.currentAccountDetail?.hasThirdPartySupplier ?? false || self.viewModel.moveFlowData.unauthMoveData?.accountDetails?.hasThirdPartySupplier ?? false {
                    MoveService.thirdPartyTransferEligibilityCheck(moveFlowData: self.viewModel.moveFlowData, completion: { [weak self] response in
                        guard let `self` = self else { return }
                                                
                        LoadingView.hide()
                        self.navigationController?.view.isUserInteractionEnabled = true

                        switch response {
                        case .success(let eligibilityResponse):
                            self.viewModel.moveFlowData.seamlessFlag = eligibilityResponse.seamlessflag
                            self.viewModel.moveFlowData.queryStartPayload = eligibilityResponse.queryStartPayload
                            
                            if eligibilityResponse.isEligible {
                                self.performSegue(withIdentifier: "showSeamlessMove", sender: nil)
                            } else {
                                self.performSegue(withIdentifier: "showTerminateSupplier", sender: nil)
                            }
                        case .failure(let error):
                            let alertVc = UIAlertController(title: error.title, message: error.description, preferredStyle: .alert)
                            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                            self.present(alertVc, animated: true, completion: nil)
                        }
                    })
                } else {
                    self.viewModel.moveServiceRequest(moveFlowData: self.moveFlowData) { [weak self] response in
                        guard let `self` = self else { return }
                        self.logMoveServiceEvent(isUnauth: self.viewModel.isUnauth, parameters: [response.isResolved == true ? .complete_resolved : .complete_unresolved])
                        LoadingView.hide()
                        self.navigationController?.view.isUserInteractionEnabled = true

                        let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
                        let moveServiceConfirmationViewController = storyboard.instantiateViewController(withIdentifier: "MoveServiceConfirmationViewController") as! MoveServiceConfirmationViewController
                        
                        let isUnauth = self.moveFlowData.unauthMoveData?.isUnauthMove ?? false
                        moveServiceConfirmationViewController.viewModel = MoveServiceConfirmationViewModel(moveServiceResponse: response, isUnauth: isUnauth)
                        moveServiceConfirmationViewController.viewModel.moveServiceResponse.isEBillEnrollment = (self.moveFlowData.unauthMoveData?.isUnauthMove ?? false) ? (self.moveFlowData.unauthMoveData?.accountDetails?.isEBillEnrollment ?? false) : (self.moveFlowData.currentAccountDetail?.isEBillEnrollment ?? true)
                        self.navigationController?.pushViewController(moveServiceConfirmationViewController, animated: true)
                    } onFailure: { [weak self] _ in
                        guard let `self` = self else { return }
                        self.logMoveServiceEvent(isUnauth: self.viewModel.isUnauth, parameters: [.submit_error])
                        LoadingView.hide()
                        self.navigationController?.view.isUserInteractionEnabled = true

                        let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
                        let generalSubmitErrorViewController = storyboard.instantiateViewController(withIdentifier: "MoveGeneralSubmitErrorViewController") as! MoveGeneralSubmitErrorViewController
                        self.navigationController?.pushViewController(generalSubmitErrorViewController, animated: true)
                    }
                }
            }).disposed(by: disposeBag)


    }

    func refreshData() {
        if moveFlowData.isOwner {
            self.renterOwnerLabel.text = "Owner"
        } else {
            self.renterOwnerLabel.text = "Renter"
        }

        if let ssn = moveFlowData.idVerification?.ssn, !ssn.isEmpty {
            self.ssnTaxIDLabel.text =  "Ending in " + ssn.suffix(4)
        } else {
            self.ssnTaxIDLabel.text = "None Provided"
        }

        if let driverLicenseNumber = moveFlowData.idVerification?.driverLicenseNumber, !driverLicenseNumber.isEmpty {
            self.dlStateIDLabel.text = driverLicenseNumber
        } else {
            self.dlStateIDLabel.text = "None Provided"
        }

        if let employmentStatus = moveFlowData.idVerification?.employmentStatus {
            self.employementStatusLabel.text = employmentStatus.0
        } else {
            self.employementStatusLabel.text = "None Provided"
        }

        if let dob = moveFlowData.idVerification?.dateOfBirth {
            self.dobLabel.text = DateFormatter.fullMonthDayAndYearFormatter.string(from:dob)
        } else {
            self.dobLabel.text = "None Provided"
        }

        changeMailingAddressButton.isHidden = moveFlowData.currentAccountDetail?.isEBillEnrollment ?? false

        self.finalBillAddressStackView.isHidden = moveFlowData.currentAccountDetail?.isEBillEnrollment ?? false
        self.ebillStackView.isHidden = !(moveFlowData.currentAccountDetail?.isEBillEnrollment ?? false)
        
        if let email = moveFlowData.currentAccountDetail?.customerInfo.emailAddress {
            self.ebillUserInfoLabel.text = "The bill for service at your previous address will be delivered to \(email)."
        } else {
            self.ebillUserInfoLabel.text = ""

        }

        if moveFlowData.hasCurrentServiceAddressForBill {
            self.finalBillAddressLabel.text = "Same as new service address"
        } else {
            guard let address = moveFlowData.mailingAddress else { return }
            self.finalBillAddressLabel.text = "\(address.streetAddress), \(address.city), \(address.state) \(address.zipCode)".getValidISUMAddress()
        }

    }

    func showAlertRenterOwner(){

        let style: UIAlertController.Style = UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet

        let alertController = UIAlertController(title: "Are you the owner or renter at your new address?", message: nil, preferredStyle: style)

        let margin:CGFloat = 10.0
        var rect = CGRect(x: margin, y: margin + 65, width: alertController.view.bounds.size.width - margin * 4.0, height: 45)

        if UIDevice.current.userInterfaceIdiom == .pad {
            rect = CGRect(x: 10, y: margin + 75, width: 245, height: 45)
        }

        let segmentedControl = SegmentedControl(frame: rect).usingAutoLayout()

        segmentedControl.backgroundColor = .softGray

        alertController.setBackgroundColor(color: .white)
        alertController.setTitle(font: SystemFont.semibold.of(size: 17), color: .neutralDark)


        alertController.view.addSubview(segmentedControl)
        alertController.view.heightAnchor.constraint(equalToConstant: 220).isActive = true

        segmentedControl.items = [NSLocalizedString("Owner", comment: ""),
                                  NSLocalizedString("Renter", comment: "")]

        if !moveFlowData.isOwner{
            segmentedControl.selectedIndex.accept(1)
        }

        let doneAction = UIAlertAction(title: "Done", style: .cancel, handler: { _ in
            if segmentedControl.selectedIndex.value == 0 {
                self.renterOwnerLabel.text = "Owner"
                self.moveFlowData?.isOwner =  true
            } else {
                self.renterOwnerLabel.text = "Renter"
                self.moveFlowData?.isOwner = false
            }
        })

        alertController.addAction(doneAction)

        self.present(alertController, animated: true, completion:{})
    }

    @objc func back(sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }

    private func logMoveServiceEvent(isUnauth: Bool, parameters: [MoveServiceParameter]) {
        FirebaseUtility.logEvent(viewModel.isUnauth ? .unauthMoveService(parameters: parameters) : .authMoveService(parameters: parameters))
    }
}

// MARK: - MoveFinalMailingAddressDelegate
extension FinalReviewMoveServiceViewController: MoveFinalMailingAddressDelegate {

    func mailingAddress(_ address: MailingAddress) {
        self.moveFlowData.hasCurrentServiceAddressForBill = false
        self.moveFlowData.mailingAddress = address
        refreshData()
    }
}

extension FinalReviewMoveServiceViewController: IdVerificationDelegate {
    
    func getIdVerification(_ id: IdVerification) {
        
        self.moveFlowData.idVerification = id
        self.refreshData()
    }
}

extension FinalReviewMoveServiceViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? SeamlessMoveViewController {
            vc.moveFlowData = viewModel.moveFlowData
            vc.isUnauth = viewModel.isUnauth
        } else if let vc = segue.destination as? TerminateAgreementViewController {
            vc.moveFlowData = viewModel.moveFlowData
            vc.transferEligibility = .ineligible
            vc.isUnauth = viewModel.isUnauth
        }
    }
}
