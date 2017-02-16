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
    
    @IBOutlet weak var scrollView: UIScrollView!
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
        
        let termsString = "Messenger bag post-ironic PBR&B, cardigan kale chips 3 wolf moon church-key whatever gastropub single-origin coffee sartorial neutra echo park. Tumblr synth hell of, chia truffaut pour-over disrupt cornhole ethical four loko typewriter blog microdosing meh art party. Four loko pabst typewriter cold-pressed health goth tofu vaporware, ennui bicycle rights bushwick twee kombucha pug. IPhone snackwave gastropub williamsburg fam tote bag. Banh mi raw denim bitters mumblecore. Roof party aesthetic offal banh mi pabst, plaid authentic. Banh mi kitsch brunch, helvetica kickstarter kombucha pinterest. Meggings freegan aesthetic skateboard twee +1. Organic chambray portland pinterest prism cardigan. Pitchfork pickled sustainable schlitz fingerstache church-key affogato venmo, narwhal shabby chic umami yr etsy. Church-key heirloom affogato craft beer, activated charcoal locavore hexagon +1 meggings. Tbh yr blue bottle tumeric semiotics bespoke. Skateboard vexillologist meh cred PBR&B. Pinterest poutine deep v keffiyeh bitters celiac. Roof party trust fund mlkshk shabby chic meggings vice air plant quinoa. Paleo umami coloring book succulents, kickstarter dreamcatcher heirloom plaid pok pok gluten-free leggings banjo. Thundercats listicle paleo actually roof party normcore. Woke kogi tumblr, edison bulb bitters 3 wolf moon asymmetrical paleo typewriter schlitz swag portland master cleanse listicle hoodie. Normcore hot chicken bespoke edison bulb taxidermy heirloom. Put a bird on it truffaut meh, normcore flannel blog sartorial tbh hexagon post-ironic small batch lomo pabst taxidermy. Deep v green juice meditation, pickled pok pok before they sold out copper mug hammock lomo pug sustainable roof party tofu put a bird on it bushwick. Polaroid tofu locavore umami cred mlkshk. Succulents selvage blue bottle, sartorial meggings DIY offal cold-pressed. Craft beer flannel kale chips, affogato vaporware keytar offal wolf post-ironic cornhole twee. Pabst hoodie live-edge swag, etsy blue bottle mixtape. Brooklyn salvia keytar mustache fixie pitchfork mixtape iceland. Letterpress hell of pop-up chambray blue bottle, cronut fap chillwave tumblr snackwave. Meditation small batch authentic, pabst squid blog semiotics coloring book hella single-origin coffee umami."
        
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
