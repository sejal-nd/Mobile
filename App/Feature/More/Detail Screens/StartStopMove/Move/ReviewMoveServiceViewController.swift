//
//  ReviewMoveServiceViewController.swift
//  EUMobile
//
//  Created by Mithlesh Kumar on 21/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import PDTSimpleCalendar

class ReviewMoveServiceViewController: UIViewController {

    @IBOutlet weak var stopCurrentServiceAddressStackView: UIStackView!
    @IBOutlet weak var stopCurrentDateStackView: UIStackView!
    @IBOutlet weak var stopServiceProviderStackView: UIStackView!


    @IBOutlet weak var startNewServiceAddressStackView: UIStackView!
    @IBOutlet weak var startNewDateStackView: UIStackView!

    @IBOutlet weak var startNewServiceProviderStackView: UIStackView!
    @IBOutlet weak var eBillStackView: UIStackView!


    @IBOutlet weak var electricCurrentStackView: UIStackView!
    @IBOutlet weak var gasCurrentStackView: UIStackView!

    @IBOutlet weak var electricNewStackView: UIStackView!
    @IBOutlet weak var gasNewStackView: UIStackView!

    @IBOutlet weak var enrollEbillButton : UIButton!

    @IBOutlet weak var changeStopServiceDateButton: UIButton!

    @IBOutlet weak var changeStartServiceDateButton: UIButton!


    @IBOutlet weak var changeStartServiceAddress: UIButton!
    @IBOutlet weak var submitButton: PrimaryButton!

    @IBOutlet weak var stopCurrentServiceAddressStaticLabel: UILabel!
    @IBOutlet weak var stopCurrentServiceAddressLabel: UILabel!
    @IBOutlet weak var stopCurrentServiceProvidedStaticLabel: UILabel!
    @IBOutlet weak var stopCurrentServiceDateStaticLabel: UILabel!
    @IBOutlet weak var stopCurrentServiceDateLabel: UILabel!
    @IBOutlet weak var stopCurrentServiceDisconnectStaticLabel: UILabel!

    @IBOutlet weak var startNewServiceAddressStaticLabel: UILabel!
    @IBOutlet weak var startNewServiceAddressLabel: UILabel!
    @IBOutlet weak var startNewServiceProvidedStaticLabel: UILabel!

    @IBOutlet weak var startNewServiceDateStaticLabel: UILabel!
    @IBOutlet weak var startNewServiceDateLabel: UILabel!

    @IBOutlet weak var startNewServiceConnectStaticLabel: UILabel!

    @IBOutlet weak var enrollEbillInfoLabel: UILabel!

    var moveFlowData: MoveServiceFlowData!
    var viewModel = ReviewMoveServiceViewModel()
    var disposeBag = DisposeBag()
    var changeDateType = ChnageDateServiceType.stop

    override func viewDidLoad() {
        super.viewDidLoad()
        initialUISetup()
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    func initialUISetup() {

        refreshData()

        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(image: UIImage(named: "ic_back"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(ReviewMoveServiceViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton


        stopCurrentServiceAddressStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        stopCurrentServiceProvidedStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        stopCurrentServiceDateStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        stopCurrentServiceDisconnectStaticLabel.font = SystemFont.regular.of(textStyle: .caption1)

        startNewServiceAddressStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        startNewServiceProvidedStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        startNewServiceDateStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        startNewServiceConnectStaticLabel.font = SystemFont.regular.of(textStyle: .caption1)

        enrollEbillInfoLabel.font = SystemFont.regular.of(textStyle: .subheadline)

        if moveFlowData.currentAccountDetail.isEBillEnrollment{
            if moveFlowData.currentAccountDetail.eBillEnrollStatus == .canEnroll{
                eBillStackView.isHidden = false;
            }else {
                eBillStackView.isHidden = true;
            }

        }else {
            eBillStackView.isHidden = false
        }

        enrollEbillButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.enrollEbillButton.isSelected = !self.enrollEbillButton.isSelected
            }).disposed(by: disposeBag)

        changeStopServiceDateButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.changeDateType = .stop
                let calendarVC = PDTSimpleCalendarViewController()
                calendarVC.calendar = .opCo
                calendarVC.delegate = self
                calendarVC.firstDate = Calendar.current.date(byAdding: .month, value: 0, to: Calendar.current.startOfDay(for: .now))
                calendarVC.lastDate = Calendar.current.date(byAdding: .month, value: 1, to: Calendar.current.startOfDay(for: .now))
                calendarVC.scroll(toSelectedDate: true)
                calendarVC.weekdayHeaderEnabled = true
                calendarVC.weekdayTextType = PDTSimpleCalendarViewWeekdayTextType.veryShort
                calendarVC.selectedDate = Calendar.opCo.startOfDay(for: self.moveFlowData.stopServiceDate)
                let navigationController = LargeTitleNavigationController(rootViewController: calendarVC)
                navigationController.setNavigationBarHidden(false, animated: false)
                calendarVC.navigationItem.title = "Select Stop Date"
                calendarVC.addCloseButton()
                calendarVC.navigationItem.largeTitleDisplayMode = .automatic
                navigationController.modalPresentationStyle = .fullScreen
                self.navigationController?.present(navigationController, animated: true, completion: nil)
            }).disposed(by: disposeBag)


        changeStartServiceDateButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.changeDateType = .start
                let calendarVC = PDTSimpleCalendarViewController()
                calendarVC.calendar = .opCo
                calendarVC.delegate = self
                calendarVC.firstDate = Calendar.current.date(byAdding: .month, value: 0, to: Calendar.current.startOfDay(for: .now))
                calendarVC.lastDate = Calendar.current.date(byAdding: .month, value: 1, to: Calendar.current.startOfDay(for: .now))
                calendarVC.scroll(toSelectedDate: true)
                calendarVC.weekdayHeaderEnabled = true
                calendarVC.weekdayTextType = PDTSimpleCalendarViewWeekdayTextType.veryShort
                if let startDate =  self.moveFlowData.startServiceDate{
                    calendarVC.selectedDate = Calendar.opCo.startOfDay(for: startDate)
                }

                let navigationController = LargeTitleNavigationController(rootViewController: calendarVC)
                navigationController.setNavigationBarHidden(false, animated: false)
                calendarVC.navigationItem.title = "Select Start Date"
                calendarVC.addCloseButton()
                calendarVC.navigationItem.largeTitleDisplayMode = .automatic
                navigationController.modalPresentationStyle = .fullScreen
                self.navigationController?.present(navigationController, animated: true, completion: nil)
            }).disposed(by: disposeBag)

        changeStartServiceAddress.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
                let newServiceAddressViewController = storyboard.instantiateViewController(withIdentifier: "NewServiceAddressViewController") as! NewServiceAddressViewController
                newServiceAddressViewController.isLaunchedFromReviewScreen = true
                newServiceAddressViewController.delegate = self
                newServiceAddressViewController.viewModel = NewServiceAddressViewModel(moveServiceFlowData: self.moveFlowData)
                let navigationController = LargeTitleNavigationController(rootViewController: newServiceAddressViewController)
                navigationController.modalPresentationStyle = .fullScreen
                self.present(navigationController, animated: true, completion: nil)
            }).disposed(by: disposeBag)


        submitButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }

                let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
                let reviewStopServiceViewController = storyboard.instantiateViewController(withIdentifier: "FinalReviewMoveServiceViewController") as! FinalReviewMoveServiceViewController
                reviewStopServiceViewController.moveFlowData = self.moveFlowData
                self.navigationController?.pushViewController(reviewStopServiceViewController, animated: true)

            }).disposed(by: disposeBag)

    }

    func refreshData() {
        self.electricCurrentStackView.isHidden = !(moveFlowData.currentAccountDetail.serviceType?.contains("ELECTRIC") ?? false)
        self.gasCurrentStackView.isHidden = !(moveFlowData.currentAccountDetail.serviceType?.contains("GAS") ?? false)
        if let currPremise = moveFlowData.currentAccount.currentPremise, let address = currPremise.addressGeneral {
            self.stopCurrentServiceAddressLabel.text = address
        }else {
            self.stopCurrentServiceAddressLabel.text = moveFlowData.currentAccount.address ?? ""
        }
        self.stopCurrentServiceDateLabel.text = DateFormatter.fullMonthDayAndYearFormatter.string(from: moveFlowData.stopServiceDate)


        self.electricCurrentStackView.isHidden = !(moveFlowData.currentAccountDetail.serviceType?.contains("ELECTRIC") ?? false)
        self.gasCurrentStackView.isHidden = !(moveFlowData.currentAccountDetail.serviceType?.contains("GAS") ?? false)

        if let address = self.moveFlowData.addressLookupResponse?.first {
            self.startNewServiceAddressLabel.text = address.compressedAddress
        }else {
            self.startNewServiceAddressLabel.text = ""
        }

        if let startDate =  moveFlowData.startServiceDate{
            self.startNewServiceDateLabel.text = DateFormatter.fullMonthDayAndYearFormatter.string(from:startDate)
        }

    }

    @objc func back(sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
}

// MARK: - PDTSimpleCalendarViewDelegate
extension ReviewMoveServiceViewController: PDTSimpleCalendarViewDelegate {
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, isEnabledDate date: Date!) -> Bool {
        return viewModel.isValidDate(date, workDays: moveFlowData.workDays, accountDetails: moveFlowData.currentAccountDetail)
    }

    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, didSelect date: Date!) {
        switch changeDateType {
        case .stop:
            self.moveFlowData.stopServiceDate = date
            self.stopCurrentServiceDateLabel.text = DateFormatter.fullMonthDayAndYearFormatter.string(from: date)
        case .start:
            self.moveFlowData.startServiceDate = date
            self.startNewServiceDateLabel.text = DateFormatter.fullMonthDayAndYearFormatter.string(from: date)
        }
        controller.dismiss(animated: true, completion: nil)
    }
}
extension ReviewMoveServiceViewController:NewServiceAddressDelegate{
    func didSelectNewServiceAddress(_ flowData: MoveServiceFlowData) {
        moveFlowData.addressLookupResponse = flowData.addressLookupResponse;
        moveFlowData.appartment_List = flowData.appartment_List;
        moveFlowData.selected_appartment = flowData.selected_appartment;
        refreshData()
    }
}
