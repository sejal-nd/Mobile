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
                
                self.appointments = appointments
                
                if appointments.count == 1 {
                    self.buttonBarView.isHidden = true
                    self.containerView.bounces = false
                } else {
                    self.buttonBarView.isHidden = false
                    self.containerView.bounces = true
                }
                
                self.reloadPagerTabStripView()
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
        navigationController?.setColoredNavBar()
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return appointments
            .map(AppointmentDetailViewModel.init)
            .map(AppointmentDetailViewController.init)
    }
}
