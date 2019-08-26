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
    
    private let scrollView = UIScrollView().usingAutoLayout()
    private let timeButton = DisclosureButtonNew().usingAutoLayout()
    
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

    func buildLayout() {
        addCloseButton()
        
        extendedLayoutIncludesOpaqueBars = true
        
        view.backgroundColor = .white
                
        let timeButtonContainer = UIView().usingAutoLayout()
        timeButtonContainer.addSubview(timeButton)
        timeButton.descriptionText = NSLocalizedString("Time", comment: "")
        timeButton.addTabletWidthConstraints(horizontalPadding: 20)
        timeButton.topAnchor.constraint(equalTo: timeButtonContainer.topAnchor, constant: 30).isActive = true
        timeButton.bottomAnchor.constraint(equalTo: timeButtonContainer.bottomAnchor, constant: -30).isActive = true
        timeButton.heightAnchor.constraint(equalToConstant: 55).isActive = true
        
        let minTemp = Temperature(value: Double(40), scale: .fahrenheit)
        let maxTemp = Temperature(value: Double(90), scale: .fahrenheit)
        let coolTempSliderView = TemperatureSliderView(currentTemperature: viewModel.coolTemp,
                                                       minTemp: minTemp,
                                                       maxTemp: maxTemp,
                                                       scale: TemperatureScaleStore.shared.scale,
                                                       mode: Variable(.cool)).usingAutoLayout()
        
        let heatTempSliderView = TemperatureSliderView(currentTemperature: viewModel.heatTemp,
                                                       minTemp: minTemp,
                                                       maxTemp: maxTemp,
                                                       scale: TemperatureScaleStore.shared.scale,
                                                       mode: Variable(.heat)).usingAutoLayout()
        
        let sliderStack = UIStackView(arrangedSubviews: [coolTempSliderView, heatTempSliderView]).usingAutoLayout()
        sliderStack.axis = .vertical
        sliderStack.spacing = 30
        
        let sliderStackContainer = UIView().usingAutoLayout()
        sliderStackContainer.addSubview(sliderStack)
        sliderStack.addTabletWidthConstraints(horizontalPadding: 20)
        
        sliderStack.topAnchor.constraint(equalTo: sliderStackContainer.topAnchor).isActive = true
        sliderStack.bottomAnchor.constraint(equalTo: sliderStackContainer.bottomAnchor).isActive = true
        
        let didYouKnowView = UIView().usingAutoLayout()
        let didYouKnowLabel = UILabel().usingAutoLayout()
        didYouKnowLabel.font = SystemFont.semibold.of(textStyle: .headline)
        didYouKnowLabel.textColor = .deepGray
        didYouKnowLabel.text = NSLocalizedString("Did you know?", comment: "")
        
        let didYouKnowDetailLabel = UILabel().usingAutoLayout()
        didYouKnowDetailLabel.font = SystemFont.regular.of(textStyle: .headline)
        didYouKnowDetailLabel.textColor = .deepGray
        didYouKnowDetailLabel.numberOfLines = 0
        didYouKnowDetailLabel.text = viewModel.didYouKnowText
        
        didYouKnowView.addSubview(didYouKnowLabel)
        didYouKnowView.addSubview(didYouKnowDetailLabel)
        
        didYouKnowLabel.addTabletWidthConstraints(horizontalPadding: 20)
        didYouKnowLabel.topAnchor.constraint(equalTo: didYouKnowView.topAnchor, constant: 26).isActive = true
        didYouKnowLabel.bottomAnchor.constraint(equalTo: didYouKnowDetailLabel.topAnchor, constant: -10).isActive = true
        didYouKnowDetailLabel.addTabletWidthConstraints(horizontalPadding: 20)
        didYouKnowDetailLabel.bottomAnchor.constraint(equalTo: didYouKnowView.bottomAnchor, constant: -15).isActive = true
        
        scrollView.contentInsetAdjustmentBehavior = .automatic
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        
        let saveButton = PrimaryButton(frame: .zero).usingAutoLayout()
        saveButton.setTitle(NSLocalizedString("Save Changes", comment: ""), for: .normal)
        saveButton.rx.tap.bind(to: viewModel.saveAction).disposed(by: disposeBag)
        let stickyFooterView = StickyFooterView().usingAutoLayout()
        stickyFooterView.addSubview(saveButton)
        view.addSubview(stickyFooterView)
        
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: stickyFooterView.topAnchor).isActive = true
        
        stickyFooterView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        stickyFooterView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        stickyFooterView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        saveButton.topAnchor.constraint(equalTo: stickyFooterView.topAnchor, constant: 15).isActive = true
        saveButton.addTabletWidthConstraints(horizontalPadding: 20)
        saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -15).isActive = true
        saveButton.heightAnchor.constraint(equalToConstant: 55).isActive = true
        
        let mainStack = UIStackView(arrangedSubviews: [timeButtonContainer, sliderStackContainer, didYouKnowView]).usingAutoLayout()
        mainStack.axis = .vertical
        mainStack.spacing = 24
        
        scrollView.addSubview(mainStack)
        mainStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 0).isActive = true
        mainStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20).isActive = true
        mainStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        mainStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        mainStack.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
    }
    
    func bindViews() {
        viewModel.timeButtonText
            .drive(timeButton.rx.valueText)
            .disposed(by: disposeBag)
        
        viewModel.timeButtonText
            .drive(timeButton.rx.accessibilityLabel)
            .disposed(by: disposeBag)
    }
    
    func bindActions() {
        timeButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                PickerView.showTimePicker(withTitle: NSLocalizedString("Select Time", comment: ""),
                                          selectedTime: self.viewModel.periodInfo.startTime,
                                          minTime: self.viewModel.minTime,
                                          maxTime: self.viewModel.maxTime,
                                          onDone: { [weak self] in self?.viewModel.startTime.onNext($0) },
                                          onCancel: nil)
            })
            .disposed(by: disposeBag)
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
                self?.dismissModal()
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
