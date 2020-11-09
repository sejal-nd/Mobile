//
//  RegistrationValidateAccountViewController.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import PDTSimpleCalendar

class RegistrationValidateAccountViewControllerNew: KeyboardAvoidingStickyFooterViewController {

    let disposeBag = DisposeBag()
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var registrationFormView: UIView!

    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var accountNumberView: UIView!
    @IBOutlet weak var accountNumberTextField: FloatLabelTextField!
    @IBOutlet weak var phoneNumberTextField: FloatLabelTextField!
    @IBOutlet weak var identifierTextField: FloatLabelTextField!
    @IBOutlet weak var amountDueTextField: FloatLabelTextField!
    @IBOutlet weak var dueDateButton: DisclosureButton!
    @IBOutlet weak var lastBillInformationLabel: UILabel!
    
    @IBOutlet weak var illustrationImageView: UIImageView!
    
    @IBOutlet weak var questionMarkButton: UIButton!
    @IBOutlet weak var identifierDescriptionLabel: UILabel!
    
    @IBOutlet weak var segmentContainer: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var segmentedControl: SegmentedControl!
    @IBOutlet weak var continueButton: PrimaryButton!

    let viewModel = RegistrationViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Register", comment: "")
        
        viewModel.validateAccountContinueEnabled.drive(continueButton.rx.isEnabled).disposed(by: disposeBag)
        
        instructionLabel.textColor = .deepGray
        instructionLabel.text = NSLocalizedString("To start, let's find your residential or business service account using your personal/business information or bill details.", comment: "")
        instructionLabel.font = SystemFont.regular.of(textStyle: .headline)
        instructionLabel.setLineHeight(lineHeight: 24)
        lastBillInformationLabel.textColor = .deepGray
        lastBillInformationLabel.text = NSLocalizedString("Use one of your last two bills to find the following information:", comment: "")
        lastBillInformationLabel.font = SystemFont.regular.of(textStyle: .headline)
        
        segmentedControl.items = [NSLocalizedString("Personal", comment: ""),
                                  NSLocalizedString("Bill Details", comment: "")]
        configureTextFields()
        stackView.setCustomSpacing(20, after: instructionLabel)
        stackView.setCustomSpacing(20, after: segmentContainer)
        segmentedControl.selectedIndex.accept(.zero)
        switch Environment.shared.opco {
        case .comEd:
            illustrationImageView.image = #imageLiteral(resourceName: "img_resbill_comed.pdf")
        case .ace, .delmarva, .pepco:
            illustrationImageView.image = #imageLiteral(resourceName: "img_resbill_PHI")
        case .peco:
            illustrationImageView.image = #imageLiteral(resourceName: "img_resbill_peco.pdf")
        case .bge:
            illustrationImageView.image = #imageLiteral(resourceName: "img_resbill_bge.pdf")
        }
        viewModel.checkForMaintenance()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        GoogleAnalytics.log(event: .registerOffer)
    }
    
    private func configureTextFields() {
        
        accountNumberTextField.placeholder = NSLocalizedString("Account Number*", comment: "")
        accountNumberTextField.textField.autocorrectionType = .no
        accountNumberTextField.setKeyboardType(.numberPad)
        accountNumberTextField.textField.delegate = self
        accountNumberTextField.textField.isShowingAccessory = true
        accountNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountNumber).disposed(by: disposeBag)
        questionMarkButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        accountNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.accountNumber.asDriver(), viewModel.accountNumberHasValidLength))
            .drive(onNext: { [weak self] accountNumber, hasValidLength in
                guard let self = self else { return }
                if !accountNumber.isEmpty && !hasValidLength {
                    let errorMessage = Environment.shared.opco.isPHI ? NSLocalizedString("Account number must be 11 digits long", comment: "") : NSLocalizedString("Account number must be 10 digits long", comment: "")
                    self.accountNumberTextField?.setError(errorMessage)
                }
                self.accessibilityErrorLabel()
            }).disposed(by: disposeBag)
        
        accountNumberTextField?.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.accountNumberTextField?.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        
        // Total Amount Due
        amountDueTextField.placeholder = NSLocalizedString("Total Amount Due*", comment: "")
        amountDueTextField.textField.autocorrectionType = .no
        amountDueTextField.textField.delegate = self
        amountDueTextField.textField.isShowingAccessory = true
        amountDueTextField.setKeyboardType(.decimalPad)
        amountDueTextField.textField.rx.text.orEmpty.asObservable()
                   .skip(1)
                   .subscribe(onNext: { [weak self] entry in
                       guard let self = self else { return }
                       
                       let amount: Double
                       let textStr = String(entry.filter { "0123456789".contains($0) })
                       if let intVal = Double(textStr) {
                           amount = intVal / 100
                       } else {
                           amount = 0
                       }
                       
                       self.amountDueTextField.textField.text = amount.currencyString
                       self.viewModel.totalAmountDue.accept(amount)
                   })
                   .disposed(by: disposeBag)
        
        // Payment Date
        if Environment.shared.opco == .bge {
            dueDateButton.descriptionText = NSLocalizedString("Issued Date*", comment: "")
        } else {
        dueDateButton.descriptionText = NSLocalizedString("Due Date*", comment: "")
        }
        dueDateButton.valueLabel.textColor = .middleGray
        viewModel.paymentDateString.asDriver().drive(dueDateButton.rx.valueText).disposed(by: disposeBag)
        dueDateButton.titleLabel?.text = ""
        dueDateButton.rx.touchUpInside.asDriver().drive(onNext: { [weak self] in
            guard let self = self else { return }
            self.view.endEditing(true)
            
            let calendarVC = PDTSimpleCalendarViewController()
            calendarVC.extendedLayoutIncludesOpaqueBars = true
            calendarVC.calendar = .opCo
            calendarVC.delegate = self
            calendarVC.title = NSLocalizedString("Select Payment Date", comment: "")
            calendarVC.firstDate = Calendar.current.date(byAdding: .year, value: -10, to: Calendar.current.startOfDay(for: .now))
            calendarVC.lastDate = Calendar.current.date(byAdding: .year, value: 10, to: Calendar.current.startOfDay(for: .now))
            calendarVC.selectedDate = Calendar.opCo.startOfDay(for: .now)
            calendarVC.scroll(toSelectedDate: true)
            
            self.navigationController?.pushViewController(calendarVC, animated: true)
        }).disposed(by: disposeBag)
        
        // Phone number
        phoneNumberTextField.placeholder = NSLocalizedString("Primary Phone Number*", comment: "")
        phoneNumberTextField.textField.autocorrectionType = .no
        phoneNumberTextField.setKeyboardType(.phonePad)
        phoneNumberTextField.textField.delegate = self
        phoneNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.phoneNumber).disposed(by: disposeBag)
        
        phoneNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.phoneNumber.asDriver(), viewModel.phoneNumberHasTenDigits))
            .drive(onNext: { [weak self] phoneNumber, hasTenDigits in
                guard let self = self else { return }
                if !phoneNumber.isEmpty && !hasTenDigits {
                    self.phoneNumberTextField.setError(NSLocalizedString("Phone number must be 10 digits long", comment: ""))
                }
                self.accessibilityErrorLabel()
            }).disposed(by: disposeBag)
        
        phoneNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.phoneNumberTextField.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        var identifierString = "Last 4 digits of your Social Security number"
        identifierString.append(" or Business Tax ID")

        identifierDescriptionLabel.textColor = .deepGray
        identifierDescriptionLabel.text = NSLocalizedString(identifierString, comment: "")
        identifierDescriptionLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        let identifierPlaceholder: String
        identifierPlaceholder = NSLocalizedString("SSN/Business Tax ID*", comment: "")
        
        identifierTextField.placeholder = NSLocalizedString(identifierPlaceholder, comment: "")
        identifierTextField.textField.autocorrectionType = .no
        identifierTextField.setKeyboardType(.numberPad, doneActionTarget: self, doneActionSelector: #selector(onIdentifierKeyboardDonePress))
        identifierTextField.textField.delegate = self
        identifierTextField.textField.rx.text.orEmpty.bind(to: viewModel.identifierNumber).disposed(by: disposeBag)
        
        identifierTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.identifierNumber.asDriver(), viewModel.identifierHasFourDigits, viewModel.identifierIsNumeric))
            .drive(onNext: { [weak self] identifierNumber, hasFourDigits, isNumeric in
                guard let self = self else { return }
                if !identifierNumber.isEmpty {
                    if !hasFourDigits {
                        self.identifierTextField.setError(NSLocalizedString("This number must be 4 digits long", comment: ""))
                    } else if !isNumeric {
                        self.identifierTextField.setError(NSLocalizedString("This number must be numeric", comment: ""))
                    }
                }
                self.accessibilityErrorLabel()
            })
            .disposed(by: disposeBag)
        
        identifierTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.identifierTextField?.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
    }
    
    private func accessibilityErrorLabel() {
        var message = ""
        message += accountNumberTextField.getError()
        message += phoneNumberTextField.getError()
        message += identifierTextField.getError()
        
        if message.isEmpty {
            continueButton.accessibilityLabel = NSLocalizedString("Continue", comment: "")
        } else {
            continueButton.accessibilityLabel = String(format: NSLocalizedString("%@ Continue", comment: ""), message)
        }
    }
    
    @objc func onIdentifierKeyboardDonePress() {
		viewModel.validateAccountContinueEnabled.asObservable().take(1).asDriver(onErrorDriveWith: .empty())
			.drive(onNext: { [weak self] enabled in
				if enabled {
					self?.onContinuePress()
				} else {
					self?.view.endEditing(true)
				}
			}).disposed(by: disposeBag)
    }
    
    @IBAction func onAccountNumberTooltipPress() {
        let description: String
        switch Environment.shared.opco {
        case .bge:
            description = NSLocalizedString("Your Customer Account Number may be found in the top right portion on your bill in the bill summary section. Please enter 10-digits including leading zeros.", comment: "")
        case .comEd:
            description = NSLocalizedString("Your Account Number is located in the upper right portion of a residential bill and the upper center portion of a commercial bill. Please enter all 10 digits, including leading zeros, but no dashes.", comment: "")
        case .peco:
            description = NSLocalizedString("Your Account Number is located in the upper left portion of your bill. Please enter all 10 digits, including leading zeroes, but no dashes. If \"SUMM\" appears after your name on your bill, please enter any account from your list of individual accounts.", comment: "")
        case .pepco, .delmarva, .ace:
            description = NSLocalizedString("Your Account Number is located in the upper-left portion of your bill. Please enter all 11 digits, but no spaces.", comment: "")
        }
        let infoModal = InfoModalViewController(title: NSLocalizedString("Find Account Number", comment: ""), image: #imageLiteral(resourceName: "bill_infographic"), description: description)
        
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
    
    @IBAction func onContinuePress() {
        view.endEditing(true)
        
        LoadingView.show()
        
        viewModel.validateAccount(onSuccess: { [weak self] in
            LoadingView.hide()
            GoogleAnalytics.log(event: .registerAccountValidation)
            if self?.viewModel.hasMultipleAccount ?? false {
                self?.performSegue(withIdentifier: "chooseAccountSegue", sender: self)
            } else {
                self?.performSegue(withIdentifier: "createCredentialsSegue", sender: self)
            }
           
        }, onMultipleAccounts:  { [weak self] in
            LoadingView.hide()
            GoogleAnalytics.log(event: .registerAccountValidation)
            
            self?.performSegue(withIdentifier: "bgeAccountNumberSegue", sender: self)
        }, onError: { [weak self] (title, message) in
            LoadingView.hide()
            
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            
            self?.present(alertController, animated: true, completion: nil)
        })
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        view.endEditing(true)
        
        if let vc = segue.destination as? RegistrationCreateCredentialsViewControllerNew {
            vc.viewModel = viewModel
        } else if let vc = segue.destination as? RegistrationBGEAccountNumberViewController {
            vc.viewModel = viewModel
        } else if let vc = segue.destination as? RegistrationChooseAccountViewController {
            vc.viewModel = viewModel
        }
    }
    
}

extension RegistrationValidateAccountViewControllerNew: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if textField == phoneNumberTextField.textField {
            let components = newString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            
            let decimalString = components.joined(separator: "") as NSString
            let length = decimalString.length
            
            if length > 10 {
                return false
            }
            
            var index = 0 as Int
            let formattedString = NSMutableString()
            
            if length - index > 3 {
                let areaCode = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("(%@) ", areaCode)
                index += 3
            }
            if length - index > 3 {
                let prefix = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("%@-", prefix)
                index += 3
            }
            
            let remainder = decimalString.substring(from: index)
            formattedString.append(remainder)
            textField.text = formattedString as String
            
            textField.sendActions(for: .valueChanged) // Send rx events
            
            return false
        } else if textField == identifierTextField?.textField {
            let characterSet = CharacterSet(charactersIn: string)
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= 4
        } else if textField == accountNumberTextField?.textField {
            let characterSet = CharacterSet(charactersIn: string)
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= (Environment.shared.opco.isPHI ? 11 : 10)
        }
        
        return true
    }
    
    @IBAction func segmentValueChanged(_ sender: SegmentedControl) {
        if sender.selectedIndex.value == .zero {
            phoneNumberTextField.isHidden = false
            identifierTextField.isHidden = false
            identifierDescriptionLabel.isHidden = false
            accountNumberView.isHidden = true
            amountDueTextField.isHidden = true
            dueDateButton.isHidden = true
            lastBillInformationLabel.isHidden = true
            illustrationImageView.isHidden = true
        } else {
            accountNumberView.isHidden = false
            amountDueTextField.isHidden = false
            dueDateButton.isHidden = false
            phoneNumberTextField.isHidden = true
            identifierTextField.isHidden = true
            identifierDescriptionLabel.isHidden = true
            lastBillInformationLabel.isHidden = false
            illustrationImageView.isHidden = false
        }
        stackView.setCustomSpacing(20, after: lastBillInformationLabel)
        viewModel.selectedSegmentIndex.accept(sender.selectedIndex.value)
    }
}

// MARK: - PDTSimpleCalendarViewDelegate

extension RegistrationValidateAccountViewControllerNew: PDTSimpleCalendarViewDelegate {
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, isEnabledDate date: Date!) -> Bool {
        return true
    }
    
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, didSelect date: Date!) {
        let components = Calendar.opCo.dateComponents([.year, .month, .day], from: date)
        guard let opCoTimeDate = Calendar.opCo.date(from: components) else { return }
        dueDateButton.valueLabel.textColor = .deepGray
        viewModel.dueDate.accept(opCoTimeDate.isInToday(calendar: .opCo) ? .now : opCoTimeDate)
    }
}
