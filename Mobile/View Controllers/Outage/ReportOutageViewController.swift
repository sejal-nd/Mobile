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
    func didReportOutage(sender: ReportOutageViewController)
}

class ReportOutageViewController: UIViewController, UITextFieldDelegate {
    
    weak var delegate: ReportOutageViewControllerDelegate?
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var segmentedControl: SegmentedControl!
    @IBOutlet weak var phoneNumberTextField: FloatLabelTextField!
    @IBOutlet weak var phoneExtensionTextField: FloatLabelTextField!
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
        
        if opco == "PECO" {
            segmentedControl.items = ["Yes", "Partially", "Dim/\nFlickering"]
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
        
        footerContainerView.layer.shadowColor = UIColor.black.cgColor
        footerContainerView.layer.shadowOpacity = 0.15
        footerContainerView.layer.shadowRadius = 2
        footerContainerView.layer.shadowOffset = CGSize(width: 0, height: 0)
        footerContainerView.layer.masksToBounds = false
        
        footerTextView.textContainerInset = UIEdgeInsets(top: 16, left: 29, bottom: 16, right: 29)
        footerTextView.textColor = .darkJungleGreen
        footerTextView.tintColor = .mediumPersianBlue // For the phone numbers
        footerTextView.text = viewModel.getFooterTextViewText()
        footerTextView.layer.shadowColor = UIColor.black.cgColor
        footerTextView.layer.shadowOpacity = 0.15
        footerTextView.layer.shadowRadius = 2
        footerTextView.layer.shadowOffset = CGSize(width: 0, height: 1)
        footerTextView.layer.masksToBounds = false
        
        // Data binding
        segmentedControl.selectedIndex.asObservable().bindTo(viewModel.selectedSegmentIndex).addDisposableTo(disposeBag)
        
        viewModel.phoneNumber.asObservable().bindTo(phoneNumberTextField.textField.rx.text.orEmpty).addDisposableTo(disposeBag)
        phoneNumberTextField.textField.rx.text.orEmpty.bindTo(viewModel.phoneNumber).addDisposableTo(disposeBag)
        phoneNumberTextField.textField.sendActions(for: .editingDidEnd)
        
        phoneExtensionTextField.textField.rx.text.orEmpty.bindTo(viewModel.phoneExtension).addDisposableTo(disposeBag)
        
        // Format the intial value
        let range = NSMakeRange(0, viewModel.phoneNumber.value.characters.count)
        _ = textField(phoneNumberTextField.textField, shouldChangeCharactersIn: range, replacementString: viewModel.phoneNumber.value)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            self.delegate?.didReportOutage(sender: self)
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
