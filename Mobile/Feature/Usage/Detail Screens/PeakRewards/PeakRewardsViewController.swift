//
//  PeakRewardsViewController.swift
//  Mobile
//
//  Created by Sam Francis on 11/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

class PeakRewardsViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var mainErrorLabel: UILabel!
    @IBOutlet weak var mainLoadingIndicator: LoadingIndicator!
    
    @IBOutlet weak var deviceSelectionStack: UIStackView!
    @IBOutlet weak var deviceButton: DisclosureButtonNew!
    
    @IBOutlet weak var programCardStack: UIStackView!
    @IBOutlet weak var cyclingStatusLabel: UILabel!
    
    @IBOutlet weak var overrideButton: DisclosureButtonNew!
    @IBOutlet weak var adjustThermostatButton: DisclosureButtonNew!
    
    @IBOutlet weak var adjustScaleLabel: UILabel!
    @IBOutlet weak var segmentedControl: SegmentedControl!
    
    @IBOutlet weak var scheduleHeaderStack: UIStackView!
    @IBOutlet weak var scheduleContentStack: UIStackView!
    @IBOutlet weak var wakePeriodCard: SmartThermostatPeriodCard!
    @IBOutlet weak var leavePeriodCard: SmartThermostatPeriodCard!
    @IBOutlet weak var returnPeriodCard: SmartThermostatPeriodCard!
    @IBOutlet weak var sleepPeriodCard: SmartThermostatPeriodCard!
    
    @IBOutlet weak var coolLegendLabel: UILabel!
    @IBOutlet weak var heatLegendLabel: UILabel!
    
    @IBOutlet weak var scheduleErrorView: UIView!
    @IBOutlet weak var scheduleLoadingView: UIView!
    
    var accountDetail: AccountDetail!
    
    let disposeBag = DisposeBag()
    
    private lazy var viewModel: PeakRewardsViewModel = PeakRewardsViewModel(peakRewardsService: ServiceFactory.createPeakRewardsService(), accountDetail: self.accountDetail)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleViews()
        bindViews()
        bindActions()
        viewModel.loadInitialData.onNext(())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func styleViews() {
        cyclingStatusLabel.textColor = .deepGray
        cyclingStatusLabel.font = OpenSans.regular.of(textStyle: .headline)
        adjustScaleLabel.textColor = .deepGray
        adjustScaleLabel.font = OpenSans.regular.of(textStyle: .headline)
        segmentedControl.items = [TemperatureScale.fahrenheit, TemperatureScale.celsius].map { $0.displayString }
        
        coolLegendLabel.textColor = .deepGray
        coolLegendLabel.font = OpenSans.regular.of(textStyle: .caption1)
        heatLegendLabel.textColor = .deepGray
        heatLegendLabel.font = OpenSans.regular.of(textStyle: .caption1)
    }
    
    func bindViews() {
        viewModel.showMainLoadingState.asDriver().not().drive(mainLoadingIndicator.rx.isHidden).disposed(by: disposeBag)
        viewModel.showMainErrorState.asDriver().not().drive(mainErrorLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.showMainContent.asDriver().not().drive(scrollView.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.showMainContent.asDriver()
            .filter { $0 }
            .drive(onNext: { [weak self] _ in UIAccessibility.post(notification: .screenChanged, argument: self?.scrollView) })
            .disposed(by: disposeBag)
        
        viewModel.showMainErrorState.asDriver()
            .filter { $0 }
            .drive(onNext: { [weak self] _ in UIAccessibility.post(notification: .screenChanged, argument: self?.mainErrorLabel) })
            .disposed(by: disposeBag)
        
        viewModel.showDeviceButton.not().drive(deviceSelectionStack.rx.isHidden).disposed(by: disposeBag)
        viewModel.deviceButtonValueText.drive(deviceButton.rx.valueText).disposed(by: disposeBag)
        viewModel.deviceButtonValueText.map {
            return String.localizedStringWithFormat("Device: %@", $0)
        }.drive(deviceButton.rx.accessibilityLabel).disposed(by: disposeBag)
        
        viewModel.programCardsData.map { $0.isEmpty }.drive(programCardStack.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.selectedDeviceIsSmartThermostat.asDriver().not().drive(scheduleHeaderStack.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.showScheduleContent.asDriver().not().drive(scheduleContentStack.rx.isHidden).disposed(by: disposeBag)
        viewModel.showScheduleLoadingState.asDriver().not().drive(scheduleLoadingView.rx.isHidden).disposed(by: disposeBag)
        viewModel.showScheduleErrorState.asDriver().not().drive(scheduleErrorView.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.showScheduleContent.asDriver()
            .filter { $0 }
            .drive(onNext: { [weak self] _ in UIAccessibility.post(notification: .screenChanged, argument: self?.scheduleContentStack) })
            .disposed(by: disposeBag)
        
        viewModel.showScheduleErrorState.asDriver()
            .filter { $0 }
            .drive(onNext: { [weak self] _ in UIAccessibility.post(notification: .screenChanged, argument: self?.scheduleErrorView) })
            .disposed(by: disposeBag)
        
        viewModel.programCardsData
            .drive(onNext: { [weak self] programCardsData in
                guard let self = self else { return }
                self.programCardStack.arrangedSubviews
                    .dropFirst() // Don't remove the header label from the stack
                    .forEach {
                        self.programCardStack.removeArrangedSubview($0)
                        $0.removeFromSuperview()
                }
                
                programCardsData
                    .map(PeakRewardsProgramCard.init)
                    .forEach(self.programCardStack.addArrangedSubview)
            })
            .disposed(by: disposeBag)
        
        viewModel.selectedDeviceIsSmartThermostat.not().drive(adjustThermostatButton.rx.isHidden).disposed(by: disposeBag)
        
        wakePeriodCard.configure(withPeriod: .wake, periodInfo: viewModel.wakeInfo)
        leavePeriodCard.configure(withPeriod: .leave, periodInfo: viewModel.leaveInfo)
        returnPeriodCard.configure(withPeriod: .return, periodInfo: viewModel.returnInfo)
        sleepPeriodCard.configure(withPeriod: .sleep, periodInfo: viewModel.sleepInfo)
        
        segmentedControl.selectedIndex.value = TemperatureScaleStore.shared.scale.rawValue
    }
    
    func bindActions() {
        deviceButton.rx.tap.asDriver()
            .withLatestFrom(viewModel.devices)
            .map { [unowned self] in (self.viewModel, $0) }
            .map(SelectDeviceViewController.init)
            .drive(onNext: { [weak self] in
                let largeTitleNavController = LargeTitleNavigationController(rootViewController: $0)
                self?.present(largeTitleNavController, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        overrideButton.rx.tap.asDriver()
            .withLatestFrom(viewModel.selectedDevice)
            .map { [unowned self] in (self.viewModel.peakRewardsService,
                                      self.viewModel.accountDetail,
                                      $0,
                                      self.viewModel.peakRewardsOverridesEvents,
                                      self.viewModel.peakRewardsSummaryFetchTracker.asDriver()) }
            .map(OverrideViewModel.init)
            .map(OverrideViewController.init)
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                $0.viewModel.saveSuccess
                    .asDriver(onErrorDriveWith: .empty())
                    .delay(0.5)
                    .drive(onNext: { [weak self] in
                        self?.view.makeToast(NSLocalizedString("Override scheduled", comment: ""))
                    })
                    .disposed(by: $0.disposeBag)
                
                Observable.merge($0.viewModel.saveSuccess, $0.viewModel.cancelSuccess)
                    .bind(to: self.viewModel.overridesUpdated)
                    .disposed(by: $0.disposeBag)
                
                let largeTitleNavController = LargeTitleNavigationController(rootViewController: $0)
                self.present(largeTitleNavController, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        segmentedControl.selectedIndex.asObservable()
            .skip(1)
            .distinctUntilChanged()
            .map { TemperatureScale(rawValue: $0) ?? .fahrenheit }
            .subscribe(onNext: { TemperatureScaleStore.shared.scale = $0 })
            .disposed(by: disposeBag)
        
        adjustThermostatButton.rx.tap.asDriver()
            .withLatestFrom(viewModel.selectedDevice)
            .map { [unowned self] in (ServiceFactory.createPeakRewardsService(), self.viewModel.accountDetail, $0) }
            .map(AdjustThermostatViewModel.init)
            .map(AdjustThermostatViewController.init)
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                $0.viewModel.saveSuccess
                    .asDriver(onErrorDriveWith: .empty())
                    .delay(0.5)
                    .drive(onNext: { [weak self] in
                        self?.view.makeToast(NSLocalizedString("Thermostat settings saved", comment: ""))
                    })
                    .disposed(by: $0.disposeBag)
                let largeTitleNavController = LargeTitleNavigationController(rootViewController: $0)
                self.present(largeTitleNavController, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        Driver.merge(
            wakePeriodCard.rx.touchUpInside.asDriver()
                .withLatestFrom(Driver.combineLatest(viewModel.selectedDevice, Driver.just(SmartThermostatPeriod.wake), viewModel.deviceSchedule)),
            leavePeriodCard.rx.touchUpInside.asDriver()
                .withLatestFrom(Driver.combineLatest(viewModel.selectedDevice, Driver.just(SmartThermostatPeriod.leave), viewModel.deviceSchedule)),
            returnPeriodCard.rx.touchUpInside.asDriver()
                .withLatestFrom(Driver.combineLatest(viewModel.selectedDevice, Driver.just(SmartThermostatPeriod.return), viewModel.deviceSchedule)),
            sleepPeriodCard.rx.touchUpInside.asDriver()
                .withLatestFrom(Driver.combineLatest(viewModel.selectedDevice, Driver.just(SmartThermostatPeriod.sleep), viewModel.deviceSchedule))
            )
            .map { [unowned self] in (ServiceFactory.createPeakRewardsService(), self.viewModel.accountDetail, $0, $1, $2) }
            .map(SmartThermostatScheduleViewModel.init)
            .map(SmartThermostatScheduleViewController.init)
            .drive(onNext: { [weak self] vc in
                guard let self = self else { return }
                vc.saveSuccess.bind(to: self.viewModel.deviceScheduleChanged).disposed(by: vc.disposeBag)
                vc.saveSuccess.asDriver(onErrorDriveWith: .empty())
                    .delay(0.5)
                    .drive(onNext: { [weak self] in
                        self?.view.showToast(NSLocalizedString("Schedule updated", comment: ""))
                    })
                    .disposed(by: vc.disposeBag)
                let largeTitleNavController = LargeTitleNavigationController(rootViewController: vc)
                self.present(largeTitleNavController, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }

}
