//
//  MyHomeProfileViewController.swift
//  Mobile
//
//  Created by Sam Francis on 10/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MyHomeProfileViewController: KeyboardAvoidingStickyFooterViewController {
    
    let disposeBag = DisposeBag()

    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet weak var homeTypeInfoLabel: UILabel!
    @IBOutlet weak var homeTypeButton: DisclosureButton!
    
    @IBOutlet weak var heatingFuelInfoLabel: UILabel!
    @IBOutlet weak var heatingFuelButton: DisclosureButton!
    
    @IBOutlet weak var numberOfResidentsInfoLabel: UILabel!
    @IBOutlet weak var numberOfAdultsButton: DisclosureButton!
    @IBOutlet weak var numberOfChildrenButton: DisclosureButton!
    
    @IBOutlet weak var homeSizeInfoLabel: UILabel!
    @IBOutlet weak var homeSizeTextField: FloatLabelTextField!
    
    @IBOutlet weak var saveButton: PrimaryButton!
    
    var accountDetail: AccountDetail!
    
    private lazy var viewModel = MyHomeProfileViewModel(usageService: ServiceFactory.createUsageService(useCache: false),
                                                        accountDetail: self.accountDetail,
                                                        saveAction: self.saveButton.rx.tap.asObservable()
                                                            .filter { [weak self] in self?.saveButton.isEnabled ?? false })
    
    private let didSaveHomeProfileSubject = PublishSubject<Void>()
    private(set) lazy var didSaveHomeProfile: Driver<Void> = self.didSaveHomeProfileSubject.asDriver(onErrorDriveWith: .empty())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let residentialAMIString = String(format: "%@%@", accountDetail.isResidential ? "Residential/" : "Commercial/", accountDetail.isAMIAccount ? "AMI" : "Non-AMI")
        GoogleAnalytics.log(event: .viewHomeProfile,
                             dimensions: [.residentialAMI: residentialAMIString])
        
        styleViews()
        initialLoadSetup()
        bindButtons()
        bindTextField()
        bindSaveResults()
        
        FirebaseUtility.logEvent(.homeProfileStart)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    func styleViews() {
        headerLabel.textColor = .deepGray
        headerLabel.font = SystemFont.regular.of(textStyle: .headline)
        headerLabel.setLineHeight(lineHeight: 24)
        homeTypeInfoLabel.textColor = .deepGray
        homeTypeInfoLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        heatingFuelInfoLabel.textColor = .deepGray
        heatingFuelInfoLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        numberOfResidentsInfoLabel.textColor = .deepGray
        numberOfResidentsInfoLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        homeSizeInfoLabel.textColor = .deepGray
        homeSizeInfoLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        homeSizeTextField.placeholder = NSLocalizedString("Home Size (sq. ft)*", comment: "")
        homeSizeTextField.textField.delegate = self
        homeSizeTextField.textField.returnKeyType = .done
        
        homeSizeTextField.textField.customAccessibilityLabel = NSLocalizedString("Home Size in square feet, required", comment: "")
    }
    
    func initialLoadSetup() {
        scrollView.isHidden = true
        errorLabel.isHidden = true
        loadingIndicator.isHidden = false
        viewModel.initialHomeProfile
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] homeProfile in
                self?.scrollView.isHidden = false
                self?.errorLabel.isHidden = true
                self?.loadingIndicator.isHidden = true
                
                self?.homeTypeButton.valueText = homeProfile.homeType?.displayString
                if let homeType = homeProfile.homeType {
                    self?.viewModel.homeType.accept(homeType)
                }
                
                self?.heatingFuelButton.valueText = homeProfile.heatType?.displayString
                if let heatType = homeProfile.heatType {
                    self?.viewModel.heatType.accept(heatType)
                }
                
                if let numberOfAdults = homeProfile.numberOfAdults {
                    self?.numberOfAdultsButton.valueText = "\(numberOfAdults)"
                    self?.viewModel.numberOfAdults.accept(numberOfAdults)
                }
                
                if let numberOfChildren = homeProfile.numberOfChildren {
                    self?.numberOfChildrenButton.valueText = "\(numberOfChildren)"
                    self?.viewModel.numberOfChildren.accept(numberOfChildren)
                }
                
                if let squareFeet = homeProfile.squareFeet {
                    self?.homeSizeTextField.textField.text = "\(squareFeet)"
                    self?.viewModel.homeSizeEntry.accept(String(squareFeet))
                }
                
                UIAccessibility.post(notification: .screenChanged, argument: self?.view)
            }, onError: { [weak self] _ in
                self?.scrollView.isHidden = true
                self?.errorLabel.isHidden = false
                self?.loadingIndicator.isHidden = true
            })
            .disposed(by: disposeBag)
    }
    
    func bindButtons() {
        viewModel.homeTypeA11y.drive(homeTypeButton.rx.accessibilityLabel).disposed(by: disposeBag)
        viewModel.heatingFuelA11y.drive(heatingFuelButton.rx.accessibilityLabel).disposed(by: disposeBag)
        viewModel.numberOfAdultsA11y.drive(numberOfAdultsButton.rx.accessibilityLabel).disposed(by: disposeBag)
        viewModel.numberOfChildrenA11y.drive(numberOfChildrenButton.rx.accessibilityLabel).disposed(by: disposeBag)
        
        homeTypeButton.rx.tap.asDriver()
            .withLatestFrom(viewModel.homeType.asDriver())
            .drive(onNext: { [weak self] homeType in
                guard let self = self else { return }
                self.homeSizeTextField.textField.resignFirstResponder()
                
                let selectedIndex: Int
                if let homeType = homeType {
                    selectedIndex = HomeType.allCases.firstIndex(of: homeType) ?? 0
                } else {
                    selectedIndex = 0
                }
                PickerView.showStringPicker(withTitle: NSLocalizedString("Select Home Type", comment: ""),
                                data: HomeType.allCases.map { $0.displayString },
                                selectedIndex: selectedIndex,
                                onDone: { [weak self] value, index in
                                    self?.homeTypeButton.valueText = value
                                    self?.viewModel.homeType.accept(HomeType(rawValue: index))
                                },
                                onCancel: nil)
            })
            .disposed(by: disposeBag)
        
        heatingFuelButton.rx.tap.asDriver()
            .withLatestFrom(viewModel.heatType.asDriver())
            .drive(onNext: { [weak self] heatType in
                guard let self = self else { return }
                self.homeSizeTextField.textField.resignFirstResponder()
                
                let selectedIndex: Int
                if let heatType = heatType {
                    selectedIndex = HeatType.allCases.firstIndex(of: heatType) ?? 0
                } else {
                    selectedIndex = 0
                }
                PickerView.showStringPicker(withTitle: NSLocalizedString("Select Fuel Type", comment: ""),
                                data: HeatType.allCases.map { $0.displayString },
                                selectedIndex: selectedIndex,
                                onDone: { [weak self] value, index in
                                    self?.heatingFuelButton.valueText = value
                                    self?.viewModel.heatType.accept(HeatType(rawValue: index))
                                },
                                onCancel: nil)
            })
            .disposed(by: disposeBag)
        
        numberOfAdultsButton.rx.tap.asDriver()
            .withLatestFrom(viewModel.numberOfAdults.asDriver())
            .drive(onNext: { [weak self] numberOfAdults in
                guard let self = self else { return }
                self.homeSizeTextField.textField.resignFirstResponder()
                
                let selectedIndex: Int
                if let numberOfAdults = numberOfAdults {
                    selectedIndex = self.viewModel.numberOfAdultsOptions.firstIndex(of: numberOfAdults) ?? 0
                } else {
                    selectedIndex = 0
                }
                PickerView.showStringPicker(withTitle: NSLocalizedString("Select Number", comment: ""),
                                data: self.viewModel.numberOfAdultsDisplayOptions,
                                selectedIndex: selectedIndex,
                                onDone: { [weak self] value, index in
                                    self?.numberOfAdultsButton.valueText = value
                                    self?.viewModel.numberOfAdults.accept(self?.viewModel.numberOfAdultsOptions[index])
                                },
                                onCancel: nil)
            })
            .disposed(by: disposeBag)
        
        numberOfChildrenButton.rx.tap.asDriver()
            .withLatestFrom(viewModel.numberOfChildren.asDriver())
            .drive(onNext: { [weak self] numberOfChildren in
                guard let self = self else { return }
                self.homeSizeTextField.textField.resignFirstResponder()
                
                let selectedIndex: Int
                if let numberOfChildren = numberOfChildren {
                    selectedIndex = self.viewModel.numberOfChildrenOptions.firstIndex(of: numberOfChildren) ?? 0
                } else {
                    selectedIndex = 0
                }
                PickerView.showStringPicker(withTitle: NSLocalizedString("Select Number", comment: ""),
                                data: self.viewModel.numberOfChildrenDisplayOptions,
                                selectedIndex: selectedIndex,
                                onDone: { [weak self] value, index in
                                    self?.numberOfChildrenButton.valueText = value
                                    self?.viewModel.numberOfChildren.accept(self?.viewModel.numberOfChildrenOptions[index])
                                },
                                onCancel: nil)
            })
            .disposed(by: disposeBag)
        
        viewModel.enableSave.asDriver(onErrorDriveWith: .empty())
            .drive(saveButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        viewModel.saveA11yLabel.drive(saveButton.rx.accessibilityLabel).disposed(by: disposeBag)
    }
    
    @IBAction func saveButtonPress(_ sender: Any) {
        FirebaseUtility.logEvent(.homeProfileSubmit)
    }
    
    func bindTextField() {
        homeSizeTextField.textField.delegate = self
        homeSizeTextField.setKeyboardType(.numberPad)
        
        homeSizeTextField.textField.rx.text
            .asObservable()
            .skip(1)
            .bind(to: viewModel.homeSizeEntry)
            .disposed(by: disposeBag)
        
        viewModel.homeSizeError.asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                if self.homeSizeTextField.textField.hasText {
                    self.homeSizeTextField.setError($0)
                } else {
                    self.homeSizeTextField.setError(nil)
                }
            })
            .disposed(by: disposeBag)
    }
    
    func bindSaveResults() {
        
        viewModel.saveSuccess
            .drive(onNext: { [weak self] in
                FirebaseUtility.logEvent(.homeProfileNetworkComplete)
                self?.didSaveHomeProfileSubject.onNext(())
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        
        viewModel.saveErrors
            .drive(onNext: { [weak self] in
                let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: $0, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        viewModel.saveTracker.asDriver()
            .drive(onNext: { [weak self] in
                if $0 {
                    self?.homeSizeTextField.textField.resignFirstResponder()
                    LoadingView.show()
                } else {
                    LoadingView.hide()
                }
            })
            .disposed(by: disposeBag)
    }
    
}

extension MyHomeProfileViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let characterSet = CharacterSet(charactersIn: string)
        
        return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= 7
    }
}

