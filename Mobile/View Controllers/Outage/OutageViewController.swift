//
//  OutageViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 3/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import Lottie
import MBProgressHUD

class OutageViewController: UIViewController {
    
    @IBOutlet weak var gradientBackground: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var accountScroller: AccountScroller!
    @IBOutlet weak var accountContentView: UIView!
    @IBOutlet weak var gasOnlyView: UIView!
    @IBOutlet weak var accountScrollerActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var outageStatusActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var outerCircleView: UIView!
    @IBOutlet weak var innerCircleView: UIView!
    @IBOutlet weak var bigButtonView: UIView!
    @IBOutlet weak var reportOutageButton: TableViewCellButton!
    @IBOutlet weak var viewOutageMapButton: TableViewCellButton!
    @IBOutlet weak var gasOnlyTextView: DataDetectorTextView!
    @IBOutlet weak var footerTextView: DataDetectorTextView!
    
    var gradientLayer: CAGradientLayer!
    
    var onAnimationView = LOTAnimationView(name: "outage")!
    var refreshControl: UIRefreshControl!
    
    let viewModel = OutageViewModel(accountService: ServiceFactory.createAccountService(), outageService: ServiceFactory.createOutageService())
    
    override func viewDidLoad() {
        super.viewDidLoad()

        gradientLayer = CAGradientLayer()
        gradientLayer.frame = gradientBackground.bounds
        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor(red: 246/255, green: 247/255, blue: 248/255, alpha: 1).cgColor,
            UIColor(red: 240/255, green: 242/255, blue: 243/255, alpha: 1).cgColor
        ]
        gradientLayer.locations = [0.0, 0.38, 1.0]
        gradientBackground.layer.addSublayer(gradientLayer)
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
        scrollView.insertSubview(refreshControl, at: 0)

        accountScroller.delegate = self

        onAnimationView.frame = CGRect(x: 0, y: 0, width: animationView.frame.size.width, height: animationView.frame.size.height)
        onAnimationView.loopAnimation = true
        onAnimationView.contentMode = .scaleAspectFill
        animationView.addSubview(onAnimationView)
        onAnimationView.play()
        
        outerCircleView.layer.cornerRadius = outerCircleView.bounds.size.width / 2
        innerCircleView.layer.cornerRadius = innerCircleView.bounds.size.width / 2
        
        let radius = bigButtonView.bounds.size.width / 2
        bigButtonView.layer.cornerRadius = radius
        bigButtonView.layer.shadowColor = UIColor.black.cgColor
        bigButtonView.layer.shadowOpacity = 0.3
        bigButtonView.layer.shadowOffset = CGSize(width: 0, height: 10)
        bigButtonView.layer.shadowRadius = 10 // Blur of 20pt
        bigButtonView.layer.shadowPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: (radius + 2) * 2, height: (radius + 2) * 2), cornerRadius: radius).cgPath // Spread of 2pt
        bigButtonView.layer.masksToBounds = false
        bigButtonView.clipsToBounds = true
        bigButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onBigButtonTap)))
        
        footerTextView.textContainerInset = .zero
        footerTextView.textColor = .darkJungleGreen
        footerTextView.tintColor = .mediumPersianBlue // For the phone numbers
        footerTextView.text = viewModel.getFooterTextViewText()
        
        gasOnlyTextView.textContainerInset = .zero
        gasOnlyTextView.tintColor = .mediumPersianBlue
        gasOnlyTextView.text = viewModel.getGasOnlyMessage()
        
        accountScroller.isHidden = true
        accountContentView.isHidden = true
        
        accountScrollerActivityIndicator.color = .mediumPersianBlue
        outageStatusActivityIndicator.color = .mediumPersianBlue
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if viewModel.currentAccount == nil {
            accountScrollerActivityIndicator.isHidden = false
            viewModel.getAccounts(onSuccess: { accounts in
                self.accountScrollerActivityIndicator.isHidden = true
                self.accountScroller.setAccounts(accounts)
                self.accountScroller.isHidden = false
                self.getOutageStatus()
            }, onError: { error in
                print("getAccounts error = \(error)")
                self.accountScrollerActivityIndicator.isHidden = true
            })
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradientLayer.frame = gradientBackground.frame
    }
    
    func updateContent() {
        layoutBigButtonContent()
        
        let currentOutageStatus = viewModel.currentOutageStatus!
        
        errorLabel.isHidden = true
        
        // Show/hide the top level container views
        gasOnlyView.isHidden = !currentOutageStatus.flagGasOnly
        accountContentView.isHidden = currentOutageStatus.flagGasOnly
        
        // Display either the Lottie animation or draw our own border circles
        let powerIsOn = !currentOutageStatus.activeOutage && viewModel.getReportedOutage() == nil && !currentOutageStatus.flagNoPay && !currentOutageStatus.flagFinaled
        animationView.isHidden = !powerIsOn
        outerCircleView.isHidden = powerIsOn
        innerCircleView.isHidden = powerIsOn
        
        if viewModel.getReportedOutage() == nil && (currentOutageStatus.activeOutage || currentOutageStatus.flagNoPay || currentOutageStatus.flagFinaled) {
            outerCircleView.backgroundColor = UIColor(red: 187/255, green: 187/255, blue: 187/255, alpha: 1)
            innerCircleView.backgroundColor = .oldLavender
        } else {
            outerCircleView.backgroundColor = UIColor.primaryColor.withAlphaComponent(0.7)
            innerCircleView.backgroundColor = .primaryColor
        }
        
        // Update the Report Outage button
        if viewModel.getReportedOutage() != nil {
            reportOutageButton.setDetailLabel(text: viewModel.getOutageReportedDateString(), checkHidden: false)
        } else {
            reportOutageButton.setDetailLabel(text: "", checkHidden: true)
        }
        
        // Disable bottom buttons if account is finaled or not paid
        let bottomButtonsEnabled = !currentOutageStatus.flagNoPay && !currentOutageStatus.flagFinaled
        reportOutageButton.isEnabled = bottomButtonsEnabled
        viewOutageMapButton.isEnabled = bottomButtonsEnabled
    }
    
    func layoutBigButtonContent() {
        for subview in bigButtonView.subviews {
            subview.removeFromSuperview()
        }
        
        let currentOutageStatus = viewModel.currentOutageStatus!
        let bigButtonWidth = bigButtonView.frame.size.width
        
        if viewModel.getReportedOutage() != nil {
            let icon = UIImageView(frame: CGRect(x: bigButtonWidth / 2 - 13.5, y: 28, width: 27, height: 29))
            icon.image = #imageLiteral(resourceName: "ic_outagestatus_reported")
            
            let yourOutageIsLabel = UILabel(frame: CGRect(x: 30, y: 61, width: bigButtonWidth - 60, height: 20))
            yourOutageIsLabel.font = UIFont(name: "OpenSans", size: 16)
            yourOutageIsLabel.textColor = .mediumPersianBlue
            yourOutageIsLabel.textAlignment = .center
            yourOutageIsLabel.text = "Your outage is"
            
            let reportedLabel = UILabel(frame: CGRect(x: 30, y: 81, width: bigButtonWidth - 60, height: 25))
            reportedLabel.font = UIFont(name: "OpenSans-Bold", size: 22)
            reportedLabel.textColor = .mediumPersianBlue
            reportedLabel.textAlignment = .center
            reportedLabel.text = "REPORTED"
            
            let estRestorationLabel = UILabel(frame: CGRect(x: 30, y: 117, width: bigButtonWidth - 60, height: 14))
            estRestorationLabel.font = UIFont(name: "OpenSans", size: 12)
            estRestorationLabel.textColor = .outerSpace
            estRestorationLabel.textAlignment = .center
            estRestorationLabel.text = "Estimated Restoration"
            
            let timeLabel = UILabel(frame: CGRect(x: 22, y: 134, width: bigButtonWidth - 44, height: 20))
            timeLabel.font = UIFont(name: "OpenSans-Bold", size: 15)
            timeLabel.textColor = .outerSpace
            timeLabel.textAlignment = .center
            timeLabel.adjustsFontSizeToFitWidth = true
            timeLabel.minimumScaleFactor = 0.5
            timeLabel.text = viewModel.getEstimatedRestorationDateString()
            
            bigButtonView.addSubview(icon)
            bigButtonView.addSubview(yourOutageIsLabel)
            bigButtonView.addSubview(reportedLabel)
            bigButtonView.addSubview(estRestorationLabel)
            bigButtonView.addSubview(timeLabel)
        } else if currentOutageStatus.activeOutage {
            let icon = UIImageView(frame: CGRect(x: bigButtonWidth / 2 - 11, y: 31, width: 22, height: 28))
            icon.image = #imageLiteral(resourceName: "ic_outagestatus_out")
            
            let yourPowerIsLabel = UILabel(frame: CGRect(x: 30, y: 62, width: bigButtonWidth - 60, height: 20))
            yourPowerIsLabel.font = UIFont(name: "OpenSans", size: 16)
            yourPowerIsLabel.textColor = .mediumPersianBlue
            yourPowerIsLabel.textAlignment = .center
            yourPowerIsLabel.text = "Your power is"
            
            let outLabel = UILabel(frame: CGRect(x: 44, y: 82, width: bigButtonWidth - 88, height: 25))
            outLabel.font = UIFont(name: "OpenSans-Bold", size: 22)
            outLabel.textColor = .mediumPersianBlue
            outLabel.textAlignment = .center
            outLabel.text = "OUT"
            
            let estRestorationLabel = UILabel(frame: CGRect(x: 30, y: 117, width: bigButtonWidth - 60, height: 14))
            estRestorationLabel.font = UIFont(name: "OpenSans", size: 12)
            estRestorationLabel.textColor = .outerSpace
            estRestorationLabel.textAlignment = .center
            estRestorationLabel.text = "Estimated Restoration"
            
            let timeLabel = UILabel(frame: CGRect(x: 22, y: 134, width: bigButtonWidth - 44, height: 20))
            timeLabel.font = UIFont(name: "OpenSans-Bold", size: 15)
            timeLabel.textColor = .outerSpace
            timeLabel.textAlignment = .center
            timeLabel.adjustsFontSizeToFitWidth = true
            timeLabel.minimumScaleFactor = 0.5
            timeLabel.text = viewModel.getEstimatedRestorationDateString()
            
            bigButtonView.addSubview(icon)
            bigButtonView.addSubview(yourPowerIsLabel)
            bigButtonView.addSubview(outLabel)
            bigButtonView.addSubview(estRestorationLabel)
            bigButtonView.addSubview(timeLabel)
        } else if currentOutageStatus.flagFinaled || currentOutageStatus.flagNoPay {
            let nonPayFinaledTextView = DataDetectorTextView(frame: CGRect(x: 14, y: 38, width: bigButtonWidth - 28, height: 120))
            let payBillLabel = UILabel(frame: .zero)
            if Environment.sharedInstance.opco != "BGE" {
                if currentOutageStatus.flagFinaled {
                    nonPayFinaledTextView.frame = CGRect(x: 14, y: 68, width: bigButtonWidth - 28, height: 84)
                } else { // accountPaid = false
                    payBillLabel.frame = CGRect(x: 23, y: 150, width: bigButtonWidth - 46, height: 19)
                    payBillLabel.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightSemibold)
                    payBillLabel.textColor = .mediumPersianBlue
                    payBillLabel.textAlignment = .center
                    payBillLabel.text = "Pay Bill"
                    bigButtonView.addSubview(payBillLabel)
                }
            }
            nonPayFinaledTextView.textContainerInset = .zero
            nonPayFinaledTextView.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightLight)
            nonPayFinaledTextView.tintColor = .mediumPersianBlue // For the phone numbers
            nonPayFinaledTextView.textColor = .oldLavender
            nonPayFinaledTextView.textAlignment = .center
            nonPayFinaledTextView.text = viewModel.getAccountNonPayFinaledMessage()

            bigButtonView.addSubview(nonPayFinaledTextView)
            bigButtonView.bringSubview(toFront: payBillLabel)
        } else { // Power is on
            let icon = UIImageView(frame: CGRect(x: bigButtonWidth / 2 - 15, y: 49, width: 30, height: 38))
            icon.image = #imageLiteral(resourceName: "ic_outagestatus_on")
            
            let yourPowerIsLabel = UILabel(frame: CGRect(x: 40, y: 89, width: bigButtonWidth - 80, height: 20))
            yourPowerIsLabel.font = UIFont(name: "OpenSans", size: 16)
            yourPowerIsLabel.textColor = .mediumPersianBlue
            yourPowerIsLabel.textAlignment = .center
            yourPowerIsLabel.text = "Your power is"
            
            let onLabel = UILabel(frame: CGRect(x: 40, y: 109, width: bigButtonWidth - 80, height: 25))
            onLabel.font = UIFont(name: "OpenSans-Bold", size: 22)
            onLabel.textColor = .mediumPersianBlue
            onLabel.textAlignment = .center
            onLabel.text = "ON"
            
            bigButtonView.addSubview(icon)
            bigButtonView.addSubview(yourPowerIsLabel)
            bigButtonView.addSubview(onLabel)
        }
    }
    
    func getOutageStatus() {
        accountContentView.isHidden = true
        gasOnlyView.isHidden = true
        errorLabel.isHidden = true
        outageStatusActivityIndicator.isHidden = false
        
        viewModel.getOutageStatus(forAccount: viewModel.currentAccount!, onSuccess: { _ in
            self.outageStatusActivityIndicator.isHidden = true
            self.updateContent()
        }, onError: { error in
            self.outageStatusActivityIndicator.isHidden = true
            self.errorLabel.text = error
            self.errorLabel.isHidden = false
        })
    }
    
    // MARK: - Actions
    
    func onBigButtonTap() {
        if viewModel.currentOutageStatus!.flagNoPay && Environment.sharedInstance.opco != "BGE"  {
            // TEMPORARILY DISABLED
            //tabBarController?.selectedIndex = 1 // Jump to Bill tab
        } else {
            let message = viewModel.currentOutageStatus!.outageDescription
            if message.characters.count > 0 {
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func onPullToRefresh() {
        viewModel.getOutageStatus(forAccount: viewModel.currentAccount!, onSuccess: { outageStatus in
            self.refreshControl.endRefreshing()
            self.updateContent()
        }, onError: { error in
            self.refreshControl.endRefreshing()
            self.errorLabel.text = error
            self.errorLabel.isHidden = false
        })
    }
    
    @IBAction func onReportOutagePress() {
        performSegue(withIdentifier: "reportOutageSegue", sender: self)
    }
    
    @IBAction func onViewOutageMapPress() {
        print("View Outage Map")
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination.isKind(of: ReportOutageViewController.self) {
            let vc = segue.destination as! ReportOutageViewController
            vc.viewModel.account = viewModel.currentAccount!
            vc.viewModel.outageStatus = viewModel.currentOutageStatus!
            vc.viewModel.phoneNumber.value = viewModel.currentOutageStatus!.contactHomeNumber
            vc.delegate = self
        }
    }
 
}

extension OutageViewController: AccountScrollerDelegate {
    
    func accountScroller(_ accountScroller: AccountScroller, didChangeAccount account: Account) {
        viewModel.currentAccount = account
        
        getOutageStatus()
    }
    
}

extension OutageViewController: ReportOutageViewControllerDelegate {
    
    func reportOutageViewControllerDidReportOutage(_ reportOutageViewController: ReportOutageViewController) {
        self.updateContent()
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.makeToast("Your outage report has been received.", duration: 3.0, position: CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height - 40))
        })
    }
    
}
