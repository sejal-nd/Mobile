//
//  SmartEnergyRewardsHistoryViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 10/25/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class TotalSavingsViewController: UIViewController {
    
    @IBOutlet weak var totalSavingsValueLabel: UILabel!
    @IBOutlet weak var totalSavingsTitleLabel: UILabel!
    @IBOutlet weak var leftArrowImageView: UIImageView!
    @IBOutlet weak var rightArrowImageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewWidthConstraint: NSLayoutConstraint!
    
    var eventResults: [SERResult]! // Passed from HomeViewController/SmartEnergyRewardsViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Total Savings", comment: "")
        
        eventResults = eventResults.reversed() // Sort most recent at the top
        
        totalSavingsValueLabel.textColor = .primaryColor
        totalSavingsValueLabel.font = OpenSans.semibold.of(size: 30)
        totalSavingsValueLabel.text = totalSavingsValue.currencyString
        
        totalSavingsTitleLabel.textColor = .blackText
        totalSavingsTitleLabel.font = OpenSans.bold.of(textStyle: .subheadline)
        totalSavingsTitleLabel.text = NSLocalizedString("Total Bill Credits", comment: "")
        
        tableView.separatorColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1)
        
        // 581 is the fixed width of the tableView with a horizontal margin of 31 on each cell.
        // This assumes the text is sized up as far as possible. But with the text at the normal size,
        // This would cause extra margin on the right side. So we calculate the actual width of the
        // "Energy Savings" header label and subtract the difference from it's fixed width (115) from
        // the tableView's width, resulting in us always having the 31 margin regardless of text size
        let boundingBox = NSLocalizedString("Energy Savings", comment: "").boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 20),
                                                                                        options: .usesLineFragmentOrigin,
                                                                                        attributes: [.font: SystemFont.medium.of(textStyle: .footnote)],
                                                                                        context: nil)
        let energySavingsLabelWidth = ceil(boundingBox.width)
        tableViewWidthConstraint.constant = 581 - (115 - energySavingsLabelWidth)
    }
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)

        scrollViewDidScroll(scrollView)
    }
    
    private var totalSavingsValue: Double {
        var val = 0.0
        for result in eventResults {
            val += result.savingDollar
        }
        return val
    }

}

extension TotalSavingsViewController: UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventResults.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TotalSavingsHeaderCell") as! TotalSavingsHeaderCell
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.5
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 0.5))
        view.backgroundColor = tableView.separatorColor
        return view
    }
    
}

extension TotalSavingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TotalSavingsCell", for: indexPath) as! TotalSavingsTableViewCell
        
        cell.bindToEvent(eventResults[indexPath.row])
        if (indexPath.row + 1) % 2 == 0 {
            cell.backgroundColor = .softGray
        } else {
            cell.backgroundColor = .white
        }
        
        return cell
    }
}

extension TotalSavingsViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.scrollView { // Ignore tableView vertical scrolling
            let xPos = scrollView.contentOffset.x

            if xPos <= 31 {
                leftArrowImageView.alpha = xPos / 31
            } else {
                leftArrowImageView.alpha = 1
            }
            
            let offscreenWidth = tableViewWidthConstraint.constant - view.bounds.size.width
            if xPos >= offscreenWidth - 31 {
                rightArrowImageView.alpha = ((offscreenWidth - xPos) / 31)
            } else {
                rightArrowImageView.alpha = 1
            }
        }
    }
}
