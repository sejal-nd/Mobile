//
//  OverrideViewController.swift
//  Mobile
//
//  Created by Sam Francis on 11/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt
import PDTSimpleCalendar

class OverrideViewController: UIViewController {
    
    let viewModel: OverrideViewModel

    let disposeBag = DisposeBag()
    
    let mainStack = UIStackView().usingAutoLayout()
    let errorLabel = UILabel().usingAutoLayout()
    let loadingIndicator = LoadingIndicator().usingAutoLayout()
    
    private let cancelButton = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""), style: .plain, target: self, action: nil)
    private let saveButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""), style: .done, target: self, action: nil)
    
    let dateButton = DisclosureButton()
    
    let scheduledSerialLabel = UILabel()
    let scheduledDateLabel = UILabel()
    let scheduledStack = UIStackView()
    
    let activeSerialLabel = UILabel()
    let activeDateLabel = UILabel()
    let activeStack = UIStackView()
    
    let scheduledCancelButton = UIButton(type: .system)
    
    init(viewModel: OverrideViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        super.loadView()
        
        buildLayout()
        bindViews()
        bindActions()
        bindSaveStates()
    }
    
    func buildLayout() {
        title = NSLocalizedString("Override", comment: "")
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
        
        let topLabel = UILabel()
        topLabel.text = NSLocalizedString("Select a date to override an Energy Savings Day", comment: "")
        topLabel.textColor = .blackText
        topLabel.font = SystemFont.semibold.of(textStyle: .headline)
        topLabel.numberOfLines = 0
        topLabel.setLineHeight(lineHeight: 24)
        
        dateButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        let scheduledTitleLabel = UILabel()
        scheduledTitleLabel.text = NSLocalizedString("Scheduled Overrides", comment: "")
        scheduledTitleLabel.textColor = .blackText
        scheduledTitleLabel.font = OpenSans.bold.of(textStyle: .title1)
        topLabel.numberOfLines = 0
        
        scheduledSerialLabel.textColor = .blackText
        scheduledSerialLabel.font = OpenSans.regular.of(textStyle: .title1)
        scheduledSerialLabel.numberOfLines = 0
        scheduledSerialLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 1), for: .horizontal)
        
        scheduledDateLabel.textColor = .blackText
        scheduledDateLabel.font = OpenSans.regular.of(textStyle: .title1)
        scheduledDateLabel.numberOfLines = 0
        scheduledDateLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 1), for: .horizontal)
        
        let scheduledLabelStack = UIStackView(arrangedSubviews: [scheduledSerialLabel, scheduledDateLabel])
        scheduledLabelStack.axis = .vertical
        scheduledLabelStack.alignment = .leading
        scheduledLabelStack.spacing = 4
        
        scheduledCancelButton.setTitle(NSLocalizedString("Cancel", comment: ""), for: .normal)
        scheduledCancelButton.setTitleColor(.actionBlue, for: .normal)
        scheduledCancelButton.titleLabel?.font = OpenSans.regular.of(size: 18)
        
        let scheduledCardStack = UIStackView(arrangedSubviews: [scheduledLabelStack, scheduledCancelButton]).usingAutoLayout()
        scheduledCardStack.axis = .horizontal
        scheduledCardStack.alignment = .center
        scheduledCardStack.spacing = 4
        
        let scheduledCardView = UIView()
        scheduledCardView.layer.cornerRadius = 2
        scheduledCardView.backgroundColor = .white
        scheduledCardView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        
        scheduledCardView.addSubview(scheduledCardStack)
        scheduledCardStack.topAnchor.constraint(equalTo: scheduledCardView.topAnchor, constant: 20).isActive = true
        scheduledCardStack.bottomAnchor.constraint(equalTo: scheduledCardView.bottomAnchor, constant: -20).isActive = true
        scheduledCardStack.leadingAnchor.constraint(equalTo: scheduledCardView.leadingAnchor, constant: 20).isActive = true
        scheduledCardStack.trailingAnchor.constraint(equalTo: scheduledCardView.trailingAnchor, constant: -20).isActive = true
        
        scheduledStack.axis = .vertical
        scheduledStack.spacing = 10
        scheduledStack.addArrangedSubview(scheduledTitleLabel)
        scheduledStack.addArrangedSubview(scheduledCardView)
        
        let activeTitleLabel = UILabel()
        activeTitleLabel.text = NSLocalizedString("Active Overrides", comment: "")
        activeTitleLabel.textColor = .blackText
        activeTitleLabel.font = OpenSans.bold.of(textStyle: .title1)
        topLabel.numberOfLines = 0
        
        activeSerialLabel.textColor = .blackText
        activeSerialLabel.font = OpenSans.regular.of(textStyle: .title1)
        activeSerialLabel.numberOfLines = 0
        activeSerialLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 1), for: .horizontal)
        
        activeDateLabel.textColor = .blackText
        activeDateLabel.font = OpenSans.regular.of(textStyle: .title1)
        activeDateLabel.numberOfLines = 0
        activeDateLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 1), for: .horizontal)
        
        let activeLabelStack = UIStackView(arrangedSubviews: [activeSerialLabel, activeDateLabel])
        activeLabelStack.axis = .vertical
        activeLabelStack.alignment = .leading
        activeLabelStack.spacing = 4
        
        activeStack.axis = .vertical
        activeStack.spacing = 10
        activeStack.addArrangedSubview(activeTitleLabel)
        activeStack.addArrangedSubview(activeLabelStack)
        
        [topLabel, dateButton, scheduledStack, activeStack].forEach(mainStack.addArrangedSubview)
        mainStack.axis = .vertical
        mainStack.spacing = 30
        
        let contentView = UIView().usingAutoLayout()
        contentView.addSubview(mainStack)
        mainStack.addTabletWidthConstraints(horizontalPadding: 29)
        mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20).isActive = true
        mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30).isActive = true
        
        let scrollView = UIScrollView().usingAutoLayout()
        scrollView.addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        contentView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        
        view.addSubview(scrollView)
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
    }
    
    func bindViews() {
        viewModel.showMainLoadingState.not().drive(loadingIndicator.rx.isHidden).disposed(by: disposeBag)
        viewModel.showMainContent.not().drive(mainStack.rx.isHidden).disposed(by: disposeBag)
        viewModel.showErrorLabel.not().drive(errorLabel.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.enableSaveButton.drive(saveButton.rx.isEnabled).disposed(by: disposeBag)
        viewModel.enableDateButton.drive(dateButton.rx.isEnabled).disposed(by: disposeBag)
        viewModel.dateButtonText.drive(dateButton.label.rx.text).disposed(by: disposeBag)
        viewModel.dateButtonA11yText.drive(dateButton.rx.accessibilityLabel).disposed(by: disposeBag)
        
        viewModel.showScheduledOverride.not().drive(scheduledStack.rx.isHidden).disposed(by: disposeBag)
        viewModel.showActiveOverride.not().drive(activeStack.rx.isHidden).disposed(by: disposeBag)
        
        scheduledSerialLabel.text = viewModel.scheduledSerialText
        viewModel.scheduledDateText.drive(scheduledDateLabel.rx.text).disposed(by: disposeBag)
        
        activeSerialLabel.text = viewModel.activeSerialText
        viewModel.activeDateText.drive(activeDateLabel.rx.text).disposed(by: disposeBag)
    }
    
    func bindActions() {
        saveButton.rx.tap.bind(to: viewModel.saveAction).disposed(by: disposeBag)
        cancelButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        scheduledCancelButton.rx.tap.bind(to: viewModel.cancelAction).disposed(by: disposeBag)
        
        dateButton.rx.tap.asObservable()
            .withLatestFrom(viewModel.selectedDate.startWith(Calendar.opCo.startOfDay(for: Date())))
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                let backItem = UIBarButtonItem()
                backItem.title = NSLocalizedString("Back", comment: "")
                self.navigationItem.backBarButtonItem = backItem
                
                let calendarVC = PDTSimpleCalendarViewController()
                calendarVC.calendar = .opCo
                calendarVC.delegate = self
                calendarVC.title = NSLocalizedString("Select Override Date", comment: "")
                
                let components = Calendar.opCo.dateComponents([.year, .month, .day], from: $0)
                if let deviceTimeDate = Calendar.current.date(from: components) {
                    calendarVC.selectedDate = deviceTimeDate
                }
                
                self.navigationController?.pushViewController(calendarVC, animated: true)
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
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        
        viewModel.cancelSuccess.asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in
                self?.view.showToast(NSLocalizedString("Override canceled", comment: ""))
            })
            .disposed(by: disposeBag)
        
        viewModel.error.asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] (title, message) in
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}

extension OverrideViewController: PDTSimpleCalendarViewDelegate {
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, isEnabledDate date: Date!) -> Bool {
        let components = Calendar.opCo.dateComponents([.year, .month, .day], from: date)
        guard let opCoTimeDate = Calendar.opCo.date(from: components) else { return false }
        
        let today = Calendar.opCo.startOfDay(for: Date())
        var addDaysComponents = DateComponents()
        addDaysComponents.day = 30
        let latestDay = Calendar.opCo.date(byAdding: addDaysComponents, to: today)!
        
        return opCoTimeDate >= today && opCoTimeDate <= latestDay
    }
    
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, didSelect date: Date!) {
        let components = Calendar.opCo.dateComponents([.year, .month, .day], from: date)
        guard let opCoTimeDate = Calendar.opCo.date(from: components) else { return }
        viewModel.selectedDate.onNext(opCoTimeDate)
    }
}
