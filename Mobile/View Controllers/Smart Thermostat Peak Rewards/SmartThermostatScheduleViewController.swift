//
//  SmartThermostatScheduleViewController.swift
//  Mobile
//
//  Created by Sam Francis on 11/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class SmartThermostatScheduleViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    let viewModel: SmartThermostatScheduleViewModel
    
    private let timeButton = DisclosureButton().usingAutoLayout()
    private let saveButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""), style: .done, target: self, action: nil)
    
    private(set) lazy var saveSuccess: Observable<Void> = self.viewModel.saveSuccess
    
    init(viewModel: SmartThermostatScheduleViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        let localizedTitle = NSLocalizedString("%@ Schedule", comment: "")
        title = String(format: localizedTitle, viewModel.period.displayString)
    }
    
    override func loadView() {
        super.loadView()
        buildLayout()
        bindViews()
        bindActions()
        bindSaveStates()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        }
    }
    
    func buildLayout() {
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = saveButton
        
        let timeButtonContainer = UIView().usingAutoLayout()
        timeButtonContainer.backgroundColor = .softGray
        
        timeButtonContainer.addSubview(timeButton)
        timeButton.addTabletWidthConstraints(horizontalPadding: 29)
        timeButton.topAnchor.constraint(equalTo: timeButtonContainer.topAnchor, constant: 30).isActive = true
        timeButton.bottomAnchor.constraint(equalTo: timeButtonContainer.bottomAnchor, constant: -30).isActive = true
        timeButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        let tempRange: CountableClosedRange<Int>
        switch TemperatureScaleStore.shared.scale {
        case .fahrenheit:
            tempRange = 40...90
        case .celsius:
            tempRange = 5...32
        }
        let coolTempSliderView = TemperatureSliderView(currentTemperature: viewModel.coolTemp,
                                                       tempRange: tempRange,
                                                       scale: TemperatureScaleStore.shared.scale,
                                                       coolOrHeat: .cool).usingAutoLayout()
        
        let heatTempSliderView = TemperatureSliderView(currentTemperature: viewModel.heatTemp,
                                                       tempRange: tempRange,
                                                       scale: TemperatureScaleStore.shared.scale,
                                                       coolOrHeat: .heat).usingAutoLayout()
        
        let sliderStack = UIStackView(arrangedSubviews: [coolTempSliderView, heatTempSliderView]).usingAutoLayout()
        sliderStack.axis = .vertical
        sliderStack.spacing = 30
        
        let sliderStackContainer = UIView().usingAutoLayout()
        sliderStackContainer.addSubview(sliderStack)
        sliderStack.addTabletWidthConstraints(horizontalPadding: 27)
        
        sliderStack.topAnchor.constraint(equalTo: sliderStackContainer.topAnchor).isActive = true
        sliderStack.bottomAnchor.constraint(equalTo: sliderStackContainer.bottomAnchor).isActive = true
        
        let mainStack = UIStackView(arrangedSubviews: [timeButtonContainer, sliderStackContainer]).usingAutoLayout()
        mainStack.axis = .vertical
        mainStack.spacing = 24
        
        view.addSubview(mainStack)
        mainStack.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
    
    func bindViews() {
        viewModel.updatedPeriodInfo
            .map {
                let localizedTimeText = NSLocalizedString("Time: %@", comment: "")
                return String(format: localizedTimeText, $0.startTimeDisplayString)
            }
            .asDriver(onErrorDriveWith: .empty())
            .drive(timeButton.label.rx.text)
            .disposed(by: disposeBag)
    }
    
    func bindActions() {
        timeButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                guard let `self` = self else { return }
                PickerView.showTimePicker(withTitle: NSLocalizedString("Select Time", comment: ""),
                                          selectedTime: self.viewModel.periodInfo.startTime,
                                          minTime: self.viewModel.minTime,
                                          maxTime: self.viewModel.maxTime,
                                          onDone: { [weak self] in self?.viewModel.startTime.onNext($0) },
                                          onCancel: nil)
            })
            .disposed(by: disposeBag)
        
        saveButton.rx.tap.bind(to: viewModel.saveAction).disposed(by: disposeBag)
    }
    
    func bindSaveStates() {
        viewModel.saveTracker.asDriver()
            .drive(onNext: {
                if $0 {
                    LoadingView.show(animated: true)
                } else {
                    LoadingView.hide(animated: true, nil)
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.saveSuccess.asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        
        viewModel.saveError.asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] errorDescription in
                let alert = UIAlertController(title: "Error", message: errorDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}
