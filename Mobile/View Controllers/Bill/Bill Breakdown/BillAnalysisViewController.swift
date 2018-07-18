//
//  BillAnalysisViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 10/4/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Charts

class BillBreakdownViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    // Current Charges Summary
    @IBOutlet weak var currentChargesPieChartView: PieChartView!
    
    @IBOutlet weak var currentChargesLegendView: UIView!
    @IBOutlet weak var supplyLegendBox: UIView!
    @IBOutlet weak var supplyLegendLabel: UILabel!
    @IBOutlet weak var supplyValueLabel: UILabel!
    @IBOutlet weak var taxesFeesLegendBox: UIView!
    @IBOutlet weak var taxesFeesLegendLabel: UILabel!
    @IBOutlet weak var taxesFeesValueLabel: UILabel!
    @IBOutlet weak var deliveryLegendBox: UIView!
    @IBOutlet weak var deliveryLegendLabel: UILabel!
    @IBOutlet weak var deliveryValueLabel: UILabel!
    @IBOutlet weak var totalChargesLegendBox: UIView!
    @IBOutlet weak var totalChargesLegendLabel: UILabel!
    @IBOutlet weak var totalChargesValueLabel: UILabel!
    
    let viewModel: BillAnalysisViewModel
    
    private let corderRadius: CGFloat = 10.0
    
    init(accountDetail: AccountDetail) {
        viewModel = BillAnalysisViewModel(accountDetail: accountDetail)
        super.init(nibName: BillBreakdownViewController.className, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let residentialAMIString = String(format: "%@%@", viewModel.accountDetail.isResidential ? "Residential/" : "Commercial/", viewModel.accountDetail.isAMIAccount ? "AMI" : "Non-AMI")
        Analytics.log(event: .billNeedHelp,
                             dimensions: [.residentialAMI: residentialAMIString])
        
        title = NSLocalizedString("Bill Breakdown", comment: "")
        
        styleViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        }
    }
    
    private func styleViews() {
        scrollView.backgroundColor = .softGray
        styleCurrentChargesSection()
    }
    
    private func styleCurrentChargesSection() {
        let supplyCharges = viewModel.supplyCharges
        let taxesAndFees = viewModel.taxesAndFees
        let deliveryCharges = viewModel.deliveryCharges
        
        // Pie Chart
        currentChargesPieChartView.highlightPerTapEnabled = false
        currentChargesPieChartView.rotationEnabled = false
        currentChargesPieChartView.legend.enabled = false // Hide the legend because we'll draw our own
        currentChargesPieChartView.chartDescription?.enabled = false // Hides the chart description
        currentChargesPieChartView.holeColor = .clear
        currentChargesPieChartView.holeRadiusPercent = 0.66
        currentChargesPieChartView.transparentCircleRadiusPercent = 0.70
        currentChargesPieChartView.transparentCircleColor = .clear
        
        let centerAttrText = NSMutableAttributedString(string: viewModel.totalChargesString)
        centerAttrText.addAttribute(.foregroundColor, value: UIColor.deepGray, range: NSRange(location: 0, length: centerAttrText.length))
        centerAttrText.addAttribute(.font, value: OpenSans.semibold.of(size: 24), range: NSRange(location: 0, length: centerAttrText.length))
        currentChargesPieChartView.centerAttributedText = centerAttrText
        
        currentChargesPieChartView.accessibilityLabel = viewModel.totalChargesString
        
        var pieChartValues = [PieChartDataEntry]()
        var pieChartColors = [UIColor]()
        if supplyCharges > 0 {
            pieChartValues.append(PieChartDataEntry(value: supplyCharges))
            pieChartColors.append(.primaryColor)
        }
        if taxesAndFees > 0 {
            pieChartValues.append(PieChartDataEntry(value: taxesAndFees))
            pieChartColors.append(.blackText)
        }
        if deliveryCharges > 0 {
            pieChartValues.append(PieChartDataEntry(value: deliveryCharges))
            pieChartColors.append(.accentGray)
        }

        let dataSet = PieChartDataSet(values: pieChartValues, label: "Current Charges")
        dataSet.colors = pieChartColors
        dataSet.drawValuesEnabled = false
        dataSet.sliceSpace = UIScreen.main.scale * 2
        let data = PieChartData(dataSet: dataSet)
        currentChargesPieChartView.data = data
        currentChargesPieChartView.notifyDataSetChanged()
        
        // Legend View
        currentChargesLegendView.addShadow(color: .black, opacity: 0.08, offset: .zero, radius: 2)
        
        supplyLegendBox.backgroundColor = .accentGray
        supplyLegendLabel.textColor = .blackText
        supplyLegendLabel.font = OpenSans.semibold.of(textStyle: .headline)
        supplyLegendLabel.text = NSLocalizedString("Supply", comment: "")
        supplyValueLabel.textColor = .blackText
        supplyValueLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        supplyValueLabel.text = supplyCharges.currencyString
        
        taxesFeesLegendBox.backgroundColor = .blackText
        taxesFeesLegendLabel.textColor = .blackText
        taxesFeesLegendLabel.font = OpenSans.semibold.of(textStyle: .headline)
        taxesFeesLegendLabel.text = NSLocalizedString("Taxes & Fees", comment: "")
        taxesFeesValueLabel.textColor = .blackText
        taxesFeesValueLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        taxesFeesValueLabel.text = taxesAndFees.currencyString
        
        deliveryLegendBox.backgroundColor = .primaryColor
        deliveryLegendLabel.textColor = .blackText
        deliveryLegendLabel.font = OpenSans.semibold.of(textStyle: .headline)
        deliveryLegendLabel.text = NSLocalizedString("Delivery", comment: "")
        deliveryValueLabel.textColor = .blackText
        deliveryValueLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        deliveryValueLabel.text = deliveryCharges.currencyString
        
        totalChargesLegendLabel.textColor = .deepGray
        totalChargesLegendLabel.font = OpenSans.bold.of(textStyle: .headline)
        totalChargesLegendLabel.text = NSLocalizedString("TOTAL CHARGES", comment: "")
        totalChargesValueLabel.textColor = .deepGray
        totalChargesValueLabel.font = OpenSans.bold.of(textStyle: .subheadline)
        totalChargesValueLabel.text = viewModel.totalChargesString
    }
    
}
