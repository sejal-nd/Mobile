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

class MyHomeProfileViewController: UIViewController {
    
    let disposeBag = DisposeBag()

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
    
    private lazy var viewModel = MyHomeProfileViewModel(usageService: ServiceFactory.createUsageService(),
                                                        homeSizeEntry: self.homeSizeTextField.textField.rx.text.orEmpty
                                                            .asObservable()
                                                            .skip(1))

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""),
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(savePressed))
        styleViews()
        bindButtons()
        bindTextField()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        }
    }
    
    func styleViews() {
        headerLabel.numberOfLines = 0
        headerLabel.font = SystemFont.regular.of(textStyle: .headline)
        headerLabel.setLineHeight(lineHeight: 24)
        homeTypeInfoLabel.numberOfLines = 0
        homeTypeInfoLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        heatingFuelInfoLabel.numberOfLines = 0
        heatingFuelInfoLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        numberOfResidentsInfoLabel.numberOfLines = 0
        numberOfResidentsInfoLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        homeSizeInfoLabel.numberOfLines = 0
        homeSizeInfoLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        homeSizeTextField.textField.placeholder = NSLocalizedString("Home Size (sq. ft)", comment: "")
        homeSizeTextField.textField.delegate = self
        homeSizeTextField.textField.returnKeyType = .done
    }
    
    func bindButtons() {
        homeTypeButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                guard let `self` = self else { return }
                PickerView.show(withTitle: NSLocalizedString("Select Home Type", comment: ""),
                                data: self.viewModel.homeTypes,
                                selectedIndex: 0,
                                onDone: { [weak self] value, index in
                                    self?.homeTypeButton.setDetailLabel(text: value, checkHidden: true)
                    },
                                onCancel: {
                                    dLog("cancel!")
                })
            })
            .disposed(by: disposeBag)
        
        heatingFuelButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                guard let `self` = self else { return }
                PickerView.show(withTitle: NSLocalizedString("Select Home Type", comment: ""),
                                data: self.viewModel.heatingFuels,
                                selectedIndex: 0,
                                onDone: { [weak self] value, index in
                                    self?.heatingFuelButton.setDetailLabel(text: value, checkHidden: true)
                    },
                                onCancel: {
                                    dLog("cancel!")
                })
            })
            .disposed(by: disposeBag)
        
        numberOfAdultsButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                guard let `self` = self else { return }
                PickerView.show(withTitle: NSLocalizedString("Select Number", comment: ""),
                                data: self.viewModel.numberOfAdults,
                                selectedIndex: 0,
                                onDone: { [weak self] value, index in
                                    self?.numberOfAdultsButton.setDetailLabel(text: value, checkHidden: true)
                    },
                                onCancel: {
                                    dLog("cancel!")
                })
            })
            .disposed(by: disposeBag)
        
        numberOfChildrenButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                guard let `self` = self else { return }
                PickerView.show(withTitle: NSLocalizedString("Select Number", comment: ""),
                                data: self.viewModel.numberOfChildren,
                                selectedIndex: 0,
                                onDone: { [weak self] value, index in
                                    self?.numberOfChildrenButton.setDetailLabel(text: value, checkHidden: true)
                    },
                                onCancel: {
                                    dLog("cancel!")
                })
            })
            .disposed(by: disposeBag)
    }
    
    func bindTextField() {
        homeSizeTextField.textField.delegate = self
        homeSizeTextField.setKeyboardType(.numberPad)
        NotificationCenter.default.rx.notification(.UIKeyboardWillShow)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] notification in
                guard let `self` = self,
                    let endFrameRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                        return
                }
                
                let insets = UIEdgeInsetsMake(0, 0, endFrameRect.size.height, 0)
                self.scrollView.contentInset = insets
                self.scrollView.scrollIndicatorInsets = insets
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(.UIKeyboardWillHide, object: nil)
            .asDriver(onErrorDriveWith: Driver.empty())
            .drive(onNext: { [weak self] _ in
                self?.scrollView.contentInset = .zero
                self?.scrollView.scrollIndicatorInsets = .zero
            })
            .disposed(by: disposeBag)
        
        viewModel.homeSizeError.asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in
                self?.homeSizeTextField.setError($0)
            })
            .disposed(by: disposeBag)
    }
    
    @objc func savePressed() {
        dLog("Save Pressed")
    }
}

extension MyHomeProfileViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let characterSet = CharacterSet(charactersIn: string)
        
        return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 7
    }
}


