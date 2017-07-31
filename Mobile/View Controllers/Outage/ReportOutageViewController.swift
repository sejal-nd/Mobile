//
//  ReportOutageViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 3/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import Lottie

protocol ReportOutageViewControllerDelegate: class {
    func reportOutageViewControllerDidReportOutage(_ reportOutageViewController: ReportOutageViewController)
}

class ReportOutageViewController: UIViewController {
    
    weak var delegate: ReportOutageViewControllerDelegate?
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    // Meter Ping
    @IBOutlet weak var meterPingStackView: UIStackView!
    
    @IBOutlet weak var meterPingCurrentStatusCheckImageView: UIImageView!
    @IBOutlet weak var meterPingCurrentStatusLoadingView: UIView!
    @IBOutlet weak var meterPingCurrentStatusLabel: UILabel!
    
    @IBOutlet weak var meterPingPowerStatusView: UIView!
    @IBOutlet weak var meterPingPowerStatusImageView: UIImageView!
    @IBOutlet weak var meterPingPowerStatusLabel: UILabel!
    
    @IBOutlet weak var meterPingVoltageStatusView: UIView!
    @IBOutlet weak var meterPingVoltageStatusImageView: UIImageView!
    @IBOutlet weak var meterPingVoltageStatusLabel: UILabel!
    
    @IBOutlet weak var meterPingResultLabel: UILabel!
    
    @IBOutlet weak var meterPingFuseBoxView: UIView!
    @IBOutlet weak var meterPingFuseBoxSwitch: Switch!
    @IBOutlet weak var meterPingFuseBoxLabel: UILabel!
    
    // Report Form
    @IBOutlet weak var reportFormStackView: UIStackView!
    @IBOutlet weak var areYourLightsOutView: UIView!
    @IBOutlet weak var areYourLightsOutLabel: UILabel!
    @IBOutlet weak var segmentedControl: SegmentedControl!
    @IBOutlet weak var howCanWeContactYouLabel: UILabel!
    @IBOutlet weak var phoneNumberTextField: FloatLabelTextField!
    @IBOutlet weak var phoneExtensionContainerView: UIView!
    @IBOutlet weak var phoneExtensionTextField: FloatLabelTextField!
    
    // Footer View
    @IBOutlet weak var footerContainerView: UIView!
    @IBOutlet weak var footerBackgroundView: UIView!
    @IBOutlet weak var footerTextView: DataDetectorTextView!
    
    let viewModel = ReportOutageViewModel(outageService: ServiceFactory.createOutageService())
    let opco = Environment.sharedInstance.opco
    
    let disposeBag = DisposeBag()
    
    var submitButton = UIBarButtonItem()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Report Outage", comment: "")

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = submitButton
        viewModel.submitEnabled.asDriver().drive(submitButton.rx.isEnabled).addDisposableTo(disposeBag)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        // METER PING
        if Environment.sharedInstance.opco == .comEd && viewModel.outageStatus!.meterPingInfo != nil {
            let bg = UIView(frame: meterPingStackView.bounds)
            bg.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            bg.backgroundColor = .softGray
            bg.addShadow(color: .black, opacity: 0.08, offset: .zero, radius: 1.5)
            meterPingStackView.addSubview(bg)
            meterPingStackView.sendSubview(toBack: bg)
            
            meterPingStackView.spacing = 20
            meterPingStackView.isHidden = false

            footerContainerView.isHidden = true
            
            meterPingFuseBoxSwitch.rx.isOn.map(!).bind(to: viewModel.reportFormHidden).addDisposableTo(disposeBag)
            viewModel.reportFormHidden.asObservable().bind(to: reportFormStackView.rx.isHidden).addDisposableTo(disposeBag)
            viewModel.reportFormHidden.asObservable().subscribe(onNext: { hidden in
                if hidden {
                    self.reportFormStackView.spacing = 0
                    self.reportFormStackView.endEditing(true)
                } else {
                    self.reportFormStackView.spacing = 30
                }
            }).addDisposableTo(disposeBag)
            
            viewModel.reportFormHidden.value = true

            meterPingCurrentStatusLabel.font = SystemFont.medium.of(textStyle: .headline)
            meterPingCurrentStatusLabel.textColor = .blackText
            
            meterPingPowerStatusImageView.isAccessibilityElement = true
            meterPingPowerStatusImageView.accessibilityLabel = NSLocalizedString("Waiting for", comment: "")
            meterPingPowerStatusLabel.font = SystemFont.medium.of(textStyle: .title1)
            meterPingPowerStatusLabel.textColor = .middleGray
            
            meterPingVoltageStatusImageView.isAccessibilityElement = true
            meterPingVoltageStatusImageView.accessibilityLabel = NSLocalizedString("Waiting for", comment: "")
            meterPingVoltageStatusLabel.font = SystemFont.medium.of(textStyle: .title1)
            meterPingVoltageStatusLabel.textColor = .middleGray
            
            meterPingResultLabel.font = SystemFont.regular.of(textStyle: .body)
            meterPingResultLabel.textColor = .deepGray
            meterPingFuseBoxLabel.font = OpenSans.regular.of(textStyle: .headline)
            meterPingFuseBoxLabel.textColor = .middleGray
            meterPingFuseBoxLabel.setLineHeight(lineHeight: 25)
            
            let lottieAnimation = LOTAnimationView(name: "loading_blue")!
            lottieAnimation.frame = CGRect(x: 0, y: 0, width: 33, height: 33)
            lottieAnimation.loopAnimation = true
            lottieAnimation.contentMode = .scaleToFill
            meterPingCurrentStatusLoadingView.addSubview(lottieAnimation)
            lottieAnimation.play()
        } else {
            viewModel.reportFormHidden.value = false
        }

        if opco == .peco {
            segmentedControl.items = [NSLocalizedString("Yes", comment: ""), NSLocalizedString("Partially", comment: ""), NSLocalizedString("Dim/Flickering", comment: "")]
        } else {
            segmentedControl.items = [NSLocalizedString("Yes", comment: ""), NSLocalizedString("Partially", comment: "")]
        }
        
        areYourLightsOutLabel.font = SystemFont.regular.of(textStyle: .headline)
        howCanWeContactYouLabel.font = SystemFont.regular.of(textStyle: .headline)

        phoneNumberTextField.textField.placeholder = NSLocalizedString("Contact Number *", comment: "")
        phoneNumberTextField.textField.autocorrectionType = .no
        phoneNumberTextField.textField.returnKeyType = opco == .bge ? .done:.next
        phoneNumberTextField.textField.delegate = self
        phoneNumberTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: { _ in
            if self.viewModel.phoneNumber.value.characters.count > 0 {
                self.viewModel.phoneNumberHasTenDigits().single().subscribe(onNext: { valid in
                    if !valid {
                        self.phoneNumberTextField.setError(NSLocalizedString("Phone number must be 10 digits long.", comment: ""))
                    }
                }).addDisposableTo(self.disposeBag)
            }
            self.accessibilityErrorLabel()
            
        }).addDisposableTo(disposeBag)
        phoneNumberTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: { _ in
            self.phoneNumberTextField.setError(nil)
            self.accessibilityErrorLabel()
            
        }).addDisposableTo(disposeBag)
        phoneExtensionTextField.textField.placeholder = NSLocalizedString("Contact Number Ext. (Optional)", comment: "")
        phoneExtensionTextField.textField.autocorrectionType = .no
        phoneExtensionTextField.textField.returnKeyType = .done
        phoneExtensionTextField.textField.delegate = self

        if opco == .bge {
            phoneExtensionContainerView.isHidden = true
        }
        
        footerBackgroundView.backgroundColor = .softGray
        footerBackgroundView.addShadow(color: .black, opacity: 0.08, offset: .zero, radius: 1.5)
        
        footerTextView.textContainerInset = UIEdgeInsets(top: 16, left: 29, bottom: 16, right: 29)
        footerTextView.font = OpenSans.regular.of(textStyle: .footnote)
        footerTextView.textColor = .blackText
        footerTextView.tintColor = .actionBlue // For the phone numbers
        footerTextView.text = viewModel.getFooterTextViewText()
        footerTextView.addShadow(color: .black, opacity: 0.06, offset: CGSize(width: 0, height: 2), radius: 2)
        
        // Data binding
        segmentedControl.selectedIndex.asObservable().bind(to: viewModel.selectedSegmentIndex).addDisposableTo(disposeBag)
        
        viewModel.phoneNumber.asObservable().bind(to: phoneNumberTextField.textField.rx.text.orEmpty)
            .addDisposableTo(disposeBag)
        phoneNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.phoneNumber).addDisposableTo(disposeBag)
        phoneNumberTextField.textField.sendActions(for: .editingDidEnd)
        
        phoneExtensionTextField.textField.rx.text.orEmpty.bind(to: viewModel.phoneExtension).addDisposableTo(disposeBag)
        
        // Format the intial value
        let range = NSMakeRange(0, viewModel.phoneNumber.value.characters.count)
        _ = textField(phoneNumberTextField.textField, shouldChangeCharactersIn: range, replacementString: viewModel.phoneNumber.value)
    }
    
    private func accessibilityErrorLabel() {
        let message = NSLocalizedString(phoneNumberTextField.getError(), comment: "")
        
        let errorStr = NSLocalizedString(message, comment: "")
        if errorStr.isEmpty {
            self.submitButton.accessibilityLabel = NSLocalizedString("Submit", comment: "")
        } else {
            self.submitButton.accessibilityLabel = errorStr
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // METER PING
        if Environment.sharedInstance.opco == .comEd && viewModel.outageStatus!.meterPingInfo != nil {
            viewModel.meterPingGetPowerStatus(onPowerVerified: { canPerformVoltageCheck in
                self.meterPingPowerStatusImageView.image = #imageLiteral(resourceName: "ic_successcheckcircle")
                self.meterPingPowerStatusImageView.accessibilityLabel = NSLocalizedString("Successful", comment: "")
                self.meterPingPowerStatusLabel.textColor = .blackText
                
                if !canPerformVoltageCheck { // POWER STATUS SUCCESS BUT NO VOLTAGE CHECK
                    self.meterPingCurrentStatusLoadingView.isHidden = true
                    self.meterPingCurrentStatusCheckImageView.isHidden = false
                    self.meterPingCurrentStatusLabel.text = NSLocalizedString("Check Complete", comment: "")
                    self.meterPingResultLabel.isHidden = false
                    self.meterPingResultLabel.text = NSLocalizedString("Our status check verified your property's meter is operational and ComEd electrical service is being delivered to your home", comment: "")
                    self.meterPingResultLabel.setLineHeight(lineHeight: 25)
                    self.meterPingFuseBoxView.isHidden = false
                    self.footerContainerView.isHidden = false
                } else { // POWER STATUS SUCCESS
                    self.meterPingCurrentStatusLabel.text = NSLocalizedString("Verifying voltage level of the meter...", comment: "")
                    self.meterPingVoltageStatusView.isHidden = false
                    self.viewModel.meterPingGetVoltageStatus(onVoltageVerified: {
                        self.meterPingCurrentStatusLoadingView.isHidden = true
                        self.meterPingCurrentStatusCheckImageView.isHidden = false
                        self.meterPingCurrentStatusLabel.text = NSLocalizedString("Check Complete", comment: "")
                        
                        self.meterPingVoltageStatusImageView.image = #imageLiteral(resourceName: "ic_successcheckcircle")
                        self.meterPingVoltageStatusImageView.accessibilityLabel = NSLocalizedString("Successful", comment: "")
                        self.meterPingVoltageStatusLabel.textColor = .blackText
                        
                        self.meterPingFuseBoxView.isHidden = false
                        self.footerContainerView.isHidden = false
                    }, onError: { error in // VOLTAGE STATUS ERROR
                        self.meterPingCurrentStatusLoadingView.isHidden = true
                        self.meterPingCurrentStatusCheckImageView.isHidden = false
                        self.meterPingCurrentStatusCheckImageView.image = #imageLiteral(resourceName: "ic_check_meterping_fail")
                        self.meterPingCurrentStatusLabel.text = NSLocalizedString("Check Complete", comment: "")
                        
                        self.meterPingVoltageStatusImageView.image = #imageLiteral(resourceName: "ic_failxcircle")
                        self.meterPingVoltageStatusImageView.accessibilityLabel = NSLocalizedString("Failed", comment: "")
                        self.meterPingVoltageStatusLabel.textColor = .blackText
                        
                        self.meterPingResultLabel.isHidden = false
                        self.meterPingResultLabel.text = NSLocalizedString("Problems Found. Please tap \"Submit\" to report an outage.", comment: "")
                        
                        self.areYourLightsOutView.isHidden = true
                        self.viewModel.reportFormHidden.value = false
                        self.footerContainerView.isHidden = false
                    })
                }

            }, onError: { error in // POWER STATUS ERROR
                self.meterPingCurrentStatusLoadingView.isHidden = true
                self.meterPingCurrentStatusCheckImageView.isHidden = false
                self.meterPingCurrentStatusCheckImageView.image = #imageLiteral(resourceName: "ic_check_meterping_fail")
                self.meterPingCurrentStatusLabel.text = NSLocalizedString("Check Complete", comment: "")
                
                self.meterPingPowerStatusImageView.image = #imageLiteral(resourceName: "ic_failxcircle")
                self.meterPingPowerStatusImageView.accessibilityLabel = NSLocalizedString("Failed", comment: "")
                self.meterPingPowerStatusLabel.textColor = .blackText
                
                self.meterPingResultLabel.isHidden = false
                self.meterPingResultLabel.text = NSLocalizedString("Problems Found. Please tap \"Submit\" to report an outage.", comment: "")
                
                self.areYourLightsOutView.isHidden = true
                self.viewModel.reportFormHidden.value = false
                self.footerContainerView.isHidden = false
            })
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func onCancelPress() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    func onSubmitPress() {
        view.endEditing(true)
        
        LoadingView.show()
        viewModel.reportOutage(onSuccess: {
            LoadingView.hide()
            self.delegate?.reportOutageViewControllerDidReportOutage(self)
            _ = self.navigationController?.popViewController(animated: true)
        }) { errorMessage in
            LoadingView.hide()
            let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - ScrollView
    
    func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo!
        let endFrameRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let insets = UIEdgeInsetsMake(0, 0, endFrameRect.size.height, 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
    
    func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }

}

extension ReportOutageViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == phoneNumberTextField.textField {
            let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
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
        } else {
            return string == string.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == phoneNumberTextField.textField {
            if phoneExtensionContainerView.isHidden {
                if viewModel.submitEnabled.value {
                    onSubmitPress()
                } else {
                    view.endEditing(true)
                }
            } else {
                phoneExtensionTextField.textField.becomeFirstResponder()
            }
        } else if textField == phoneExtensionTextField?.textField {
            if viewModel.submitEnabled.value {
                onSubmitPress()
            } else {
                view.endEditing(true)
            }
        }
        return false
    }
}
