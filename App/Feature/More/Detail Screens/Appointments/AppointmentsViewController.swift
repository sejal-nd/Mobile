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
    
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var noNetworkView: NoNetworkConnectionView!
    @IBOutlet weak var emptyStateView: StateView!
    @IBOutlet weak var errorStateView: StateView!
    @IBOutlet weak var contactUsButton: PrimaryButton!
    
    var appointments: [Appointment] = [Appointment]()
    var appointmentVCs: [AppointmentDetailViewController]!
    var pollingDisposable: Disposable?
    
    let disposeBag = DisposeBag()
    
    lazy var viewModel = AppointmentsViewModel(initialAppointments: appointments)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Appointment Tracker", comment: "")
        
        viewModel.showLoadingState.not().drive(loadingIndicator.rx.isHidden).disposed(by: disposeBag)
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
            }).disposed(by: disposeBag)
        
        viewModel.showNoNetworkState.not().drive(self.noNetworkView.rx.isHidden).disposed(by: disposeBag)
        viewModel.showErrorState.not().drive(self.errorStateView.rx.isHidden).disposed(by: disposeBag)
        viewModel.showEmptyState.not().drive(self.emptyStateView.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.showEmptyState.drive(onNext: { empty in
            self.emptyStateView.isHidden = !empty
            }).disposed(by: disposeBag)
        
        noNetworkView.reload
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: {
                self.viewModel.fetchAllData()
            }).disposed(by: disposeBag)
        
        pollingDisposable = viewModel.startPolling()
            .subscribe()
        
        initStates()
        
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
        
        contactUsButton.rx
            .touchUpInside
            .asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                UIApplication.shared.openPhoneNumberIfCan(self.viewModel.contactNumber)
            }).disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.pollingDisposable?.dispose()
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        if appointments.count == 0 {
            self.buttonBarView.isHidden = true
            self.containerView.bounces = false
            
            return [EmptyChildViewController()]
        }
        else if appointments.count == 1 {
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
    
    private func initStates() {
        self.emptyStateView.stateMessage = "You have no appointments scheduled."
        self.emptyStateView.stateImageName = "img_appt_empty"
        self.errorStateView.stateMessage = "Error getting appointments"
//        self.errorStateView.stateImageName = "ic_appt_canceled"
    }
}
