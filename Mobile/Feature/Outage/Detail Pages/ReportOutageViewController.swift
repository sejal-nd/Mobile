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

protocol ReportOutageDelegate: class {
    func didReportOutage()
}

class ReportOutageViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var accountInfoBar: AccountInfoBarNew!
    
    // Meter Ping
    @IBOutlet weak var meterPingStackView: UIStackView!
    
    @IBOutlet weak var meterPingCurrentStatusAnimationView: UIView!
    @IBOutlet weak var meterPingCurrentStatusLabel: UILabel!
    
    @IBOutlet weak var meterPingStatusView: UIView!
    @IBOutlet weak var meterPingStatusTitleLabel: UILabel!
    @IBOutlet weak var meterPingStatusDescriptionLabel: UILabel!
    
    @IBOutlet weak var meterPingFuseBoxView: UIView!
    @IBOutlet weak var meterPingFuseBoxSwitch: Switch!
    @IBOutlet weak var meterPingFuseBoxLabel: UILabel!
    
    @IBOutlet weak var meterPingSeparatorView: UIView!
    
    // Report Form
    @IBOutlet weak var reportFormStackView: UIStackView!
    @IBOutlet weak var areYourLightsOutView: UIView!
    @IBOutlet weak var areYourLightsOutLabel: UILabel!
    @IBOutlet weak var segmentedControl: SegmentedControlNew!
    @IBOutlet weak var howCanWeContactYouLabel: UILabel!
    @IBOutlet weak var phoneNumberTextField: FloatLabelTextFieldNew!
    @IBOutlet weak var phoneExtensionContainerView: UIView!
    @IBOutlet weak var phoneExtensionTextField: FloatLabelTextFieldNew!
    @IBOutlet weak var commentView: UIView!
    @IBOutlet weak var commentTextView: FloatLabelTextViewNew!
    @IBOutlet weak var commentLabel: UILabel!
    
    // Footer View
    @IBOutlet weak var footerContainerView: UIView!
    @IBOutlet weak var footerBackgroundView: UIView!
    @IBOutlet weak var footerTextView: DataDetectorTextView!
    
    @IBOutlet weak var stickyFooterBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var submitButton: PrimaryButtonNew!
    
    private var lottieAnimationView: LOTAnimationView?
    
    var delegate: ReportOutageDelegate?
    let viewModel = ReportOutageViewModel(outageService: ServiceFactory.createOutageService())
    let opco = Environment.shared.opco
    
    let disposeBag = DisposeBag()
    
    var unauthenticatedExperience = false // `true` passed from UnauthenticatedOutageStatusViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Report Outage", comment: "")
        
        style()
        
        viewModel.submitEnabled.asDriver().drive(submitButton.rx.isEnabled).disposed(by: disposeBag)
        
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        if unauthenticatedExperience,
            let accountNumberText = viewModel.outageStatus?.maskedAccountNumber,
            let addressText = viewModel.outageStatus?.maskedAddress {
            accountInfoBar.configure(accountNumberText: accountNumberText, addressText: addressText)
        }
        
        if viewModel.shouldPingMeter && !unauthenticatedExperience {
            let bg = UIView(frame: meterPingStackView.bounds)
            bg.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            bg.addShadow(color: .black, opacity: 0.08, offset: .zero, radius: 1.5)
            meterPingStackView.addSubview(bg)
            meterPingStackView.sendSubviewToBack(bg)
            
            meterPingStackView.spacing = 20
            meterPingStackView.isHidden = false
            meterPingSeparatorView.isHidden = false
            
            footerContainerView.isHidden = true
            
            meterPingStatusView.isHidden = true
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
            
            meterPingCurrentStatusLabel.text = NSLocalizedString("Checking meter status...", comment: "")
            
            meterPingFuseBoxLabel.text = NSLocalizedString("I have checked my circuit breakers or fuse box and I would still like to report an outage.", comment: "")
            meterPingFuseBoxLabel.isAccessibilityElement = false
            meterPingFuseBoxSwitch.accessibilityLabel = meterPingFuseBoxLabel.text
            
            // Add Lottie Animation
            self.setLottieAnimation(for: "smallcircleload_blue", shouldLoop: true)
        } else {
            meterPingStackView.isHidden = true
            meterPingFuseBoxView.isHidden = true
            viewModel.reportFormHidden.value = false
            meterPingSeparatorView.isHidden = true
        }
        
        if opco != .comEd {
            commentView.isHidden = true
        }
        
        if opco == .peco {
            segmentedControl.items = [NSLocalizedString("Yes", comment: ""), NSLocalizedString("Partially", comment: ""), NSLocalizedString("Dim/Flickering", comment: "")]
        } else {
            segmentedControl.items = [NSLocalizedString("Yes", comment: ""), NSLocalizedString("Partially", comment: "")]
        }
        
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
        
        footerTextView.textColor = .blackText
        footerTextView.tintColor = .actionBlue // For the phone numbers
        footerTextView.attributedText = viewModel.footerTextViewText
        footerTextView.linkTapDelegate = self
        
        commentTextView.placeholder = NSLocalizedString("Enter details here (Optional)", comment: "")
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if unauthenticatedExperience {
            GoogleAnalytics.log(event: .reportAnOutageUnAuthScreenView)
        } else {
            GoogleAnalytics.log(event: .reportOutageAuthOffer)
        }
        
        if viewModel.shouldPingMeter && !unauthenticatedExperience {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                UIAccessibility.post(notification: .announcement, argument: NSLocalizedString("Checking meter status", comment: ""))
            })
            
            viewModel.meterPingGetStatus(onComplete: { [weak self] meterPingInfo in
                guard let `self` = self else { return }
                
                // Add Lottie Animation
                self.setLottieAnimation(for: "checkmark_blue")
                
                self.meterPingCurrentStatusLabel.text = NSLocalizedString("Check Complete", comment: "")
                self.meterPingStatusView.isHidden = false
                
                var problemsFound = !meterPingInfo.pingResult
                if meterPingInfo.voltageResult {
                    if let voltageReads = meterPingInfo.voltageReads,
                        !voltageReads.lowercased().contains("improper"),
                        voltageReads.lowercased().contains("proper") {
                    } else {
                        problemsFound = true
                    }
                }
                
                if problemsFound {
                    self.meterPingStatusTitleLabel.text = NSLocalizedString("Problems Found", comment: "")
                    self.meterPingStatusDescriptionLabel.text = NSLocalizedString("Problems Found. Please tap \"Submit\" to report an outage.", comment: "")
                    
                    self.areYourLightsOutView.isHidden = true
                    self.viewModel.reportFormHidden.value = false
                } else {
                    self.meterPingFuseBoxView.isHidden = false
                }
                
                self.footerContainerView.isHidden = false
                
                
                UIAccessibility.post(notification: .screenChanged, argument: self)
                UIAccessibility.post(notification: .announcement, argument: NSLocalizedString("Check Complete", comment: ""))
                }, onError: { [weak self] in
                    guard let `self` = self else { return }
                    self.setLottieAnimation(for: "checkmark_blue")
                    
                    self.meterPingCurrentStatusLabel.text = NSLocalizedString("Check Complete", comment: "")
                    
                    self.meterPingStatusView.isHidden = false
                    self.meterPingStatusTitleLabel.text = NSLocalizedString("Problems Found", comment: "")
                    self.meterPingStatusDescriptionLabel.text = NSLocalizedString("Problems Found. Please tap \"Submit\" to report an outage.", comment: "")
                    
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
    
    
    // MARK: - Helper
    
    private func style() {
        // Meter Ping
        meterPingCurrentStatusLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        meterPingCurrentStatusLabel.textColor = .deepGray
        
        // Status View
        meterPingStatusView.layer.borderWidth = 1.0
        meterPingStatusView.layer.borderColor = UIColor.accentGray.cgColor
        meterPingStatusTitleLabel.textColor = .deepGray
        meterPingStatusTitleLabel.font = SystemFont.semibold.of(textStyle: .body)
        meterPingStatusDescriptionLabel.textColor = .deepGray
        meterPingStatusDescriptionLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        // Fuse Box
        meterPingFuseBoxLabel.textColor = .deepGray
        meterPingFuseBoxLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        meterPingFuseBoxLabel.setLineHeight(lineHeight: 25)
        
        // Form
        areYourLightsOutLabel.textColor = .deepGray
        areYourLightsOutLabel.font = SystemFont.regular.of(textStyle: .body)
        howCanWeContactYouLabel.textColor = .deepGray
        howCanWeContactYouLabel.font = SystemFont.regular.of(textStyle: .body)
        commentLabel.textColor = .deepGray
        commentLabel.font = SystemFont.regular.of(textStyle: .body)
    }
    
    private func setLottieAnimation(for name: String, shouldLoop: Bool = false) {
        self.lottieAnimationView?.removeFromSuperview()
        self.lottieAnimationView = LOTAnimationView(name: name)
        self.lottieAnimationView?.frame = CGRect(x: 0, y: 0, width: 33, height: 33)
        self.lottieAnimationView?.loopAnimation = shouldLoop
        self.lottieAnimationView?.contentMode = .scaleToFill
        if let animationView = self.lottieAnimationView {
            self.meterPingCurrentStatusAnimationView.addSubview(animationView)
            animationView.play()
        }
    }
    
    
    // MARK: - Actions
    
    @objc func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func submitButtonPress(_ sender: Any? = nil) {
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
                self.delegate?.didReportOutage()
                self.navigationController?.popViewController(animated: true)
                }, onError: errorBlock)
            GoogleAnalytics.log(event: .reportAnOutageUnAuthSubmit)
        } else {
            viewModel.reportOutage(onSuccess: { [weak self] in
                LoadingView.hide()
                guard let self = self else { return }
                RxNotifications.shared.outageReported.onNext(())
                self.delegate?.didReportOutage()
                self.navigationController?.popViewController(animated: true)
                }, onError: errorBlock)
            GoogleAnalytics.log(event: .reportOutageAuthSubmit)
        }
        
    }
    
    @IBAction func switchPressed(sender: AnyObject) {
        if sender.isEqual(meterPingFuseBoxSwitch) && meterPingFuseBoxSwitch.isOn {
            GoogleAnalytics.log(event: .reportOutageAuthCircuitBreak)
        }
    }
    
    
    // MARK: - ScrollView
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardFrameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber else { return }
        
        let keyboardHeight: CGFloat
        if notification.name == UIResponder.keyboardWillHideNotification {
            keyboardHeight = 0 // view.endEditing() triggers keyboardWillHideNotification with a non-zero height
        } else {
            keyboardHeight = keyboardFrameValue.cgRectValue.size.height
        }
        
        let options = UIView.AnimationOptions(rawValue: curve.uintValue<<16)
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
            self.stickyFooterBottomConstraint.constant = keyboardHeight
            self.view.layoutIfNeeded()
        }, completion: nil)
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
        let screenName: GoogleAnalyticsEvent = unauthenticatedExperience ?
            .reportAnOutageUnAuthEmergencyPhone :
            .reportOutageEmergencyCall
        
        GoogleAnalytics.log(event: screenName)
    }
}
