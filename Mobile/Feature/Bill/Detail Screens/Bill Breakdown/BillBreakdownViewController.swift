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
    
    @IBOutlet private weak var totalChargesValueLabel: UILabel!
    @IBOutlet private weak var totalChargesTextLabel: UILabel!
    
    @IBOutlet private weak var currentChargesLegendView: UIView!
    
    @IBOutlet private weak var supplyLegendCircle: UIView!
    @IBOutlet private weak var supplyLegendLabel: UILabel!
    @IBOutlet private weak var supplyValueLabel: UILabel!
    
    @IBOutlet private weak var taxesFeesLegendCircle: UIView!
    @IBOutlet private weak var taxesFeesLegendLabel: UILabel!
    @IBOutlet private weak var taxesFeesValueLabel: UILabel!
    
    @IBOutlet private weak var deliveryLegendCircle: UIView!
    @IBOutlet private weak var deliveryLegendLabel: UILabel!
    @IBOutlet private weak var deliveryValueLabel: UILabel!
    
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
        
        extendedLayoutIncludesOpaqueBars = true

        let residentialAMIString = String(format: "%@%@", viewModel.accountDetail.isResidential ? "Residential/" : "Commercial/", viewModel.accountDetail.isAMIAccount ? "AMI" : "Non-AMI")
        GoogleAnalytics.log(event: .billNeedHelp,
                             dimensions: [.residentialAMI: residentialAMIString])
        
        title = NSLocalizedString("Bill Breakdown", comment: "")
        
        styleViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
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
        currentChargesPieChartView.holeRadiusPercent = 0.58
        currentChargesPieChartView.transparentCircleColor = .clear
        
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
        totalChargesValueLabel.textColor = .deepGray
        totalChargesValueLabel.font = OpenSans.semibold.of(textStyle: .title1)
        totalChargesValueLabel.text = viewModel.totalChargesString
        totalChargesTextLabel.textColor = .deepGray
        totalChargesTextLabel.font = SystemFont.regular.of(textStyle: .caption1)
        totalChargesTextLabel.text = NSLocalizedString("Total Charges", comment: "")
        
        currentChargesLegendView.layer.borderColor = UIColor.accentGray.cgColor
        currentChargesLegendView.layer.borderWidth = 1
        
        supplyLegendCircle.layer.cornerRadius = 7.5
        supplyLegendCircle.backgroundColor = .accentGray
        supplyLegendLabel.textColor = .deepGray
        supplyLegendLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        supplyLegendLabel.text = NSLocalizedString("Supply", comment: "")
        supplyValueLabel.textColor = .deepGray
        supplyValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        supplyValueLabel.text = viewModel.supplyCharges.currencyString
        
        taxesFeesLegendCircle.layer.cornerRadius = 7.5
        taxesFeesLegendCircle.backgroundColor = .blackText
        taxesFeesLegendLabel.textColor = .deepGray
        taxesFeesLegendLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        taxesFeesLegendLabel.text = NSLocalizedString("Taxes & Fees", comment: "")
        taxesFeesValueLabel.textColor = .deepGray
        taxesFeesValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        taxesFeesValueLabel.text = viewModel.taxesAndFees.currencyString
        
        deliveryLegendCircle.layer.cornerRadius = 7.5
        deliveryLegendCircle.backgroundColor = .primaryColor
        deliveryLegendLabel.textColor = .deepGray
        deliveryLegendLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        deliveryLegendLabel.text = NSLocalizedString("Delivery", comment: "")
        deliveryValueLabel.textColor = .deepGray
        deliveryValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        deliveryValueLabel.text = viewModel.deliveryCharges.currencyString
    }

}
