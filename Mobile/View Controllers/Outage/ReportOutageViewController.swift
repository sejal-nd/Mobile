//
//  ReportOutageViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 3/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Lottie

class ReportOutageViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var accountInfoBar: AccountInfoBar!
    
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
    @IBOutlet weak var commentView: UIView!
    @IBOutlet weak var commentTextView: FloatLabelTextView!
    @IBOutlet weak var commentLabel: UILabel!
    
    // Footer View
    @IBOutlet weak var footerContainerView: UIView!
    @IBOutlet weak var footerBackgroundView: UIView!
    @IBOutlet weak var footerTextView: DataDetectorTextView!
    
    
    let viewModel = ReportOutageViewModel(outageService: ServiceFactory.createOutageService())
    let opco = Environment.shared.opco
    
    let disposeBag = DisposeBag()
    
    var submitButton = UIBarButtonItem()
    
    var unauthenticatedExperience = false // `true` passed from UnauthenticatedOutageStatusViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Report Outage", comment: "")

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = submitButton
        viewModel.submitEnabled.asDriver().drive(submitButton.rx.isEnabled).disposed(by: disposeBag)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        if unauthenticatedExperience {
            accountInfoBar.update(accountNumber: viewModel.outageStatus!.maskedAccountNumber, address: viewModel.outageStatus!.maskedAddress)
        }
        
        if viewModel.shouldPingMeter && !unauthenticatedExperience {
            let bg = UIView(frame: meterPingStackView.bounds)
            bg.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            bg.backgroundColor = .softGray
            bg.addShadow(color: .black, opacity: 0.08, offset: .zero, radius: 1.5)
            meterPingStackView.addSubview(bg)
            meterPingStackView.sendSubviewToBack(bg)
            
            meterPingStackView.spacing = 20
            meterPingStackView.isHidden = false

            footerContainerView.isHidden = true
            
            meterPingPowerStatusView.isHidden = true
            meterPingVoltageStatusView.isHidden = true
            meterPingResultLabel.isHidden = true
            meterPingFuseBoxView.isHidden = true
            
            meterPingFuseBoxSwitch.rx.isOn.asDriver().map(!).drive(viewModel.reportFormHidden).disposed(by: disposeBag)
            viewModel.reportFormHidden.asDriver().drive(reportFormStackView.rx.isHidden).disposed(by: disposeBag)
            viewModel.reportFormHidden.asDriver().drive(onNext: { [weak self] hidden in
                if hidden {
                    self?.reportFormStackView.spacing = 0
                    self?.reportFormStackView.endEditing(true)
                } else {
                    self?.reportFormStackView.spacing = 30
                }
            }).disposed(by: disposeBag)
            
            viewModel.reportFormHidden.value = true

            meterPingCurrentStatusLabel.font = SystemFont.medium.of(textStyle: .headline)
            meterPingCurrentStatusLabel.textColor = .blackText
            meterPingCurrentStatusLabel.text = NSLocalizedString("Checking meter status...", comment: "")
            
            meterPingPowerStatusImageView.isAccessibilityElement = true
            meterPingPowerStatusLabel.font = SystemFont.medium.of(textStyle: .title1)
            meterPingPowerStatusLabel.textColor = .blackText
            
            meterPingVoltageStatusImageView.isAccessibilityElement = true
            meterPingVoltageStatusLabel.font = SystemFont.medium.of(textStyle: .title1)
            meterPingVoltageStatusLabel.textColor = .blackText
            
            meterPingResultLabel.font = SystemFont.regular.of(textStyle: .body)
            meterPingResultLabel.textColor = .deepGray
            meterPingFuseBoxLabel.font = OpenSans.regular.of(textStyle: .headline)
            meterPingFuseBoxLabel.textColor = .middleGray
            meterPingFuseBoxLabel.setLineHeight(lineHeight: 25)
            meterPingFuseBoxLabel.text = NSLocalizedString("I have checked my circuit breakers or fuse box and I would still like to report an outage.", comment: "")
            meterPingFuseBoxLabel.isAccessibilityElement = false
            meterPingFuseBoxSwitch.accessibilityLabel = meterPingFuseBoxLabel.text
            
            let lottieAnimation = LOTAnimationView(name: "loading_blue")
            lottieAnimation.frame = CGRect(x: 0, y: 0, width: 33, height: 33)
            lottieAnimation.loopAnimation = true
            lottieAnimation.contentMode = .scaleToFill
            meterPingCurrentStatusLoadingView.addSubview(lottieAnimation)
            lottieAnimation.play()
        } else {
            meterPingStackView.isHidden = true
            meterPingFuseBoxView.isHidden = true
            viewModel.reportFormHidden.value = false
        }

        if opco != .comEd {
            commentView.isHidden = true
        }
        
        if opco == .peco {
            segmentedControl.items = [NSLocalizedString("Yes", comment: ""), NSLocalizedString("Partially", comment: ""), NSLocalizedString("Dim/Flickering", comment: "")]
        } else {
            segmentedControl.items = [NSLocalizedString("Yes", comment: ""), NSLocalizedString("Partially", comment: "")]
        }
        
        areYourLightsOutLabel.font = SystemFont.regular.of(textStyle: .headline)
        howCanWeContactYouLabel.font = SystemFont.regular.of(textStyle: .headline)
        commentLabel.font = SystemFont.regular.of(textStyle: .headline)
        
        phoneNumberTextField.textField.placeholder = NSLocalizedString("Contact Number*", comment: "")
        phoneNumberTextField.textField.autocorrectionType = .no
        phoneNumberTextField.setKeyboardType(.phonePad)
        phoneNumberTextField.textField.delegate = self
        
        phoneNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .drive(onNext: { [weak self] in
                self?.accessibilityErrorLabel()
            })
            .disposed(by: disposeBag)
        
        phoneNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(viewModel.phoneNumber.asDriver())
            .filter { !$0.isEmpty }
            .withLatestFrom(viewModel.phoneNumberHasTenDigits)
            .filter(!)
            .drive(onNext: { [weak self] _ in
                self?.phoneNumberTextField.setError(NSLocalizedString("Phone number must be 10 digits long", comment: ""))
            })
            .disposed(by: disposeBag)
        
        phoneNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] _ in
            self?.phoneNumberTextField.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        phoneExtensionTextField.textField.placeholder = NSLocalizedString("Contact # Ext. (Opt.)", comment: "")
        phoneExtensionTextField.textField.autocorrectionType = .no
        phoneExtensionTextField.setKeyboardType(.numberPad)
        phoneExtensionTextField.textField.delegate = self

        if opco == .bge {
            phoneExtensionContainerView.isHidden = true
        }
        
        footerBackgroundView.backgroundColor = .softGray
        footerBackgroundView.addShadow(color: .black, opacity: 0.08, offset: .zero, radius: 1.5)
        
        footerTextView.textColor = .blackText
        footerTextView.tintColor = .actionBlue // For the phone numbers
        footerTextView.attributedText = viewModel.footerTextViewText
        footerTextView.linkTapDelegate = self
        
        commentTextView.textView.placeholder = NSLocalizedString("Enter details here (Optional)", comment: "")
        
        // Data binding
        segmentedControl.selectedIndex.asObservable().bind(to: viewModel.selectedSegmentIndex).disposed(by: disposeBag)
        
        viewModel.phoneNumber.asDriver().drive(phoneNumberTextField.textField.rx.text.orEmpty)
            .disposed(by: disposeBag)
        phoneNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.phoneNumber).disposed(by: disposeBag)
        phoneNumberTextField.textField.sendActions(for: .editingDidEnd)
        
        phoneExtensionTextField.textField.rx.text.orEmpty.bind(to: viewModel.phoneExtension).disposed(by: disposeBag)
        commentTextView.textView.rx.text.orEmpty.bind(to: viewModel.comments).disposed(by: disposeBag)
        
        // Format the intial value
        let range = NSMakeRange(0, viewModel.phoneNumber.value.count)
        _ = textField(phoneNumberTextField.textField, shouldChangeCharactersIn: range, replacementString: viewModel.phoneNumber.value)
    }
    
    private func accessibilityErrorLabel() {
        let message = phoneNumberTextField.getError()
        
        if message.isEmpty {
            submitButton.accessibilityLabel = NSLocalizedString("Submit", comment: "")
        } else {
            submitButton.accessibilityLabel = String(format: NSLocalizedString("%@ Submit", comment: ""), message)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if unauthenticatedExperience {
            Analytics.log(event: .reportAnOutageUnAuthScreenView)
        } else {
            Analytics.log(event: .reportOutageAuthOffer)
        }
        
        if viewModel.shouldPingMeter && !unauthenticatedExperience {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                UIAccessibility.post(notification: .announcement, argument: NSLocalizedString("Checking meter status", comment: ""))
            })
            
            viewModel.meterPingGetStatus(onComplete: { meterPingInfo in
                self.meterPingCurrentStatusLoadingView.isHidden = true
                self.meterPingCurrentStatusCheckImageView.isHidden = false
                
                self.meterPingCurrentStatusLabel.text = NSLocalizedString("Check Complete", comment: "")
                
                var problemsFound = false
                if meterPingInfo.pingResult {
                    self.meterPingPowerStatusView.isHidden = false
                    self.meterPingPowerStatusImageView.image = #imageLiteral(resourceName: "ic_successcheckcircle")
                    self.meterPingPowerStatusImageView.accessibilityLabel = NSLocalizedString("Successful", comment: "")
                } else {
                    problemsFound = true
                    self.meterPingPowerStatusView.isHidden = false
                    self.meterPingPowerStatusImageView.image = #imageLiteral(resourceName: "ic_failxcircle")
                    self.meterPingPowerStatusImageView.accessibilityLabel = NSLocalizedString("Failed", comment: "")
                    self.meterPingVoltageStatusView.isHidden = true
                }
                
                if meterPingInfo.voltageResult {
                    if meterPingInfo.pingResult {
                        self.meterPingVoltageStatusView.isHidden = false
                    }
                    if let voltageReads = meterPingInfo.voltageReads,
                        !voltageReads.lowercased().contains("improper"),
                        voltageReads.lowercased().contains("proper") {
                        self.meterPingVoltageStatusImageView.image = #imageLiteral(resourceName: "ic_successcheckcircle")
                        self.meterPingVoltageStatusImageView.accessibilityLabel = NSLocalizedString("Successful", comment: "")
                    } else {
                        problemsFound = true
                        self.meterPingVoltageStatusImageView.image = #imageLiteral(resourceName: "ic_failxcircle")
                        self.meterPingVoltageStatusImageView.accessibilityLabel = NSLocalizedString("Failed", comment: "")
                    }
                }

                if problemsFound {
                    self.meterPingCurrentStatusCheckImageView.image = #imageLiteral(resourceName: "ic_check_meterping_fail")
                    self.meterPingResultLabel.isHidden = false
                    self.meterPingResultLabel.text = NSLocalizedString("Problems Found. Please tap \"Submit\" to report an outage.", comment: "")
                    
                    self.areYourLightsOutView.isHidden = true
                    self.viewModel.reportFormHidden.value = false
                } else {
                    self.meterPingFuseBoxView.isHidden = false
                }

                self.footerContainerView.isHidden = false
                        
                
                UIAccessibility.post(notification: .screenChanged, argument: self)
                UIAccessibility.post(notification: .announcement, argument: NSLocalizedString("Check Complete", comment: ""))
            }, onError: {
                self.meterPingCurrentStatusLoadingView.isHidden = true
                self.meterPingCurrentStatusCheckImageView.image = #imageLiteral(resourceName: "ic_check_meterping_fail")
                self.meterPingCurrentStatusCheckImageView.isHidden = false
                self.meterPingCurrentStatusLabel.text = NSLocalizedString("Check Complete", comment: "")
                
                self.meterPingPowerStatusView.isHidden = false
                self.meterPingPowerStatusImageView.image = #imageLiteral(resourceName: "ic_failxcircle")
                self.meterPingPowerStatusImageView.accessibilityLabel = NSLocalizedString("Failed", comment: "")
                
                self.meterPingResultLabel.isHidden = false
                self.meterPingResultLabel.text = NSLocalizedString("Problems Found. Please tap \"Submit\" to report an outage.", comment: "")
                
                self.areYourLightsOutView.isHidden = true
                self.viewModel.reportFormHidden.value = false
                self.footerContainerView.isHidden = false
                
                UIAccessibility.post(notification: .screenChanged, argument: self)
                UIAccessibility.post(notification: .announcement, argument: NSLocalizedString("Check Complete", comment: ""))
            })
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func onSubmitPress() {
        guard submitButton.isEnabled else { return }
        view.endEditing(true)
        
        let errorBlock = { [weak self] (errorMessage: String) in
            LoadingView.hide()
            let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        }
        
        LoadingView.show()
        if unauthenticatedExperience {
            viewModel.reportOutageAnon(onSuccess: { [weak self] reportedOutage in
                LoadingView.hide()
                guard let self = self else { return }
                RxNotifications.shared.outageReported.onNext(())
                self.navigationController?.popViewController(animated: true)
            }, onError: errorBlock)
            Analytics.log(event: .reportAnOutageUnAuthSubmit)
        } else {
            viewModel.reportOutage(onSuccess: { [weak self] in
                LoadingView.hide()
                guard let self = self else { return }
                RxNotifications.shared.outageReported.onNext(())
                self.navigationController?.popViewController(animated: true)
            }, onError: errorBlock)
            Analytics.log(event: .reportOutageAuthSubmit)
        }
        

    }
    
    @IBAction func switchPressed(sender: AnyObject) {
        if sender.isEqual(meterPingFuseBoxSwitch) && meterPingFuseBoxSwitch.isOn {
            Analytics.log(event: .reportOutageAuthCircuitBreak)
        }
    }
    
    // MARK: - ScrollView
    
    @objc func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo!
        let endFrameRect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        var safeAreaBottomInset: CGFloat = 0
        if #available(iOS 11.0, *) {
            safeAreaBottomInset = self.view.safeAreaInsets.bottom
        }
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: endFrameRect.size.height - safeAreaBottomInset, right: 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
    
    @objc func keyboardWillHide(notification: Notification) {
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
    
}

extension ReportOutageViewController: DataDetectorTextViewLinkTapDelegate {
    
    func dataDetectorTextView(_ textView: DataDetectorTextView, didInteractWith URL: URL) {
        let screenName: AnalyticsEvent = unauthenticatedExperience ?
            .reportAnOutageUnAuthEmergencyPhone :
            .reportOutageEmergencyCall
        
        Analytics.log(event: screenName)
    }
}
