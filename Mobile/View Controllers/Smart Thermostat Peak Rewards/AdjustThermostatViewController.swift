//
//  AdjustThermostatViewController.swift
//  Mobile
//
//  Created by Sam Francis on 11/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class AdjustThermostatViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    let viewModel: AdjustThermostatViewModel
    
    let mainContentStack = UIStackView().usingAutoLayout()
    let errorLabel = UILabel().usingAutoLayout()
    let loadingIndicator = LoadingIndicator().usingAutoLayout()
    
    lazy var tempSliderView = TemperatureSliderView(currentTemperature: self.viewModel.currentTemperature,
                                               minTemp: Temperature(value: Double(40), scale: .fahrenheit),
                                               maxTemp: Temperature(value: Double(90), scale: .fahrenheit),
                                               scale: TemperatureScaleStore.shared.scale,
                                               mode: Variable(.cool))
    let permanentHoldSwitch = Switch().usingAutoLayout()
    let modeSegmentedControl = SegmentedControl(frame: .zero).usingAutoLayout()
    let fanSegmentedControl = SegmentedControl(frame: .zero).usingAutoLayout()
    
    private let cancelButton = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""), style: .plain, target: self, action: nil)
    private let saveButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""), style: .done, target: self, action: nil)
    
    init(viewModel: AdjustThermostatViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func loadView() {
        super.loadView()
        buildLayout()
        bindViews()
        bindActions()
        bindSaveStates()
        viewModel.loadInitialData.onNext(())
    }
    
    func buildLayout() {
        title = NSLocalizedString("Adjust Thermostat", comment: "")
        view.backgroundColor = .white
        
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        errorLabel.textColor = .blackText
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        view.addSubview(errorLabel)
        errorLabel.addTabletWidthConstraints(horizontalPadding: 29)
        errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        view.addSubview(loadingIndicator)
        loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
        
        let permanentHoldLabel = UILabel().usingAutoLayout()
        permanentHoldLabel.numberOfLines = 0
        permanentHoldLabel.font = SystemFont.regular.of(textStyle: .headline)
        permanentHoldLabel.textColor = .blackText
        permanentHoldLabel.text = NSLocalizedString("Permanent Hold", comment: "")
        permanentHoldLabel.isAccessibilityElement = false
        permanentHoldLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 1), for: .horizontal)
        permanentHoldLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        permanentHoldSwitch.setContentHuggingPriority(.required, for: .horizontal)
        
        let permanentHoldStack = UIStackView(arrangedSubviews: [permanentHoldLabel, permanentHoldSwitch]).usingAutoLayout()
        permanentHoldStack.axis = .horizontal
        permanentHoldStack.alignment = .center
        permanentHoldStack.spacing = 8
        
        let permanentHoldContainer = UIView()
        permanentHoldContainer.addSubview(permanentHoldStack)
        permanentHoldStack.topAnchor.constraint(equalTo: permanentHoldContainer.topAnchor, constant: 25).isActive = true
        permanentHoldStack.leadingAnchor.constraint(equalTo: permanentHoldContainer.leadingAnchor).isActive = true
        permanentHoldStack.trailingAnchor.constraint(equalTo: permanentHoldContainer.trailingAnchor).isActive = true
        permanentHoldStack.bottomAnchor.constraint(equalTo: permanentHoldContainer.bottomAnchor, constant: -13).isActive = true
        
        let modeLabel = UILabel()
        modeLabel.font = SystemFont.regular.of(textStyle: .headline)
        modeLabel.textColor = .blackText
        modeLabel.text = NSLocalizedString("Mode", comment: "")
        
        modeSegmentedControl.heightAnchor.constraint(equalToConstant: 50).isActive = true
        modeSegmentedControl.items = [NSLocalizedString("Cool", comment: ""),
                                      NSLocalizedString("Heat", comment: ""),
                                      NSLocalizedString("Off", comment: "")]
        
        viewModel.mode.asObservable()
            .bind(to: tempSliderView.mode)
            .disposed(by: disposeBag)
        
        let modeStack = UIStackView(arrangedSubviews: [modeLabel, modeSegmentedControl])
        modeStack.axis = .vertical
        modeStack.spacing = 10
        
        let fanLabel = UILabel()
        fanLabel.font = SystemFont.regular.of(textStyle: .headline)
        fanLabel.textColor = .blackText
        fanLabel.text = NSLocalizedString("Fan", comment: "")
        
        fanSegmentedControl.heightAnchor.constraint(equalToConstant: 50).isActive = true
        fanSegmentedControl.items = [NSLocalizedString("Auto", comment: ""),
                                     NSLocalizedString("Circulate", comment: ""),
                                     NSLocalizedString("On", comment: "")]
        let fanStack = UIStackView(arrangedSubviews: [fanLabel, fanSegmentedControl])
        fanStack.axis = .vertical
        fanStack.spacing = 10
        
        let didYouKnowView = UIView().usingAutoLayout()
        let didYouKnowLabel = UILabel().usingAutoLayout()
        didYouKnowLabel.font = SystemFont.semibold.of(textStyle: .headline)
        didYouKnowLabel.textColor = .blackText
        didYouKnowLabel.text = NSLocalizedString("Did you know?", comment: "")
        
        let didYouKnowDetailLabel = UILabel().usingAutoLayout()
        didYouKnowDetailLabel.font = SystemFont.regular.of(textStyle: .headline)
        didYouKnowDetailLabel.textColor = .blackText
        didYouKnowDetailLabel.numberOfLines = 0
        didYouKnowDetailLabel.text = NSLocalizedString("By turning your thermostat back by 7-10°F for eight hours a day, you can save 10% a year on heating and cooling.", comment: "")
        
        didYouKnowView.addSubview(didYouKnowLabel)
        didYouKnowView.addSubview(didYouKnowDetailLabel)
        
        didYouKnowLabel.topAnchor.constraint(equalTo: didYouKnowView.topAnchor).isActive = true
        didYouKnowLabel.leadingAnchor.constraint(equalTo: didYouKnowView.leadingAnchor).isActive = true
        didYouKnowLabel.trailingAnchor.constraint(equalTo: didYouKnowView.trailingAnchor).isActive = true
        didYouKnowLabel.bottomAnchor.constraint(equalTo: didYouKnowDetailLabel.topAnchor, constant: -10).isActive = true
        didYouKnowDetailLabel.leadingAnchor.constraint(equalTo: didYouKnowView.leadingAnchor).isActive = true
        didYouKnowDetailLabel.trailingAnchor.constraint(equalTo: didYouKnowView.trailingAnchor).isActive = true
        didYouKnowDetailLabel.bottomAnchor.constraint(equalTo: didYouKnowView.bottomAnchor, constant: -15).isActive = true
        
        let scrollView = UIScrollView().usingAutoLayout()
        view.addSubview(scrollView)
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        [tempSliderView, permanentHoldContainer, modeStack, fanStack, didYouKnowView]
            .forEach(mainContentStack.addArrangedSubview)
        mainContentStack.axis = .vertical
        mainContentStack.spacing = 30
        scrollView.addSubview(mainContentStack)
        mainContentStack.addTabletWidthConstraints(horizontalPadding: 29)
        mainContentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 40).isActive = true
        mainContentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -29).isActive = true
    }
    
    func bindViews() {
        viewModel.showMainLoadingState.not().drive(loadingIndicator.rx.isHidden).disposed(by: disposeBag)
        viewModel.showMainContent.not().drive(mainContentStack.rx.isHidden).disposed(by: disposeBag)
        viewModel.showErrorLabel.not().drive(errorLabel.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.showMainContent.asDriver()
            .filter { $0 }
            .drive(onNext: { [weak self] _ in UIAccessibility.post(notification: .screenChanged, argument: self?.view) })
            .disposed(by: disposeBag)
        
        viewModel.showErrorLabel.asDriver()
            .filter { $0 }
            .drive(onNext: { [weak self] _ in UIAccessibility.post(notification: .screenChanged, argument: self?.view) })
            .disposed(by: disposeBag)
        
        viewModel.initialTemp.drive(tempSliderView.currentTemperature).disposed(by: disposeBag)
        viewModel.initialMode.map { SmartThermostatMode.allValues.index(of: $0) ?? 0 }
            .drive(modeSegmentedControl.selectedIndex)
            .disposed(by: disposeBag)
        
        viewModel.initialFan
            .map { SmartThermostatFan.allValues.index(of: $0) ?? 0 }
            .drive(fanSegmentedControl.selectedIndex)
            .disposed(by: disposeBag)
        
        permanentHoldSwitch.accessibilityLabel = NSLocalizedString("Permanent Hold", comment: "")
        viewModel.initialHold.drive(permanentHoldSwitch.rx.isOn).disposed(by: disposeBag)
        
        // Bind to view model
        permanentHoldSwitch.rx.isOn.distinctUntilChanged()
            .do(onNext: {
                Analytics.log(event: $0 ? .permanentHoldOn : .permanentHoldOff)
            })
            .bind(to: viewModel.hold)
            .disposed(by: disposeBag)
        
        modeSegmentedControl.selectedIndex.asObservable()
            .distinctUntilChanged()
            .map { SmartThermostatMode.allValues[$0] }
            .do(onNext: {
                switch $0 {
                case .cool:
                    Analytics.log(event: .systemCool)
                case .heat:
                    Analytics.log(event: .systemHeat)
                case .off:
                    Analytics.log(event: .systemOff)
                }
            })
            .bind(to: viewModel.mode)
            .disposed(by: disposeBag)
        
        fanSegmentedControl.selectedIndex.asObservable()
            .distinctUntilChanged()
            .map { SmartThermostatFan.allValues[$0] }
            .do(onNext: {
                switch $0 {
                case .auto:
                    Analytics.log(event: .fanAuto)
                case .circulate:
                    Analytics.log(event: .fanCirculate)
                case .on:
                    Analytics.log(event: .fanOn)
                }
            })
            .bind(to: viewModel.fan)
            .disposed(by: disposeBag)
    }
    
    func bindActions() {
        cancelButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in self?.navigationController?.popViewController(animated: true) })
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
