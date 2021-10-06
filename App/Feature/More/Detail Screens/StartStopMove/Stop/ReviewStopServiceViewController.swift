//
//  ReviewStopServiceViewController.swift
//  EUMobile
//
//  Created by RAMAITHANI on 08/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import PDTSimpleCalendar

class ReviewStopServiceViewController: UIViewController {
    
    @IBOutlet weak var stopCurrentServiceAddressStackView: UIStackView!
    @IBOutlet weak var stopDateStackView: UIStackView!
    @IBOutlet weak var finalBillAddressStackView: UIStackView!
    @IBOutlet weak var supplierAgreementStackView: UIStackView!
    @IBOutlet weak var serviceProviderStackView: UIStackView!
    @IBOutlet weak var electricStackView: UIStackView!
    @IBOutlet weak var gasStackView: UIStackView!
    @IBOutlet weak var ebillStackView: UIStackView!

    @IBOutlet weak var ebillUserInfoLabel: UILabel!
    @IBOutlet weak var currentServiceAddressLabel: UILabel!
    @IBOutlet weak var stopServiceDateLabel: UILabel!
    @IBOutlet weak var finalMailingAddress: UILabel!
    
    @IBOutlet weak var supplierAgreementButton: UIButton!
    @IBOutlet weak var changeMailingAddressButton: UIButton!
    @IBOutlet weak var changeStopServiceDateButton: UIButton!
    @IBOutlet weak var submitButton: PrimaryButton!
    
    @IBOutlet weak var stopServiceAddressStaticLabel: UILabel!
    @IBOutlet weak var serviceProvidedStaticLabel: UILabel!
    @IBOutlet weak var stopServiceDateStaticLabel: UILabel!
    @IBOutlet weak var serviceDisconnectStaticLabel: UILabel!
    @IBOutlet weak var finalBillAddressStaticLabel: UILabel!


    var stopFlowData: StopServiceFlowData!
    var viewModel = ReviewStopServiceViewModel()
    var disposeBag = DisposeBag()
    var delegate: FinalMailingAddressDelegate? = nil

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
        let newBackButton = UIBarButtonItem(image: UIImage(named: "ic_back"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(ReviewStopServiceViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton
        
        stopServiceAddressStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        serviceProvidedStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        stopServiceDateStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        serviceDisconnectStaticLabel.font = SystemFont.regular.of(textStyle: .caption1)
        finalBillAddressStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        changeMailingAddressButton.isHidden = stopFlowData.hasCurrentServiceAddressForBill

        submitButton.roundCorners(.allCorners, radius: 27.5, borderColor: UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0), borderWidth: 1.0)

        supplierAgreementButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.supplierAgreementButton.isSelected = !self.supplierAgreementButton.isSelected
                self.submitButton.isUserInteractionEnabled = self.supplierAgreementButton.isSelected
                self.submitButton.backgroundColor = self.supplierAgreementButton.isSelected ? UIColor(red: 0, green: 89.0/255.0, blue: 164.0/255.0, alpha: 1.0) : UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0)
                self.submitButton.setTitleColor(self.supplierAgreementButton.isSelected ? UIColor.white : UIColor(red: 74.0/255.0, green: 74.0/255.0, blue: 74.0/255.0, alpha: 0.5), for: .normal)

            }).disposed(by: disposeBag)
        
        changeMailingAddressButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                let storyboard = UIStoryboard(name: "ISUMStop", bundle: nil)
                let finalMailingAddressViewController = storyboard.instantiateViewController(withIdentifier: "FinalMailingAddressViewController") as! FinalMailingAddressViewController
                finalMailingAddressViewController.isLaunchedFromReviewScreen = true
                finalMailingAddressViewController.delegate = self
                finalMailingAddressViewController.stopFlowData = self.stopFlowData
                let navigationController = LargeTitleNavigationController(rootViewController: finalMailingAddressViewController)
                navigationController.modalPresentationStyle = .fullScreen
                self.present(navigationController, animated: true, completion: nil)
            }).disposed(by: disposeBag)
        
        changeStopServiceDateButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                let calendarVC = PDTSimpleCalendarViewController()
                calendarVC.calendar = .opCo
                calendarVC.delegate = self
                calendarVC.firstDate = Calendar.current.date(byAdding: .month, value: 0, to: Calendar.current.startOfDay(for: .now))
                calendarVC.lastDate = Calendar.current.date(byAdding: .month, value: 1, to: Calendar.current.startOfDay(for: .now))
                calendarVC.scroll(toSelectedDate: true)
                calendarVC.weekdayHeaderEnabled = true
                calendarVC.weekdayTextType = PDTSimpleCalendarViewWeekdayTextType.veryShort
                calendarVC.selectedDate = Calendar.opCo.startOfDay(for: self.stopFlowData.selectedDate)
                let navigationController = LargeTitleNavigationController(rootViewController: calendarVC)
                navigationController.setNavigationBarHidden(false, animated: false)
                calendarVC.navigationItem.title = "Select Stop Date"
                calendarVC.addCloseButton()
                calendarVC.navigationItem.largeTitleDisplayMode = .automatic
                navigationController.modalPresentationStyle = .fullScreen
                self.navigationController?.present(navigationController, animated: true, completion: nil)
            }).disposed(by: disposeBag)

        submitButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.navigationController?.view.isUserInteractionEnabled = false
                self.submitButton.setLoading()
                self.viewModel.onStopSubmit.onNext(self.stopFlowData)
            }).disposed(by: disposeBag)
        
        viewModel.response
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.navigationController?.view.isUserInteractionEnabled = true
                self.submitButton.reset()
                let storyboard = UIStoryboard(name: "ISUMStop", bundle: nil)
                let stopConfirmationScreenViewController = storyboard.instantiateViewController(withIdentifier: "StopConfirmationScreenViewController") as! StopConfirmationScreenViewController
                self.navigationController?.pushViewController(stopConfirmationScreenViewController, animated: true)
            }).disposed(by: disposeBag)
        
        viewModel.errorResponse
            .subscribe(onNext: { [weak self]_ in
                guard let `self` = self else { return }
                self.navigationController?.view.isUserInteractionEnabled = true
                self.submitButton.reset()
            }).disposed(by: disposeBag)
    }
    
    func refreshData() {
        
        self.electricStackView.isHidden = !(stopFlowData.currentAccountDetail.serviceType?.contains("ELECTRIC") ?? false)
        self.gasStackView.isHidden = !(stopFlowData.currentAccountDetail.serviceType?.contains("GAS") ?? false)
        if let currPremise = stopFlowData.currentAccount.currentPremise, let address = currPremise.addressGeneral {
            self.currentServiceAddressLabel.text = address
        }else {
            self.currentServiceAddressLabel.text = stopFlowData.currentAccount.address ?? ""
        }
        self.stopServiceDateLabel.text = DateFormatter.ddMMMMYYYYFormatter.string(from: stopFlowData.selectedDate)
        self.finalBillAddressStackView.isHidden = stopFlowData.currentAccountDetail.isEBillEnrollment
        self.ebillStackView.isHidden = !stopFlowData.currentAccountDetail.isEBillEnrollment
        self.ebillUserInfoLabel.text = "Your final bill will be delivered by email to \(stopFlowData.currentAccountDetail.customerInfo.emailAddress ?? "")."
        self.supplierAgreementStackView.isHidden = !stopFlowData.currentAccountDetail.hasThirdPartySupplier

        self.submitButton.isUserInteractionEnabled = !stopFlowData.currentAccountDetail.hasThirdPartySupplier
        self.submitButton.backgroundColor = !stopFlowData.currentAccountDetail.hasThirdPartySupplier ? UIColor(red: 0, green: 89.0/255.0, blue: 164.0/255.0, alpha: 1.0) : UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0)
        self.submitButton.setTitleColor(!stopFlowData.currentAccountDetail.hasThirdPartySupplier ? UIColor.white : UIColor(red: 74.0/255.0, green: 74.0/255.0, blue: 74.0/255.0, alpha: 0.5), for: .normal)
        
        if stopFlowData.hasCurrentServiceAddressForBill {
            self.finalMailingAddress.text = "Same as current service address"
        } else {
            guard let address = stopFlowData.mailingAddress else { return }
            self.finalMailingAddress.text = "\(address.streetAddress), \(address.city), \(address.state) \(address.zipCode)"
        }

    }
    
    @objc func back(sender: UIBarButtonItem) {
        
        if let address = stopFlowData.mailingAddress {
            delegate?.mailingAddress(address)
        }
        self.navigationController?.popViewController(animated: true)
    }
}

// MARK: - PDTSimpleCalendarViewDelegate
extension ReviewStopServiceViewController: PDTSimpleCalendarViewDelegate {
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, isEnabledDate date: Date!) -> Bool {
        return viewModel.isValidDate(date, workDays: stopFlowData.workDays, accountDetails: stopFlowData.currentAccountDetail)
    }
    
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, didSelect date: Date!) {
        self.stopFlowData.selectedDate = date
        self.stopServiceDateLabel.text = DateFormatter.ddMMMMYYYYFormatter.string(from: date)
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - FinalMailingAddressProtocol
extension ReviewStopServiceViewController: FinalMailingAddressDelegate {
    
    func mailingAddress(_ address: MailingAddress) {
        
        self.stopFlowData.mailingAddress = address
        refreshData()
    }
}
