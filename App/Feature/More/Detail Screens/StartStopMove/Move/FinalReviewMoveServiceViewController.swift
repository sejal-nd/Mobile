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

    @IBOutlet weak var supplierAgreementStackView: UIStackView!


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
    @IBOutlet weak var supplierAgreementButton: UIButton!
    @IBOutlet weak var ebillUserInfoLabel: UILabel!



    @IBOutlet weak var submitBtn: PrimaryButton!

    var moveFlowData: MoveServiceFlowData!
    var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        initialUIBinding()
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    func initialUIBinding() {

        refreshData()

        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(image: UIImage(named: "ic_back"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(FinalReviewMoveServiceViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton

        renterOwnerStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        finalBillAddressStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        ssnTaxIDStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        dlStateIDStaticLabel.font = SystemFont.regular.of(textStyle: .caption1)
        employementStatusStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        dobStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)


        submitBtn.roundCorners(.allCorners, radius: 27.5, borderColor: UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0), borderWidth: 1.0)

        changeRenterOwnerButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.showAlertRenterOwner()
            }).disposed(by: disposeBag)


        supplierAgreementButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.supplierAgreementButton.isSelected = !self.supplierAgreementButton.isSelected
                self.submitBtn.isUserInteractionEnabled = self.supplierAgreementButton.isSelected
                self.submitBtn.backgroundColor = self.supplierAgreementButton.isSelected ? UIColor(red: 0, green: 89.0/255.0, blue: 164.0/255.0, alpha: 1.0) : UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0)
                self.submitBtn.setTitleColor(self.supplierAgreementButton.isSelected ? UIColor.white : UIColor(red: 74.0/255.0, green: 74.0/255.0, blue: 74.0/255.0, alpha: 0.5), for: .normal)

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
                //  guard let `self` = self else { return }
                // TODO ::

            }).disposed(by: disposeBag)

        submitBtn.rx.tap
            .subscribe(onNext: { [weak self] _ in
                // TODO

            }).disposed(by: disposeBag)


    }

    func refreshData() {
        if moveFlowData.isOwner {
            self.renterOwnerLabel.text = "Owner"
        }else {
            self.ssnTaxIDLabel.text = "Renter"
        }

        if let ssn = moveFlowData.idVerification?.ssn {
            self.ssnTaxIDLabel.text =  "Ending in " + ssn
        }else {
            self.ssnTaxIDLabel.text = "None Provided"
        }

        if let driverLicenseNumber = moveFlowData.idVerification?.driverLicenseNumber {
            self.dlStateIDLabel.text = driverLicenseNumber
        }else {
            self.dlStateIDLabel.text = "None Provided"
        }

        if let employmentStatus = moveFlowData.idVerification?.employmentStatus {
            self.employementStatusLabel.text = employmentStatus
        }else {
            self.employementStatusLabel.text = "None Provided"
        }

        if let dob = moveFlowData.idVerification?.dateOfBirth {
            self.dobLabel.text = DateFormatter.fullMonthDayAndYearFormatter.string(from:dob)
        }else {
            self.dobLabel.text = "None Provided"
        }



        changeMailingAddressButton.isHidden = moveFlowData.currentAccountDetail.isEBillEnrollment


        self.finalBillAddressStackView.isHidden = moveFlowData.currentAccountDetail.isEBillEnrollment
        self.ebillStackView.isHidden = !moveFlowData.currentAccountDetail.isEBillEnrollment
        self.ebillUserInfoLabel.text = "Your final bill will be delivered by email to \(moveFlowData.currentAccountDetail.customerInfo.emailAddress ?? "")."
        self.supplierAgreementStackView.isHidden = !moveFlowData.currentAccountDetail.hasThirdPartySupplier

        self.submitBtn.isUserInteractionEnabled = !moveFlowData.currentAccountDetail.hasThirdPartySupplier
        self.submitBtn.backgroundColor = !moveFlowData.currentAccountDetail.hasThirdPartySupplier ? UIColor(red: 0, green: 89.0/255.0, blue: 164.0/255.0, alpha: 1.0) : UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0)
        self.submitBtn.setTitleColor(!moveFlowData.currentAccountDetail.hasThirdPartySupplier ? UIColor.white : UIColor(red: 74.0/255.0, green: 74.0/255.0, blue: 74.0/255.0, alpha: 0.5), for: .normal)

        if moveFlowData.hasCurrentServiceAddressForBill {
            self.finalBillAddressLabel.text = "Same as current service address"
        } else {
            guard let address = moveFlowData.mailingAddress else { return }
            self.finalBillAddressLabel.text = "\(address.streetAddress), \(address.city), \(address.state) \(address.zipCode)"
        }

    }

    func showAlertRenterOwner(){
        let alertController = UIAlertController(title: "Are you the owner or renter?", message: nil, preferredStyle: .actionSheet)

        let margin:CGFloat = 10.0
        let rect = CGRect(x: margin, y: margin + 50, width: alertController.view.bounds.size.width - margin * 4.0, height: 45)
        let segmentedControl = SegmentedControl(frame: rect)

        segmentedControl.backgroundColor = .softGray

        alertController.setBackgroundColor(color: .white)
        alertController.setTitle(font: SystemFont.semibold.of(size: 17), color: .deepGray)


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
            }else {
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

}

// MARK: - MoveFinalMailingAddressDelegate
extension FinalReviewMoveServiceViewController: MoveFinalMailingAddressDelegate {

    func mailingAddress(_ address: MailingAddress) {
        self.moveFlowData.hasCurrentServiceAddressForBill = false
        self.moveFlowData.mailingAddress = address
        refreshData()
    }
}

