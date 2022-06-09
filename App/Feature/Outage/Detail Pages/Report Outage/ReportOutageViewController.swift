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

class ReportOutageViewController: KeyboardAvoidingStickyFooterViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var accountInfoBar: AccountInfoBar!
    
    // Meter Ping
    @IBOutlet weak var meterPingStackView: UIStackView!
    
    @IBOutlet weak var meterPingCurrentStatusAnimationView: UIView!
    @IBOutlet weak var meterPingCurrentStatusLabel: UILabel!
    
    @IBOutlet weak var meterPingStatusSeparatorView: UIView!
    @IBOutlet weak var meterPingStatusContainer: UIView!
    @IBOutlet weak var meterPingStatusBox: UIView!
    @IBOutlet weak var meterPingStatusTitleLabel: UILabel!
    @IBOutlet weak var meterPingStatusDescriptionLabel: UILabel!
    
    @IBOutlet weak var meterPingStatusTitleLabelTopAnchor: NSLayoutConstraint!
    @IBOutlet weak var meterPingStatusSeparatorTopAnchor: NSLayoutConstraint!
    
    @IBOutlet weak var meterPingFuseBoxView: UIView!
    @IBOutlet weak var meterPingFuseBoxCheckbox: Checkbox!
    @IBOutlet weak var meterPingFuseBoxLabel: UILabel!
    
    @IBOutlet weak var meterPingSeparatorView: UIView!
    
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
    @IBOutlet weak var footerTextView: DataDetectorTextView!
    
    @IBOutlet weak var submitButton: PrimaryButton!
    
    private var lottieAnimationView: AnimationView?
    
    var delegate: ReportOutageDelegate?
    let viewModel = ReportOutageViewModel()
    let opco = Configuration.shared.opco
    
    let disposeBag = DisposeBag()
    
    var unauthenticatedExperience = false
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return StormModeStatus.shared.isOn ? .lightContent : .default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FirebaseUtility.logEvent(.reportOutageStart)
        
        title = NSLocalizedString("Report Outage", comment: "")
        
        style()
        viewModel.submitEnabled.asDriver().drive(submitButton.rx.isEnabled).disposed(by: disposeBag)
        
        if unauthenticatedExperience,
            let accountNumberText = viewModel.outageStatus?.maskedAccountNumber,
            let addressText = viewModel.outageStatus?.maskedAddress {
            accountInfoBar.configure(accountNumberText: accountNumberText, addressText: "\(addressText)...")
        }
        
        if viewModel.shouldPingPHIMeter || (viewModel.shouldPingMeter && !unauthenticatedExperience) {
            let bg = UIView(frame: meterPingStackView.bounds)
            bg.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            bg.addShadow(color: .black, opacity: 0.08, offset: .zero, radius: 1.5)
            meterPingStackView.addSubview(bg)
            meterPingStackView.sendSubviewToBack(bg)
            
            meterPingStackView.isHidden = false
            meterPingStatusContainer.isHidden = true
            
            meterPingCurrentStatusLabel.text = Configuration.shared.opco.isPHI ? NSLocalizedString("Checking Meter Status", comment: "") : NSLocalizedString("Verifying Meter Status", comment: "")
            
            meterPingFuseBoxView.isHidden = true
            meterPingFuseBoxLabel.text = Configuration.shared.opco.isPHI ? NSLocalizedString("I have checked my circuit breakers or fuse box and would still like to report an outage.", comment: "") : NSLocalizedString("I have checked my circuit breakers or fuse box and I would still like to report an outage.", comment: "")
            meterPingFuseBoxLabel.isAccessibilityElement = false
            meterPingFuseBoxCheckbox.accessibilityLabel = meterPingFuseBoxLabel.text
            meterPingFuseBoxCheckbox.rx.isChecked.asDriver().not().drive(viewModel.reportFormHidden).disposed(by: disposeBag)
            
            meterPingSeparatorView.isHidden = false
            
            viewModel.reportFormHidden.accept(true)
            viewModel.reportFormHidden.asDriver().drive(reportFormStackView.rx.isHidden).disposed(by: disposeBag)
            viewModel.reportFormHidden.asDriver().drive(onNext: { [weak self] hidden in
                if hidden {
                    self?.reportFormStackView.endEditing(true)
                }
            }).disposed(by: disposeBag)
            
            self.setLottieAnimation(for: "smallcircleload_blue", shouldLoop: true)
        } else {
            meterPingStackView.isHidden = true
            meterPingFuseBoxView.isHidden = true
            meterPingSeparatorView.isHidden = true
            viewModel.reportFormHidden.accept(false)
        }
        
        // show comment view for ComEd only
        if opco != .comEd {
            commentView.isHidden = true
        }
        
        if opco == .peco {
            segmentedControl.items = [NSLocalizedString("Yes", comment: ""), NSLocalizedString("Partially", comment: ""), NSLocalizedString("Dim/Flickering", comment: "")]
        } else {
            segmentedControl.items = [NSLocalizedString("Yes", comment: ""), NSLocalizedString("Partially", comment: "")]
        }
        
        phoneNumberTextField.placeholder = opco.isPHI ? NSLocalizedString("Contact Number (Optional)", comment: "") : NSLocalizedString("Contact Number*", comment: "")
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
        
        phoneExtensionTextField.placeholder = NSLocalizedString("Contact Number Ext. (Optional)", comment: "")
        phoneExtensionTextField.textField.customAccessibilityLabel = NSLocalizedString("Contact number extension, optional", comment: "")
        phoneExtensionTextField.textField.autocorrectionType = .no
        phoneExtensionTextField.setKeyboardType(.numberPad)
        phoneExtensionTextField.textField.delegate = self
        
        // show phone extension for ComEd and PECO
        if opco == .bge || opco.isPHI {
            phoneExtensionContainerView.isHidden = true
        }
        
        footerTextView.tintColor = .actionBlue // For the phone numbers
        footerTextView.attributedText = viewModel.footerTextViewText
        footerTextView.linkTapDelegate = self
        
        commentTextView.placeholder = NSLocalizedString("Enter details here (Optional)", comment: "")
        commentTextView.textView.accessibilityLabel = NSLocalizedString("Enter details here, optional", comment: "")
        
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
            submitButton.accessibilityLabel = NSLocalizedString("Report Outage", comment: "")
        } else {
            submitButton.accessibilityLabel = String(format: NSLocalizedString("%@ Report Outage", comment: ""), message)
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
                UIAccessibility.post(notification: .announcement, argument: Configuration.shared.opco.isPHI ? NSLocalizedString("Checking Meter Status", comment: "") : NSLocalizedString("Verifying Meter Status", comment: ""))
            })
            
            viewModel.meterPingGetStatus(onComplete: { [weak self] meterPingInfo in
                guard let `self` = self else { return }
                
                self.setLottieAnimation(for: "checkmark_blue")
                
                self.meterPingCurrentStatusLabel.text = NSLocalizedString("Check Complete", comment: "")
                
                var problemsFound = !meterPingInfo.pingResult
                if meterPingInfo.voltageResult {
                    if let voltageReads = meterPingInfo.voltageReads,
                        !voltageReads.lowercased().contains("improper"),
                        voltageReads.lowercased().contains("proper") {
                    } else {
                        problemsFound = true
                    }
                }
                self.meterPingStatusTitleLabel.isHidden = Configuration.shared.opco.isPHI
                self.meterPingSeparatorView.isHidden = Configuration.shared.opco.isPHI
                if Configuration.shared.opco.isPHI {
                    self.meterPingStatusTitleLabel.heightAnchor.constraint(equalToConstant: 0).isActive = true
                    self.meterPingStatusTitleLabelTopAnchor.constant = 0.0
                    self.meterPingStatusSeparatorTopAnchor.constant = 0.0
                }
                
                if problemsFound {
                    self.meterPingStatusTitleLabel.text = NSLocalizedString("Problems Found", comment: "")
                    self.meterPingStatusDescriptionLabel.text = NSLocalizedString("Please report your outage.", comment: "")
                    
                    self.viewModel.reportFormHidden.accept(false)
                    self.meterPingStatusContainer.isHidden = true
                } else {
                    self.meterPingStatusTitleLabel.text = NSLocalizedString("No Problems Found", comment: "")
                    self.meterPingStatusDescriptionLabel.text = Configuration.shared.opco.isPHI ? NSLocalizedString("Our status check has verified that electrical service is being delivered to your meter.", comment: "") : NSLocalizedString("Our status check verified your property's meter is operational and \(Configuration.shared.opco.displayString) electrical service is being delivered to your home.", comment: "")
                    
                    self.meterPingFuseBoxView.isHidden = false
                    self.meterPingStatusContainer.isHidden = false
                }
                
                UIAccessibility.post(notification: .screenChanged, argument: self)
                UIAccessibility.post(notification: .announcement, argument: NSLocalizedString("Check Complete", comment: ""))
                }, onError: { [weak self] in
                    guard let `self` = self else { return }
                    
                    self.setLottieAnimation(for: "checkmark_blue")
                    
                    self.meterPingCurrentStatusLabel.text = NSLocalizedString("Check Complete", comment: "")
                    
                    self.meterPingStatusContainer.isHidden = true
                    self.meterPingStatusTitleLabel.text = NSLocalizedString("Problems Found", comment: "")
                    self.meterPingStatusDescriptionLabel.text = NSLocalizedString("Please report your outage.", comment: "")
                    
                    self.viewModel.reportFormHidden.accept(false)
                    
                    UIAccessibility.post(notification: .screenChanged, argument: self)
                    UIAccessibility.post(notification: .announcement, argument: NSLocalizedString("Check Complete", comment: ""))
            })
        }
        
        if viewModel.shouldPingPHIMeter && unauthenticatedExperience {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                UIAccessibility.post(notification: .announcement, argument: Configuration.shared.opco.isPHI ? NSLocalizedString("Checking Meter Status", comment: "") : NSLocalizedString("Verifying Meter Status", comment: ""))
            })
            
            viewModel.meterPingGetStatusAnon(onComplete: { [weak self] meterPingInfo in
                guard let `self` = self else { return }
                
                self.setLottieAnimation(for: "checkmark_blue")
                
                self.meterPingCurrentStatusLabel.text = NSLocalizedString("Check Complete", comment: "")
                
                var problemsFound = !meterPingInfo.pingResult
                if meterPingInfo.voltageResult {
                    if let voltageReads = meterPingInfo.voltageReads,
                        !voltageReads.lowercased().contains("improper"),
                        voltageReads.lowercased().contains("proper") {
                    } else {
                        problemsFound = true
                    }
                }
                self.meterPingStatusTitleLabel.isHidden = Configuration.shared.opco.isPHI
                self.meterPingSeparatorView.isHidden = Configuration.shared.opco.isPHI
                if Configuration.shared.opco.isPHI {
                    self.meterPingStatusTitleLabel.heightAnchor.constraint(equalToConstant: 0).isActive = true
                    self.meterPingStatusTitleLabelTopAnchor.constant = 0.0
                    self.meterPingStatusSeparatorTopAnchor.constant = 0.0
                }
                if problemsFound {
                    self.meterPingStatusTitleLabel.text = NSLocalizedString("Problems Found", comment: "")
                    self.meterPingStatusDescriptionLabel.text = NSLocalizedString("Please report your outage.", comment: "")
                    
                    self.viewModel.reportFormHidden.accept(false)
                    self.meterPingStatusContainer.isHidden = true
                } else {
                    self.meterPingStatusTitleLabel.text = NSLocalizedString("No Problems Found", comment: "")
                    self.meterPingStatusDescriptionLabel.text = Configuration.shared.opco.isPHI ? NSLocalizedString("Our status check has verified that electrical service is being delivered to your meter.", comment: "") : NSLocalizedString("Our status check verified your property's meter is operational and \(Configuration.shared.opco.displayString) electrical service is being delivered to your home.", comment: "")
                    
                    self.meterPingFuseBoxView.isHidden = false
                    self.meterPingStatusContainer.isHidden = false
                }
                
                UIAccessibility.post(notification: .screenChanged, argument: self)
                UIAccessibility.post(notification: .announcement, argument: NSLocalizedString("Check Complete", comment: ""))
                }, onError: { [weak self] in
                    guard let `self` = self else { return }
                    
                    self.setLottieAnimation(for: "checkmark_blue")
                    
                    self.meterPingCurrentStatusLabel.text = NSLocalizedString("Check Complete", comment: "")
                    
                    self.meterPingStatusContainer.isHidden = true
                    self.meterPingStatusTitleLabel.text = NSLocalizedString("Problems Found", comment: "")
                    self.meterPingStatusDescriptionLabel.text = NSLocalizedString("Please report your outage.", comment: "")
                    
                    self.viewModel.reportFormHidden.accept(false)
                    
                    UIAccessibility.post(notification: .screenChanged, argument: self)
                    UIAccessibility.post(notification: .announcement, argument: NSLocalizedString("Check Complete", comment: ""))
            })
        }
    }
    
    // MARK: - Helper
    
    private func style() {
        // Meter Ping
        meterPingCurrentStatusLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        meterPingCurrentStatusLabel.textColor = .deepGray
        
        // Status View
        meterPingStatusBox.layer.borderWidth = 1.0
        meterPingStatusBox.layer.borderColor = UIColor.accentGray.cgColor
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
        self.lottieAnimationView = AnimationView(name: name)
        self.lottieAnimationView?.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        self.lottieAnimationView?.loopMode = shouldLoop ? .loop : .playOnce
        self.lottieAnimationView?.backgroundBehavior = .pauseAndRestore
        self.lottieAnimationView?.contentMode = .scaleAspectFit
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
        FirebaseUtility.logEvent(.reportOutageSubmit)
        
        if unauthenticatedExperience {
            FirebaseUtility.logEvent(.unauthOutage(parameters: [.report_outage]))
        } else {
            FirebaseUtility.logEvent(.authOutage(parameters: [.report_outage]))
        }
        
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
                FirebaseUtility.logEvent(.reportOutageNetworkComplete)
                FirebaseUtility.logEvent(.unauthOutage(parameters: [.report_complete]))
                
                GoogleAnalytics.log(event: .reportAnOutageUnAuthComplete)
                
                LoadingView.hide()
                guard let self = self else { return }
                RxNotifications.shared.outageReported.onNext(())
                self.delegate?.didReportOutage()
                self.navigationController?.popViewController(animated: true)
                }, onError: errorBlock)
            GoogleAnalytics.log(event: .reportAnOutageUnAuthSubmit)
        } else {
            viewModel.reportOutage(onSuccess: { [weak self] in
                FirebaseUtility.logEvent(.reportOutageNetworkComplete)
                FirebaseUtility.logEvent(.authOutage(parameters: [.report_complete]))
                
                GoogleAnalytics.log(event: .reportOutageAuthComplete)
                
                LoadingView.hide()
                guard let self = self else { return }
                RxNotifications.shared.outageReported.onNext(())
                self.delegate?.didReportOutage()
                self.navigationController?.popViewController(animated: true)
                }, onError: errorBlock)
            GoogleAnalytics.log(event: .reportOutageAuthSubmit)
        }
        
    }
    
    @IBAction func checkboxToggled() {
        if meterPingFuseBoxCheckbox.isChecked {
            GoogleAnalytics.log(event: .reportOutageAuthCircuitBreak)
        }
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
