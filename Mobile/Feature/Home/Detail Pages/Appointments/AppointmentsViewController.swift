//
//  AppointmentsViewController.swift
//  Mobile
//
//  Created by Samuel Francis on 10/11/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XLPagerTabStrip
import RxSwift
import RxCocoa

class AppointmentsViewController: ButtonBarPagerTabStripViewController {
    
    var premiseNumber: String!
    var appointments: [Appointment]!
    var appointmentVCs: [AppointmentDetailViewController]!
    
    let disposeBag = DisposeBag()
    
    lazy var viewModel = AppointmentsViewModel(premiseNumber: premiseNumber,
                                               initialAppointments: appointments,
                                               appointmentService: ServiceFactory.createAppointmentService())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Appointment Tracker", comment: "")
        
        viewModel.appointments.asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] appointments in
                guard let self = self else { return }
                guard !appointments.isEmpty else { return }
                
                if self.canAvoidFullReload(newAppointments: appointments) {
                    self.appointments = appointments
                    for i in 0..<appointments.count {
                        let appointment = self.appointments[i]
                        let appointmentVC = self.appointmentVCs[i]
                        appointmentVC.update(withAppointment: appointment)
                    }
                } else {
                    self.appointments = appointments
                    self.reloadPagerTabStripView()
                }
                UIAccessibility.post(notification: .screenChanged, argument: nil)
            })
            .disposed(by: disposeBag)
        
        buttonBarItemSpec = ButtonBarItemSpec<ButtonBarViewCell>.cellClass(width: { _ in 125 })
        buttonBarView.selectedBar.backgroundColor = .primaryColor
        buttonBarView.backgroundColor = .white
        
        settings.style.buttonBarBackgroundColor = .white
        settings.style.buttonBarMinimumInteritemSpacing = 0
        settings.style.buttonBarMinimumLineSpacing = 0
        settings.style.buttonBarLeftContentInset = 55
        settings.style.buttonBarRightContentInset = 55
        settings.style.selectedBarBackgroundColor = .white
        settings.style.selectedBarHeight = 4
        settings.style.selectedBarVerticalAlignment = .bottom
        settings.style.buttonBarItemBackgroundColor = .white
        settings.style.buttonBarItemFont = OpenSans.semibold.of(textStyle: .subheadline)
        settings.style.buttonBarItemTitleColor = .middleGray
        settings.style.buttonBarItemsShouldFillAvailableWidth = false
        settings.style.buttonBarHeight = 48
        
        changeCurrentIndexProgressive = { (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            oldCell?.label.textColor = .middleGray
            oldCell?.label.font = OpenSans.regular.of(textStyle: .subheadline)
            newCell?.label.textColor = .actionBlue
            newCell?.label.font = OpenSans.semibold.of(textStyle: .subheadline)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        if appointments.count == 0 {
            self.buttonBarView.isHidden = true
            self.containerView.bounces = false
            
            let emptyStateViewController = EmptyStateViewController(message: "No appointments found", imageName: "ic_appt_canceled")
            return [emptyStateViewController]
        }
        if appointments.count == 1 {
            self.buttonBarView.isHidden = true
            self.containerView.bounces = false
        } else {
            self.buttonBarView.isHidden = false
            self.containerView.bounces = true
        }
        
        appointmentVCs = appointments
            .map(AppointmentDetailViewModel.init)
            .map(AppointmentDetailViewController.init)
        
        for i in 0..<appointments.count {
            let apptVC = appointmentVCs[i]
            apptVC.index = i
            apptVC.totalCount = appointments.count
        }
        
        return appointmentVCs
    }
    
    private func canAvoidFullReload(newAppointments: [Appointment]) -> Bool {
        // If # of appointments has changed we must do a full reload
        if appointments.count != newAppointments.count {
            return false
        }

        // Ensure all id's remained the same
        for i in 0..<appointments.count {
            let currAppt = appointments[i]
            let newAppt = newAppointments[i]
            if currAppt.id != newAppt.id {
                return false
            }
        }

        return true
    }
}
