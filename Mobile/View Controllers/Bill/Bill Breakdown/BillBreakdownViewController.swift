//
//  BillBreakdownViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 10/4/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Charts

class BillBreakdownViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet private weak var currentChargesPieChartView: PieChartView!
    
    @IBOutlet private weak var currentChargesLegendView: UIView!
    
    @IBOutlet private weak var supplyLegendBox: UIView!
    @IBOutlet private weak var supplyLegendLabel: UILabel!
    @IBOutlet private weak var supplyValueLabel: UILabel!
    
    @IBOutlet private weak var taxesFeesLegendBox: UIView!
    @IBOutlet private weak var taxesFeesLegendLabel: UILabel!
    @IBOutlet private weak var taxesFeesValueLabel: UILabel!
    
    @IBOutlet private weak var deliveryLegendBox: UIView!
    @IBOutlet private weak var deliveryLegendLabel: UILabel!
    @IBOutlet private weak var deliveryValueLabel: UILabel!
    
    @IBOutlet private weak var totalChargesLegendLabel: UILabel!
    @IBOutlet private weak var totalChargesValueLabel: UILabel!
    
    // MARK: - Properties
    
    private let viewModel: BillBreakdownViewModel
    
    // MARK: - Init
    
    init(accountDetail: AccountDetail) {
        viewModel = BillBreakdownViewModel(accountDetail: accountDetail)
        super.init(nibName: BillBreakdownViewController.className, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let residentialAMIString = String(format: "%@%@", viewModel.accountDetail.isResidential ? "Residential/" : "Commercial/", viewModel.accountDetail.isAMIAccount ? "AMI" : "Non-AMI")
        Analytics.log(event: .billNeedHelp,
                             dimensions: [.residentialAMI: residentialAMIString])
        
        title = NSLocalizedString("Bill Breakdown", comment: "")
        
        styleViews()
    }

    // MARK: - Style Views
    
    private func styleViews() {
        stylePieChart()
        styleLegend()
    }
    
    private func stylePieChart() {
        currentChargesPieChartView.highlightPerTapEnabled = false // Disable chart interaction
        currentChargesPieChartView.rotationEnabled = false // Disable chart interaction
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
        if viewModel.deliveryCharges > 0 {
            pieChartValues.append(PieChartDataEntry(value: viewModel.deliveryCharges))
            pieChartColors.append(.primaryColor)
        }
        if viewModel.taxesAndFees > 0 {
            pieChartValues.append(PieChartDataEntry(value: viewModel.taxesAndFees))
            pieChartColors.append(.blackText)
        }
        if viewModel.supplyCharges > 0 {
            pieChartValues.append(PieChartDataEntry(value: viewModel.supplyCharges))
            pieChartColors.append(.accentGray)
        }
        
        let dataSet = PieChartDataSet(entries: pieChartValues, label: "Current Charges")
        dataSet.colors = pieChartColors
        dataSet.drawValuesEnabled = false
        dataSet.sliceSpace = UIScreen.main.scale * 2
        let data = PieChartData(dataSet: dataSet)
        currentChargesPieChartView.data = data
        currentChargesPieChartView.notifyDataSetChanged()
    }
    
    private func styleLegend() {
        currentChargesLegendView.addShadow(color: .black, opacity: 0.08, offset: .zero, radius: 2)
        
        supplyLegendBox.backgroundColor = .accentGray
        supplyLegendLabel.textColor = .blackText
        supplyLegendLabel.font = OpenSans.semibold.of(textStyle: .headline)
        supplyLegendLabel.text = NSLocalizedString("Supply", comment: "")
        supplyValueLabel.textColor = .blackText
        supplyValueLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        supplyValueLabel.text = viewModel.supplyCharges.currencyString
        
        taxesFeesLegendBox.backgroundColor = .blackText
        taxesFeesLegendLabel.textColor = .blackText
        taxesFeesLegendLabel.font = OpenSans.semibold.of(textStyle: .headline)
        taxesFeesLegendLabel.text = NSLocalizedString("Taxes & Fees", comment: "")
        taxesFeesValueLabel.textColor = .blackText
        taxesFeesValueLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        taxesFeesValueLabel.text = viewModel.taxesAndFees.currencyString
        
        deliveryLegendBox.backgroundColor = .primaryColor
        deliveryLegendLabel.textColor = .blackText
        deliveryLegendLabel.font = OpenSans.semibold.of(textStyle: .headline)
        deliveryLegendLabel.text = NSLocalizedString("Delivery", comment: "")
        deliveryValueLabel.textColor = .blackText
        deliveryValueLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        deliveryValueLabel.text = viewModel.deliveryCharges.currencyString
        
        totalChargesLegendLabel.textColor = .deepGray
        totalChargesLegendLabel.font = OpenSans.bold.of(textStyle: .headline)
        totalChargesLegendLabel.text = NSLocalizedString("TOTAL CHARGES", comment: "")
        totalChargesValueLabel.textColor = .deepGray
        totalChargesValueLabel.font = OpenSans.bold.of(textStyle: .subheadline)
        totalChargesValueLabel.text = viewModel.totalChargesString
    }
    
    // MARK: - Actions
    
    @IBAction private func viewUsageButtonPressed(_ sender: Any) {
        navigationController?.tabBarController?.selectedIndex = 3
        navigationController?.popToRootViewController(animated: false)
    }
}
