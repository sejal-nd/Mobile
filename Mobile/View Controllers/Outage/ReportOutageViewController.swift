//
//  ReportOutageViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 3/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import MBProgressHUD
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
    @IBOutlet weak var segmentedControl: SegmentedControl!
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Report Outage", comment: "")

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = submitButton
        viewModel.submitButtonEnabled().bindTo(submitButton.rx.isEnabled).addDisposableTo(disposeBag)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        // METER PING
        if Environment.sharedInstance.opco == "ComEd" {
            let bg = UIView(frame: meterPingStackView.bounds)
            bg.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            bg.backgroundColor = .whiteSmoke
            bg.layer.shadowColor = UIColor.black.cgColor
            bg.layer.shadowOpacity = 0.08
            bg.layer.shadowRadius = 1.5
            bg.layer.shadowOffset = CGSize(width: 0, height: 0)
            bg.layer.masksToBounds = false
            meterPingStackView.addSubview(bg)
            meterPingStackView.sendSubview(toBack: bg)
            
            meterPingStackView.spacing = 20
            meterPingStackView.isHidden = false

            footerContainerView.isHidden = true
            
            meterPingFuseBoxSwitch.rx.isOn.map(!).bindTo(viewModel.reportFormHidden).addDisposableTo(disposeBag)
            viewModel.reportFormHidden.asObservable().bindTo(reportFormStackView.rx.isHidden).addDisposableTo(disposeBag)
            viewModel.reportFormHidden.asObservable().subscribe(onNext: { hidden in
                if hidden {
                    self.reportFormStackView.spacing = 0
                    self.reportFormStackView.endEditing(true)
                } else {
                    self.reportFormStackView.spacing = 30
                }
            }).addDisposableTo(disposeBag)
            
            viewModel.reportFormHidden.value = true

            meterPingCurrentStatusLabel.textColor = .darkJungleGreen
            meterPingPowerStatusLabel.textColor = .oldLavender
            meterPingVoltageStatusLabel.textColor = .oldLavender
            meterPingResultLabel.textColor = .outerSpace
            meterPingFuseBoxLabel.textColor = .oldLavender
            meterPingFuseBoxLabel.setLineHeight(lineHeight: 25)
            
            let lottieAnimation = LOTAnimationView(name: "loading_blue")!
            lottieAnimation.frame = CGRect(x: 0, y: 0, width: 33, height: 33)
            lottieAnimation.loopAnimation = true
            lottieAnimation.contentMode = .scaleToFill
            meterPingCurrentStatusLoadingView.addSubview(lottieAnimation)
            lottieAnimation.play()
        }

        if opco == "PECO" {
            segmentedControl.items = [NSLocalizedString("Yes", comment: ""), NSLocalizedString("Partially", comment: ""), NSLocalizedString("Dim/Flickering", comment: "")]
        } else {
            segmentedControl.items = [NSLocalizedString("Yes", comment: ""), NSLocalizedString("Partially", comment: "")]
        }

        phoneNumberTextField.textField.placeholder = NSLocalizedString("Contact Number *", comment: "")
        phoneNumberTextField.textField.keyboardType = .phonePad
        phoneNumberTextField.textField.delegate = self
        phoneExtensionTextField.textField.placeholder = NSLocalizedString("Contact Number Ext. (Optional)", comment: "")
        phoneExtensionTextField.textField.keyboardType = .phonePad
        phoneExtensionTextField.textField.delegate = self

        if opco == "BGE" {
            phoneExtensionContainerView.isHidden = true
        }
        
        footerBackgroundView.backgroundColor = .whiteSmoke
        footerBackgroundView.layer.shadowColor = UIColor.black.cgColor
        footerBackgroundView.layer.shadowOpacity = 0.08
        footerBackgroundView.layer.shadowRadius = 1.5
        footerBackgroundView.layer.shadowOffset = CGSize(width: 0, height: 0)
        footerBackgroundView.layer.masksToBounds = false
        
        footerTextView.textContainerInset = UIEdgeInsets(top: 16, left: 29, bottom: 16, right: 29)
        footerTextView.textColor = .darkJungleGreen
        footerTextView.tintColor = .mediumPersianBlue // For the phone numbers
        footerTextView.text = viewModel.getFooterTextViewText()
        footerTextView.layer.shadowColor = UIColor.black.cgColor
        footerTextView.layer.shadowOpacity = 0.06
        footerTextView.layer.shadowRadius = 2
        footerTextView.layer.shadowOffset = CGSize(width: 0, height: 2)
        footerTextView.layer.masksToBounds = false
        
        // Data binding
        segmentedControl.selectedIndex.asObservable().bindTo(viewModel.selectedSegmentIndex).addDisposableTo(disposeBag)
        
        viewModel.phoneNumber.asObservable().bindTo(phoneNumberTextField.textField.rx.text.orEmpty)
            .addDisposableTo(disposeBag)
        phoneNumberTextField.textField.rx.text.orEmpty.bindTo(viewModel.phoneNumber).addDisposableTo(disposeBag)
        phoneNumberTextField.textField.sendActions(for: .editingDidEnd)
        
        phoneExtensionTextField.textField.rx.text.orEmpty.bindTo(viewModel.phoneExtension).addDisposableTo(disposeBag)
        
        // Format the intial value
        let range = NSMakeRange(0, viewModel.phoneNumber.value.characters.count)
        _ = textField(phoneNumberTextField.textField, shouldChangeCharactersIn: range, replacementString: viewModel.phoneNumber.value)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // METER PING
        if Environment.sharedInstance.opco == "ComEd" {
            viewModel.meterPingGetPowerStatus(onPowerVerified: { canPerformVoltageCheck in
                self.meterPingPowerStatusImageView.image = #imageLiteral(resourceName: "ic_successcheckcircle")
                self.meterPingPowerStatusLabel.textColor = .darkJungleGreen
                
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
                        self.meterPingVoltageStatusLabel.textColor = .darkJungleGreen
                        
                        self.meterPingFuseBoxView.isHidden = false
                        self.footerContainerView.isHidden = false
                    }, onError: { error in // VOLTAGE STATUS ERROR
                        self.meterPingCurrentStatusLoadingView.isHidden = true
                        self.meterPingCurrentStatusCheckImageView.isHidden = false
                        self.meterPingCurrentStatusCheckImageView.image = #imageLiteral(resourceName: "ic_check_meterping_fail")
                        self.meterPingCurrentStatusLabel.text = NSLocalizedString("Check Complete", comment: "")
                        
                        self.meterPingVoltageStatusImageView.image = #imageLiteral(resourceName: "ic_failxcircle")
                        self.meterPingVoltageStatusLabel.textColor = .darkJungleGreen
                        
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
                self.meterPingPowerStatusLabel.textColor = .darkJungleGreen
                
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
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.bezelView.style = MBProgressHUDBackgroundStyle.solidColor
        hud.bezelView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        hud.contentColor = .white
        viewModel.reportOutage(onSuccess: {
            hud.hide(animated: true)
            self.delegate?.reportOutageViewControllerDidReportOutage(self)
            _ = self.navigationController?.popViewController(animated: true)
        }) { error in
            print(error)
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
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        let components = newString.components(separatedBy: CharacterSet.decimalDigits.inverted)
        
        let decimalString = components.joined(separator: "") as NSString
        let length = decimalString.length
        let hasLeadingOne = length > 0 && decimalString.character(at: 0) == (1 as unichar)
        
        if length == 0 || (length > 10 && !hasLeadingOne) || length > 11 {
            let newLength = (textField.text! as NSString).length + (string as NSString).length - range.length as Int
            
            return (newLength > 10) ? false : true
        }
        var index = 0 as Int
        let formattedString = NSMutableString()
        
        if hasLeadingOne {
            formattedString.append("1 ")
            index += 1
        }
        if (length - index) > 3 {
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
    }
}
