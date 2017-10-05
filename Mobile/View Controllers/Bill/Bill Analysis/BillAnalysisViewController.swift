//
//  BillAnalysisViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 10/4/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class BillAnalysisViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var stackViewWidthConstraint: NSLayoutConstraint! // So that we can design every bar in IB but set it to 460 in viewDidLoad
    
    @IBOutlet weak var electricGasSegmentView: UIView!
    @IBOutlet weak var electricGasSegmentedControl: SegmentedControl!
    
    @IBOutlet weak var billComparisonSegmentedControl: BillAnalysisSegmentedControl!
    
    @IBOutlet weak var noDataContainerButton: ButtonControl!
    @IBOutlet weak var noDataBarView: UIView!
    @IBOutlet weak var noDataLabel: UILabel!
    @IBOutlet weak var noDataDateLabel: UILabel!

    @IBOutlet weak var previousContainerButton: ButtonControl!
    @IBOutlet weak var previousDollarLabel: UILabel!
    @IBOutlet weak var previousBarView: UIView!
    @IBOutlet weak var previousDateLabel: UILabel!
    
    @IBOutlet weak var currentContainerButton: ButtonControl!
    @IBOutlet weak var currentDollarLabel: UILabel!
    @IBOutlet weak var currentBarView: UIView!
    @IBOutlet weak var currentDateLabel: UILabel!
    
    @IBOutlet weak var projectedContainerButton: ButtonControl!
    @IBOutlet weak var projectedDollarLabel: UILabel!
    @IBOutlet weak var projectedBarImage: UIImageView!
    @IBOutlet weak var projectedDateLabel: UILabel!
    
    @IBOutlet weak var projectionNotAvailableContainerButton: ButtonControl!
    @IBOutlet weak var projectionNotAvailableBarView: UIView!
    @IBOutlet weak var projectionNotAvailableDaysRemainingLabel: UILabel!
    @IBOutlet weak var projectionNotAvailableUntilNextForecastLabel: UILabel!
    @IBOutlet weak var projectionNotAvailableDateLabel: UILabel!
    
    @IBOutlet weak var barDescriptionView: UIView!
    @IBOutlet weak var barDescriptionDateLabel: UILabel!
    @IBOutlet weak var barDescriptionDetailLabel: UILabel!
    @IBOutlet weak var barDescriptionTriangleCenterXConstraint: NSLayoutConstraint!
    
    
    init() {
        super.init(nibName: BillAnalysisViewController.className, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Bill Analysis", comment: "")
        
        billComparisonSegmentedControl.setItems(leftLabel: NSLocalizedString("Last Year", comment: ""), rightLabel: NSLocalizedString("Previous Bill", comment: ""), initialSelectedIndex: 1)
        
        styleViews()
        
        previousContainerButton.isHidden = true
        currentContainerButton.isHidden = true
        //projectionNotAvailableContainerButton.isHidden = true
        stackViewWidthConstraint.constant = 460
        
        if UIScreen.main.bounds.size.width < 375 { // If smaller than iPhone 6 width
            stackView.spacing = 11
        }
        
        stackView.layoutIfNeeded() // Needed for the initial selection triangle position
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        }
        
        onBarPress(sender: projectedContainerButton) // Initial selection
        
    }
    
    func styleViews() {
        scrollView.backgroundColor = .softGray
        
        electricGasSegmentedControl.items = [NSLocalizedString("Electric", comment: ""), NSLocalizedString("Gas", comment: "")]
        
        noDataBarView.addDashedBorder(color: UIColor(red: 0, green: 80/255, blue: 125/255, alpha: 0.24))
        projectionNotAvailableBarView.addDashedBorder(color: UIColor(red: 0, green: 80/255, blue: 125/255, alpha: 0.24))
        
        switch Environment.sharedInstance.opco {
        case .bge:
            projectedBarImage.tintColor = UIColor(red: 0, green: 110/255, blue: 187/255, alpha: 1)
        case .comEd:
            projectedBarImage.tintColor = UIColor(red: 0, green: 145/255, blue: 182/255, alpha: 1)
        case .peco:
            projectedBarImage.tintColor = UIColor(red: 114/255, green: 184/255, blue: 101/255, alpha: 1)
        }
        
        barDescriptionView.addShadow(color: .black, opacity: 0.08, offset: .zero, radius: 2)
        barDescriptionDateLabel.font = OpenSans.semibold.of(textStyle: .subheadline)
        barDescriptionDateLabel.textColor = .blackText
        barDescriptionDetailLabel.font = OpenSans.regular.of(textStyle: .footnote)
        barDescriptionDetailLabel.textColor = .blackText
    }
    
    @IBAction func onBarPress(sender: ButtonControl) {
        let centerPoint = sender.center
        let convertedPoint = stackView.convert(centerPoint, to: barDescriptionView)

        let centerXOffset = (barDescriptionView.bounds.width / 2)
        if convertedPoint.x < centerXOffset {
            barDescriptionTriangleCenterXConstraint.constant = -1 * (centerXOffset - convertedPoint.x)
        } else if convertedPoint.x > centerXOffset {
            barDescriptionTriangleCenterXConstraint.constant = convertedPoint.x - centerXOffset
        } else {
            barDescriptionTriangleCenterXConstraint.constant = 0
        }
    }
    
    
    
    



}
