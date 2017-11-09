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
    
    init(viewModel: SmartThermostatScheduleViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        let localizedTitle = NSLocalizedString("%@ Schedule", comment: "")
        title = String(format: localizedTitle, viewModel.period.displayString)
    }
    
    override func loadView() {
        super.loadView()
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let saveButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""), style: .done, target: self, action: nil)
        navigationItem.rightBarButtonItem = saveButton
        
        let timeButtonContainer = UIView().usingAutoLayout()
        timeButtonContainer.backgroundColor = .softGray
        
        let timeButton = DisclosureButton().usingAutoLayout()
        let localizedTimeText = NSLocalizedString("Time: %@", comment: "")
        timeButton.labelText = String(format: localizedTimeText, viewModel.periodInfo.startTimeDisplayString)
        
        timeButtonContainer.addSubview(timeButton)
        timeButton.addTabletWidthConstraints(horizontalPadding: 29)
        timeButton.topAnchor.constraint(equalTo: timeButtonContainer.topAnchor, constant: 30).isActive = true
        timeButton.bottomAnchor.constraint(equalTo: timeButtonContainer.bottomAnchor, constant: -30).isActive = true
        timeButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        timeButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                guard let `self` = self else { return }
                PickerView.showTimePicker(withTitle: NSLocalizedString("Select Time", comment: ""),
                                          selectedTime: self.viewModel.periodInfo.startTime,
                                          minTime: self.viewModel.minTime,
                                          maxTime: self.viewModel.maxTime,
                                          onDone: nil,
                                          onCancel: nil)
        })
            .disposed(by: disposeBag)
        
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}
