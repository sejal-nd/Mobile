//
//  MoveStartServiceViewController.swift
//  EUMobile
//
//  Created by RAMAITHANI on 11/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit
import PDTSimpleCalendar

class MoveStartServiceViewController: UIViewController {

    @IBOutlet weak var startServiceAddressStaticLabel: UILabel!
    @IBOutlet weak var startServiceAddressLabel: UILabel!
    
    @IBOutlet weak var serviceProvidedStaticLabel: UILabel!
    @IBOutlet weak var electricStackView: UIStackView!
    @IBOutlet weak var gasStackView: UIStackView!
    @IBOutlet weak var noneLabel: UILabel!
    
    @IBOutlet weak var renterOwnerSegmentControl: SegmentedControl!
    @IBOutlet weak var renterOwnerStaticLabel: UILabel!
    
    @IBOutlet weak var emailConfirmationStackView: UIStackView!

    @IBOutlet weak var startDateSelectionView: UIView!
    @IBOutlet weak var chooseStartDateStaticLabel: UILabel!
    @IBOutlet weak var stopDateToolTipButton: UIButton!
    @IBOutlet weak var dateStackView: UIStackView!
    @IBOutlet weak var selectedDateLabel: UILabel!
    @IBOutlet weak var startDateStaticLabel: UILabel!
    @IBOutlet weak var startDateLargeStaticLabel: UILabel!
    @IBOutlet weak var serviceStartStaticLabel: UILabel!

    var viewModel: MoveStartServiceViewModel!
    
    @IBOutlet weak var continueButton: PrimaryButton!

    override func viewDidLoad() {
        
        super.viewDidLoad()
        initialUISetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        FirebaseUtility.logScreenView(.moveSelectStartDateView(className: self.className))
    }
    
    func initialUISetup() {
        
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(image: UIImage(named: "ic_back"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(MoveStartServiceViewController.back(sender:)))
        newBackButton.accessibilityLabel = "Back"
        self.navigationItem.leftBarButtonItem = newBackButton
        
        renterOwnerSegmentControl.items = [NSLocalizedString("Owner", comment: ""), NSLocalizedString("Renter", comment: "")]
        startDateSelectionView.roundCorners(.allCorners, radius: 10.0, borderColor: UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0), borderWidth: 1.0)
        fontStyling()
        dataBinding()
    }
    
    @objc func back(sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }

    
    private func fontStyling() {
        
        startServiceAddressStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        serviceProvidedStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        serviceStartStaticLabel.font = SystemFont.regular.of(textStyle: .caption1)
    }
    
    private func dataBinding() {
        
        emailConfirmationStackView.isHidden = viewModel.moveServiceFlow.currentAccountDetail.isAMIAccount
        if let address = viewModel.moveServiceFlow.addressLookupResponse?.first {
            startServiceAddressLabel.text = address.compressedAddress.getValidISUMAddress()
        }
        electricStackView.isHidden = !(viewModel.moveServiceFlow.currentAccountDetail.serviceType?.contains("ELECTRIC") ?? false)
        gasStackView.isHidden = !(viewModel.moveServiceFlow.currentAccountDetail.serviceType?.contains("GAS") ?? false)

    }
    
    private func refreshUI(startDate: Date) {
        viewModel.moveServiceFlow.startServiceDate = startDate
        selectedDateLabel.text = DateFormatter.mmDdYyyyFormatter.string(from: startDate)
        selectedDateLabel.accessibilityLabel = "\(startDate.weekday),  \(startDate.fullMonthDayAndYearString)"
        continueButton.isEnabled = true
        continueButton.isUserInteractionEnabled = true
        self.dateStackView.isHidden = false
        self.startDateLargeStaticLabel.isHidden = true

    }
    
    @IBAction func onStartDateClicked(_ sender: Any) {
                
        FirebaseUtility.logEvent(.moveService(parameters: [.calendar_start_date]))
        let calendarVC = PDTSimpleCalendarViewController()
        calendarVC.calendar = .opCo
        calendarVC.delegate = self
        calendarVC.firstDate = Calendar.current.date(byAdding: .month, value: 0, to: Calendar.current.startOfDay(for: .now))
        calendarVC.lastDate = Calendar.current.date(byAdding: .day, value: 30, to: Calendar.current.startOfDay(for: .now))
        if let selectedDate = viewModel.moveServiceFlow.startServiceDate {
            calendarVC.selectedDate = Calendar.opCo.startOfDay(for: selectedDate)
        }
        calendarVC.scroll(toSelectedDate: true)
        calendarVC.weekdayHeaderEnabled = true
        calendarVC.weekdayTextType = PDTSimpleCalendarViewWeekdayTextType.veryShort

        let calendarNavigationController = LargeTitleNavigationController(rootViewController: calendarVC)
        calendarNavigationController.setNavigationBarHidden(false, animated: false)
        calendarVC.navigationItem.title = "Select Start Date"
        calendarVC.addCloseButton()
        calendarVC.navigationItem.largeTitleDisplayMode = .automatic
        calendarNavigationController.modalPresentationStyle = .fullScreen
        navigationController?.present(calendarNavigationController, animated: true, completion: nil)
    }
    
    @IBAction func onToolTipClicked(_ sender: Any) {
        
        let alertViewController = InfoAlertController(title: NSLocalizedString("Start Service Date", comment: ""),
                                                      message: "You must select an effective date within 30 days from the day you submit your request, excluding holidays and Sundays.")
        present(alertViewController, animated: true)
    }


    @IBAction func onContinueClicked(_ sender: Any) {
        viewModel.moveServiceFlow.isOwner = renterOwnerSegmentControl.selectedIndex.value == 0
        let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
        let idVerificationViewController = storyboard.instantiateViewController(withIdentifier: "IdVerificationViewController") as! IdVerificationViewController
        idVerificationViewController.viewModel = IdVerificationViewModel(moveDataFlow: viewModel.moveServiceFlow)
        self.navigationController?.pushViewController(idVerificationViewController, animated: true)
    }
}

// MARK: - PDTSimpleCalendarViewDelegate
extension MoveStartServiceViewController: PDTSimpleCalendarViewDelegate {
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, isEnabledDate date: Date!) -> Bool {
        
        return viewModel.isValidDate(date)
    }
    
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, didSelect date: Date!) {

        refreshUI(startDate: date)
        controller.dismiss(animated: true, completion: nil)
    }
}
