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

protocol ReportOutageViewControllerDelegate: class {
    func reportOutageViewControllerDidReportOutage(_ reportOutageViewController: ReportOutageViewController)
}

class ReportOutageViewController: UIViewController {
    
    weak var delegate: ReportOutageViewControllerDelegate?
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    // Meter Ping
    @IBOutlet weak var meterPingStackView: UIStackView!
    
    @IBOutlet weak var meterPingCurrentStatusImageView: UIImageView!
    @IBOutlet weak var meterPingCurrentStatusActivityIndicator: UIActivityIndicatorView!
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
    @IBOutlet weak var reportFormView: UIView!
    @IBOutlet weak var segmentedControl: SegmentedControl!
    @IBOutlet weak var phoneNumberTextField: FloatLabelTextField!
    @IBOutlet weak var phoneExtensionTextField: FloatLabelTextField!
    
    // Footer View
    @IBOutlet weak var footerContainerView: UIView!
    @IBOutlet weak var footerTextView: DataDetectorTextView!
    
    let viewModel = ReportOutageViewModel(outageService: ServiceFactory.createOutageService())
    let opco = Environment.sharedInstance.opco
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let submitButton = UIBarButtonItem(title: "Submit", style: .done, target: self, action: #selector(onSubmitPress))
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
            reportFormView.isHidden = true
            
            meterPingFuseBoxSwitch.rx.isOn.map(!).bindTo(viewModel.reportFormHidden).addDisposableTo(disposeBag)
            viewModel.reportFormHidden.asObservable().bindTo(reportFormView.rx.isHidden).addDisposableTo(disposeBag)
            viewModel.reportFormHidden.asObservable().subscribe(onNext: { hidden in
                if hidden {
                    self.reportFormView.endEditing(true)
                }
            }).addDisposableTo(disposeBag)

            meterPingCurrentStatusActivityIndicator.tintColor = .mediumPersianBlue
            meterPingCurrentStatusLabel.textColor = .darkJungleGreen
            meterPingPowerStatusLabel.textColor = .oldLavender
            meterPingVoltageStatusLabel.textColor = .oldLavender
            meterPingResultLabel.textColor = .outerSpace
            meterPingFuseBoxLabel.textColor = .oldLavender
            meterPingFuseBoxLabel.setLineHeight(lineHeight: 25)
        }

        if opco == "PECO" {
            segmentedControl.items = ["Yes", "Partially", "Dim/Flickering"]
        } else {
            segmentedControl.items = ["Yes", "Partially"]
        }

        phoneNumberTextField.textField.placeholder = "Contact Number *"
        phoneNumberTextField.textField.keyboardType = .phonePad
        phoneNumberTextField.textField.delegate = self
        phoneExtensionTextField.textField.placeholder = "Contact Number Ext. (Optional)"
        phoneExtensionTextField.textField.keyboardType = .phonePad
        phoneExtensionTextField.textField.delegate = self

        if opco == "BGE" {
            phoneExtensionTextField.isHidden = true
        }
        
        footerContainerView.backgroundColor = .whiteSmoke
        footerContainerView.layer.shadowColor = UIColor.black.cgColor
        footerContainerView.layer.shadowOpacity = 0.08
        footerContainerView.layer.shadowRadius = 1.5
        footerContainerView.layer.shadowOffset = CGSize(width: 0, height: 0)
        footerContainerView.layer.masksToBounds = false
        
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
                    self.meterPingCurrentStatusActivityIndicator.isHidden = true
                    self.meterPingCurrentStatusImageView.isHidden = false
                    self.meterPingCurrentStatusLabel.text = "Check Complete"
                    self.meterPingResultLabel.isHidden = false
                    self.meterPingResultLabel.text = "Our status check verified your property's meter is operational and ComEd electrical service is being delivered to your home"
                    self.meterPingResultLabel.setLineHeight(lineHeight: 25)
                    self.meterPingFuseBoxView.isHidden = false
                } else { // POWER STATUS SUCCESS
                    self.meterPingCurrentStatusLabel.text = "Verifying voltage level of the meter..."
                    self.meterPingVoltageStatusView.isHidden = false
                    self.viewModel.meterPingGetVoltageStatus(onVoltageVerified: {
                        self.meterPingCurrentStatusActivityIndicator.isHidden = true
                        self.meterPingCurrentStatusImageView.isHidden = false
                        self.meterPingCurrentStatusLabel.text = "Check Complete"
                        
                        self.meterPingVoltageStatusImageView.image = #imageLiteral(resourceName: "ic_successcheckcircle")
                        self.meterPingVoltageStatusLabel.textColor = .darkJungleGreen
                        
                        self.meterPingFuseBoxView.isHidden = false
                    }, onError: { error in // VOLTAGE STATUS ERROR
                        self.meterPingCurrentStatusActivityIndicator.isHidden = true
                        self.meterPingCurrentStatusImageView.isHidden = false
                        self.meterPingCurrentStatusImageView.image = #imageLiteral(resourceName: "ic_check_meterping_fail")
                        self.meterPingCurrentStatusLabel.text = "Check Complete"
                        
                        self.meterPingVoltageStatusImageView.image = #imageLiteral(resourceName: "ic_failxcircle")
                        self.meterPingVoltageStatusLabel.textColor = .darkJungleGreen
                        
                        self.meterPingResultLabel.isHidden = false
                        self.meterPingResultLabel.text = "Problems Found. Please tap \"Submit\" to report an outage."
                        
                        self.viewModel.reportFormHidden.value = false
                    })
                }

            }, onError: { error in // POWER STATUS ERROR
                self.meterPingCurrentStatusActivityIndicator.isHidden = true
                self.meterPingCurrentStatusImageView.isHidden = false
                self.meterPingCurrentStatusImageView.image = #imageLiteral(resourceName: "ic_check_meterping_fail")
                self.meterPingCurrentStatusLabel.text = "Check Complete"
                
                self.meterPingPowerStatusImageView.image = #imageLiteral(resourceName: "ic_failxcircle")
                self.meterPingPowerStatusLabel.textColor = .darkJungleGreen
                
                self.meterPingResultLabel.isHidden = false
                self.meterPingResultLabel.text = "Problems Found. Please tap \"Submit\" to report an outage."
                
                self.viewModel.reportFormHidden.value = false
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
