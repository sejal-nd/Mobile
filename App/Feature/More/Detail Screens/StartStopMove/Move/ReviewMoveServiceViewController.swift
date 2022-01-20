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


    @IBOutlet weak var electricCurrentStackView: UIStackView!
    @IBOutlet weak var gasCurrentStackView: UIStackView!

    @IBOutlet weak var electricNewStackView: UIStackView!
    @IBOutlet weak var gasNewStackView: UIStackView!


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

    var viewModel = ReviewMoveServiceViewModel()
    var disposeBag = DisposeBag()
    var changeDateType = ChnageDateServiceType.stop

    override func viewDidLoad() {
        super.viewDidLoad()
        initialUISetup()
    }

    override func viewWillAppear(_ animated: Bool) {
        if viewModel.isUnauth {
            FirebaseUtility.logScreenView(.unauthMoveReviewView(className: self.className))
        } else {
            FirebaseUtility.logScreenView(.moveReviewView(className: self.className))
        }
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    func initialUISetup() {

        refreshData()

        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(image: UIImage(named: "ic_back"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(ReviewMoveServiceViewController.back(sender:)))
        newBackButton.accessibilityLabel = NSLocalizedString("Back", comment: "")
        self.navigationItem.leftBarButtonItem = newBackButton


        stopCurrentServiceAddressStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        stopCurrentServiceProvidedStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        stopCurrentServiceDateStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        stopCurrentServiceDisconnectStaticLabel.font = SystemFont.regular.of(textStyle: .caption1)

        startNewServiceAddressStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        startNewServiceProvidedStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        startNewServiceDateStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        startNewServiceConnectStaticLabel.font = SystemFont.regular.of(textStyle: .caption1)


        changeStopServiceDateButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                FirebaseUtility.logEvent(self.viewModel.isUnauth ? .unauthMoveService(parameters: [.calendar_stop_date]) : .authMoveService(parameters: [.calendar_stop_date]))
                self.changeDateType = .stop
                let calendarVC = PDTSimpleCalendarViewController()
                calendarVC.calendar = .opCo
                calendarVC.delegate = self
                calendarVC.firstDate = Calendar.current.date(byAdding: .month, value: 0, to: Calendar.current.startOfDay(for: .now))
                calendarVC.lastDate = Calendar.current.date(byAdding: .month, value: 1, to: Calendar.current.startOfDay(for: .now))
                calendarVC.scroll(toSelectedDate: true)
                calendarVC.weekdayHeaderEnabled = true
                calendarVC.weekdayTextType = PDTSimpleCalendarViewWeekdayTextType.veryShort
                calendarVC.selectedDate = Calendar.opCo.startOfDay(for: self.viewModel.moveFlowData.stopServiceDate)
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
                
                FirebaseUtility.logEvent(self.viewModel.isUnauth ? .unauthMoveService(parameters: [.calendar_start_date]) : .authMoveService(parameters: [.calendar_start_date]))
                self.changeDateType = .start
                let calendarVC = PDTSimpleCalendarViewController()
                calendarVC.calendar = .opCo
                calendarVC.delegate = self
                calendarVC.firstDate = Calendar.current.date(byAdding: .month, value: 0, to: Calendar.current.startOfDay(for: .now))
                calendarVC.lastDate = Calendar.current.date(byAdding: .month, value: 1, to: Calendar.current.startOfDay(for: .now))
                calendarVC.scroll(toSelectedDate: true)
                calendarVC.weekdayHeaderEnabled = true
                calendarVC.weekdayTextType = PDTSimpleCalendarViewWeekdayTextType.veryShort
                if let startDate =  self.viewModel.moveFlowData.startServiceDate{
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
                newServiceAddressViewController.viewModel = NewServiceAddressViewModel(moveServiceFlowData: self.viewModel.moveFlowData)
                let navigationController = LargeTitleNavigationController(rootViewController: newServiceAddressViewController)
                navigationController.modalPresentationStyle = .fullScreen
                self.present(navigationController, animated: true, completion: nil)
            }).disposed(by: disposeBag)


        submitButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }

                let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
                let reviewStopServiceViewController = storyboard.instantiateViewController(withIdentifier: "FinalReviewMoveServiceViewController") as! FinalReviewMoveServiceViewController
                reviewStopServiceViewController.moveFlowData = self.viewModel.moveFlowData
                self.navigationController?.pushViewController(reviewStopServiceViewController, animated: true)
            }).disposed(by: disposeBag)

    }

    func refreshData() {
        
        self.electricCurrentStackView.isHidden = (viewModel.moveFlowData.unauthMoveData?.isUnauthMove ?? false) ? !(viewModel.moveFlowData.unauthMoveData?.accountDetails?.serviceType.contains("ELECTRIC") ?? false) : !(viewModel.moveFlowData.currentAccountDetail?.serviceType?.contains("ELECTRIC") ?? false)
        
        self.gasCurrentStackView.isHidden = (viewModel.moveFlowData.unauthMoveData?.isUnauthMove ?? false) ? !(viewModel.moveFlowData.unauthMoveData?.accountDetails?.serviceType.contains("GAS") ?? false) : !(viewModel.moveFlowData.currentAccountDetail?.serviceType?.contains("GAS") ?? false)

        if let unauthMoveData = viewModel.moveFlowData.unauthMoveData, unauthMoveData.isUnauthMove, let unauthAccountDetails = unauthMoveData.accountDetails {
            var address = ""
            if !unauthAccountDetails.addressLine.isEmpty  {
                address += "\(unauthAccountDetails.addressLine), "
            }
            if !unauthAccountDetails.city.isEmpty {
                address += "\(unauthAccountDetails.city), "
            }
            if !unauthAccountDetails.state.isEmpty {
                address += "\(unauthAccountDetails.state)"
            }
            if !unauthAccountDetails.zipCode.isEmpty {
                address += " \(unauthAccountDetails.zipCode)"
            }
            
            if address.isEmpty {
                self.stopCurrentServiceAddressLabel.text = "No Address Available"
            } else {
                self.stopCurrentServiceAddressLabel.text = address
            }
        } else if let currPremise = viewModel.moveFlowData.currentAccount?.currentPremise, let address = currPremise.addressGeneral {
            self.stopCurrentServiceAddressLabel.text = address
        } else {
            self.stopCurrentServiceAddressLabel.text = viewModel.moveFlowData.currentAccount?.address ?? "No Address Available"
        }
        self.stopCurrentServiceDateLabel.text = DateFormatter.fullMonthDayAndYearFormatter.string(from: viewModel.moveFlowData.stopServiceDate)

        if let address = self.viewModel.moveFlowData.addressLookupResponse?.first {
            self.startNewServiceAddressLabel.text = address.compressedAddress.getValidISUMAddress()

            if address.meterInfo.contains(where: {$0.meterType.lowercased() == "ELECTRIC".lowercased()}) {
                self.electricNewStackView.isHidden = false
            } else {
                self.electricNewStackView.isHidden = true
            }

            if address.meterInfo.contains(where: {$0.meterType.lowercased() == "GAS".lowercased()}) {
                self.gasNewStackView.isHidden = false
            }
            else {
                self.gasNewStackView.isHidden = true
            }

        } else {
            self.startNewServiceAddressLabel.text = ""
            self.electricNewStackView.isHidden = true
            self.gasNewStackView.isHidden = true
        }

        if let startDate =  viewModel.moveFlowData.startServiceDate{
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
        return viewModel.isValidDate(date, workDays: viewModel.moveFlowData.workDays)
    }

    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, didSelect date: Date!) {
        switch changeDateType {
        case .stop:
            self.viewModel.moveFlowData.stopServiceDate = date
            self.stopCurrentServiceDateLabel.text = DateFormatter.fullMonthDayAndYearFormatter.string(from: date)
        case .start:
            self.viewModel.moveFlowData.startServiceDate = date
            self.startNewServiceDateLabel.text = DateFormatter.fullMonthDayAndYearFormatter.string(from: date)
        }
        controller.dismiss(animated: true, completion: nil)
    }
}
extension ReviewMoveServiceViewController:NewServiceAddressDelegate{
    func didSelectNewServiceAddress(_ flowData: MoveServiceFlowData) {
        viewModel.moveFlowData.addressLookupResponse = flowData.addressLookupResponse;
        viewModel.moveFlowData.appartment_List = flowData.appartment_List;
        viewModel.moveFlowData.selected_appartment = flowData.selected_appartment;
        refreshData()
    }
}
