//
//  AlertPreferencesNotificationsSettingsCell.swift
//  Mobile
//
//  Created by Samuel Francis on 9/28/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class AlertPreferencesNotificationsSettingsCell: UITableViewCell {

    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var button: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        label.textColor = .deepGray
        label.font = SystemFont.regular.of(textStyle: .footnote)
        label.text = String(format: NSLocalizedString("Your notifications are currently disabled on your device. Please visit your device settings to allow %@ to send notifications.", comment: ""), Environment.shared.opco.displayString)
        button.setTitleColor(.actionBlue, for: .normal)
        button.titleLabel?.font = SystemFont.semibold.of(textStyle: .body)
        button.titleLabel?.text = NSLocalizedString("Go to Settings", comment: "")
    }

    @IBAction func goToSettingsPressed(_ sender: Any) {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            GoogleAnalytics.log(event: .alertsDevSet)
            UIApplication.shared.open(url)
        }
    }
}
