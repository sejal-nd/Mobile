//
//  PeakRewardsViewController.swift
//  Mobile
//
//  Created by Sam Francis on 11/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class PeakRewardsViewController: UIViewController {
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var mainErrorLabel: UILabel!
    @IBOutlet weak var mainLoadingIndicator: LoadingIndicator!
    
    @IBOutlet weak var deviceButton: DisclosureButton!
    
    @IBOutlet weak var programCardStack: UIStackView!
    
    @IBOutlet weak var overrideButton: DisclosureButton!
    @IBOutlet weak var adjustThermostatButton: DisclosureButton!
    
    @IBOutlet weak var segmentedControl: SegmentedControl!
    
    @IBOutlet weak var scheduleContentStack: UIStackView!
    @IBOutlet weak var wakePeriodCard: SmartThermostatPeriodCard!
    @IBOutlet weak var leavePeriodCard: SmartThermostatPeriodCard!
    @IBOutlet weak var returnPeriodCard: SmartThermostatPeriodCard!
    @IBOutlet weak var sleepPeriodCard: SmartThermostatPeriodCard!
    
    @IBOutlet weak var scheduleErrorView: UIView!
    @IBOutlet weak var scheduleLoadingView: UIView!
    let gradientLayer = CAGradientLayer()
    
    var accountDetail: AccountDetail!
    
    let disposeBag = DisposeBag()
    
    private lazy var viewModel: PeakRewardsViewModel = PeakRewardsViewModel(peakRewardsService: ServiceFactory.createPeakRewardsService(), accountDetail: self.accountDetail)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleViews()
        bindViews()
        bindActions()
    }
    
    func styleViews() {
        gradientLayer.frame = gradientView.bounds
        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor(red: 244/255, green: 245/255, blue: 246/255, alpha: 1).cgColor,
            UIColor(red: 239/255, green: 241/255, blue: 243/255, alpha: 1).cgColor
        ]
        gradientView.layer.addSublayer(gradientLayer)
        
        segmentedControl.items = [TemperatureScale.fahrenheit, TemperatureScale.celsius].map { $0.displayString }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientView.frame = gradientView.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        }
        
        viewModel.rootScreenWillReappear.onNext(())
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        gradientLayer.frame = gradientView.bounds
    }
    
    func bindViews() {
        viewModel.showMainLoadingState.asDriver().not().drive(mainLoadingIndicator.rx.isHidden).disposed(by: disposeBag)
        viewModel.showMainErrorState.asDriver().not().drive(mainErrorLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.showMainContent.asDriver().not().drive(scrollView.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.showScheduleLoadingState.asDriver().not().drive(scheduleLoadingView.rx.isHidden).disposed(by: disposeBag)
        viewModel.showScheduleErrorState.asDriver().not().drive(scheduleErrorView.rx.isHidden).disposed(by: disposeBag)
        viewModel.showScheduleContent.asDriver().not().drive(scheduleContentStack.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.selectedDeviceName.drive(deviceButton.label.rx.text).disposed(by: disposeBag)
        
        viewModel.peakRewardsPrograms
            .drive(onNext: { [weak self] programs in
                guard let `self` = self else { return }
                self.programCardStack.arrangedSubviews
                    .dropFirst() // Don't remove the header label from the stack
                    .forEach(self.programCardStack.removeArrangedSubview)
                
                programs
                    .map(PeakRewardsProgramCard.init)
                    .forEach(self.programCardStack.addArrangedSubview)
            })
            .disposed(by: disposeBag)
        
        viewModel.showAdjustThermostatButton.not().drive(adjustThermostatButton.rx.isHidden).disposed(by: disposeBag)
        
        wakePeriodCard.configure(withPeriod: .wake, periodInfo: viewModel.wakeInfo)
        leavePeriodCard.configure(withPeriod: .leave, periodInfo: viewModel.leaveInfo)
        returnPeriodCard.configure(withPeriod: .return, periodInfo: viewModel.returnInfo)
        sleepPeriodCard.configure(withPeriod: .sleep, periodInfo: viewModel.sleepInfo)

        segmentedControl.selectedIndex.asObservable()
            .skip(1)
            .distinctUntilChanged()
            .map { TemperatureScale(rawValue: $0) ?? .fahrenheit }
            .subscribe(onNext: { TemperatureScaleStore.shared.scale = $0 })
            .disposed(by: disposeBag)
        
        TemperatureScaleStore.shared.scaleObservable
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: .fahrenheit)
            .map { $0.rawValue }
            .drive(segmentedControl.selectedIndex)
            .disposed(by: disposeBag)
    }
    
    func bindActions() {
        deviceButton.rx.tap.asDriver()
            .withLatestFrom(viewModel.devices)
            .map { [unowned self] in (self.viewModel, $0) }
            .map(SelectDeviceViewController.init)
            .drive(onNext: { [weak self] in
                self?.navigationController?.pushViewController($0, animated: true)
            })
            .disposed(by: disposeBag)
        
        wakePeriodCard.rx.touchUpInside.asDriver().withLatestFrom(Driver.combineLatest(viewModel.selectedDevice, viewModel.wakeInfo))
            .map { ($0, SmartThermostatPeriod.wake, $1) }
            .map(SmartThermostatScheduleViewModel.init)
            .map(SmartThermostatScheduleViewController.init)
            .drive(onNext: { [weak self] in
                self?.navigationController?.pushViewController($0, animated: true)
            })
            .disposed(by: disposeBag)
    }

}
