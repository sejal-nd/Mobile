//
//  LoginTermsConditionsViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class LoginTermsConditionsViewController: UIViewController {
    
    @IBOutlet weak var agreeSwitch: UISwitch!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var agreeView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.textContainerInset = UIEdgeInsetsMake(0, 12, 8, 16)
        textView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 8, 4)

        agreeView.layer.shadowColor = UIColor.black.cgColor
        agreeView.layer.shadowOffset = CGSize(width: 0, height: -1)
        agreeView.layer.shadowOpacity = 0.1
        agreeView.layer.shadowRadius = 2
        agreeView.layer.masksToBounds = false

        agreeSwitch.tintColor = UIColor(red: 193/255, green: 193/255, blue: 193/255, alpha: 1)
        agreeSwitch.onTintColor = .primaryColor
        agreeSwitch.backgroundColor = .switchOffColor
        agreeSwitch.layer.cornerRadius = 16
        _ = agreeSwitch.rx.isOn.bindTo(continueButton.rx.isEnabled)
        
        let termsString = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas accumsan libero in laoreet malesuada. Aliquam volutpat velit sed purus ornare sollicitudin. Morbi iaculis metus id urna iaculis, vel pulvinar urna molestie. Ut nec est nec ipsum fringilla gravida. Nam non tellus purus. Mauris blandit diam quis arcu pellentesque mattis. Morbi aliquam arcu eu ligula ultrices, id congue elit hendrerit. Nam nisl velit, aliquam at commodo sit amet, pharetra sed enim. Praesent eu elit mauris. Fusce hendrerit pulvinar sapien, eu feugiat tortor dignissim vel. Nunc et nunc in turpis mollis vestibulum dignissim nec lectus. Nulla dolor sapien, maximus non lectus eu, lacinia tristique libero. Phasellus ut vulputate lectus. Morbi dolor enim, fringilla non orci sed, interdum auctor dui. Aenean purus libero, laoreet ut urna et, ultrices convallis est. Integer eu sapien sapien. Fusce aliquam, lorem a venenatis iaculis, dolor justo tempor leo, eu dapibus quam quam eget ex. Donec et imperdiet sapien, et vehicula nulla. Aliquam sed massa risus. Duis sit amet ullamcorper velit. Curabitur a neque in urna sollicitudin ullamcorper. Etiam nisl ligula, rhoncus sit amet sem ut, varius dignissim arcu. Etiam volutpat mauris vel mauris vehicula hendrerit ac sit amet ipsum. Vestibulum id dignissim lacus, ac fermentum diam. Pellentesque nisl massa, laoreet faucibus pellentesque nec, commodo a mi. Nulla mattis tincidunt urna a blandit. Duis at metus molestie, pretium nisi sed, dignissim tellus. Integer a hendrerit velit. Vestibulum eget pellentesque mauris. In hac habitasse platea dictumst. Suspendisse nec dapibus erat. Vestibulum rhoncus id tortor et fermentum. Nam condimentum elit magna, sed iaculis arcu finibus vel. Donec volutpat dui id velit luctus laoreet. Praesent turpis orci, sagittis ut enim eget, efficitur elementum justo. Curabitur laoreet, augue sed convallis tincidunt, felis sapien feugiat purus, vitae efficitur massa quam eu urna. Donec mattis, eros id dignissim iaculis, ante sapien placerat risus, a maximus sem quam a leo. Donec finibus aliquam condimentum. Suspendisse venenatis felis at viverra pretium. Proin accumsan sem in orci mattis interdum varius tempor velit. Sed nec faucibus neque, euismod eleifend metus. Curabitur vitae ligula quis orci dignissim interdum. Suspendisse auctor nunc vitae justo ullamcorper euismod. Etiam non porttitor justo. Nam euismod dolor libero, nec lacinia velit vehicula sit amet. Nullam vitae congue libero. Nam eleifend nisi vel ipsum volutpat, eget laoreet ante semper. Aenean et ipsum nec neque consectetur laoreet sit amet sed orci. In massa arcu, faucibus in auctor tincidunt, aliquam at urna. Nullam suscipit ligula eget justo suscipit, et lobortis est pellentesque. Maecenas volutpat fringilla lorem vitae bibendum. Aliquam vestibulum odio at libero elementum bibendum consectetur vitae ante. Proin tempus augue nibh, ut sodales erat hendrerit quis. Fusce eu turpis gravida, ullamcorper magna eget, commodo ex."
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 10
        let attrString = NSMutableAttributedString(string: termsString)
        attrString.addAttribute(NSParagraphStyleAttributeName, value:paragraphStyle, range:NSMakeRange(0, attrString.length))
        attrString.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 17), range: NSMakeRange(0, attrString.length))
        textView.attributedText = attrString
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onContinuePress() {
        UserDefaults.standard.set(true, forKey: UserDefaultKeys.HasAcceptedTerms)
        dismiss(animated: true, completion: nil)
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
