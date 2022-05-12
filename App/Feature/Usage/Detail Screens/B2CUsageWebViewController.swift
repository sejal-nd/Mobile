//
//  B2CUsageWebViewController.swift
//  Mobile
//
//  Created by Joseph Erlandson on 8/6/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit
import WebKit
import RxSwift

class B2CUsageWebViewController: UIViewController {
    
    enum WidgetName: String, CaseIterable {
        // residential
        case usage = "data-browser"
        case ser, pesc = "peak-time-rebate"
        
        // commercial
        case electricUsage = "electric-usage-chart-interval"
        case gasUsage = "gas-usage-chart-bill"
        case compareElectric = "electric-monthly-cost-chart-bill-type"
        case compareGas = "gas-monthly-cost-chart-bill-type"
        case electricTips = "electric-solutions"
        case gasTips = "gas-solutions"
        case projectedUsage = "projected_usage"
        
        var navigationTitle: String {
            switch self {
            case .usage:
                return "Usage Data"
            case .ser:
                return "Smart Energy Rewards"
            case .pesc:
                return "Peak Energy Savings History"
            case .electricUsage:
                return "My Electric Usage"
            case.gasUsage:
                return "My Gas Usage"
            case .compareElectric:
                return "Compare Electric Bills"
            case .compareGas:
                return "Compare Gas Bills"
            case .electricTips:
                return "View My Tips (Electric Only)"
            case .gasTips:
                return "View My Tips (Gas Only)"
            case.projectedUsage:
                return "Projected Usage"
            }
        }
        
        var identifier: String {
            switch self {
            case .usage:
                return "data-browser"
            case .ser, .pesc:
                return "peak-time-rebate"
            case .electricUsage:
                return Configuration.shared.opco == .ace ? "electric-usage-chart-bill" : "electric-usage-chart-interval"
            case .gasUsage:
                return "gas-usage-chart-bill"
            case .compareElectric:
                return "electric-monthly-cost-chart-bill-type"
            case .compareGas:
                return "gas-monthly-cost-chart-bill-type"
            case .electricTips:
                return "electric-solutions"
            case.gasTips:
                return "gas_solutions"
            case .projectedUsage:
                return "projected_usage"
            }
        }
        
        static var commercialWidgets: [WidgetName] = [.usage, .electricUsage, .gasUsage, .compareElectric, .compareGas, .electricTips, .gasTips, .projectedUsage]
    }
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorImage: UIImageView!
    @IBOutlet weak var errorTitle: UILabel!
    @IBOutlet weak var errorDescription: UILabel!
    
    @IBOutlet weak var tabCollectionView: UICollectionView!
    @IBOutlet weak var separatorView: UIView!
    
    var accountDetail: AccountDetail?
    var accessToken: String?
    var widget: WidgetName = .usage
    
    let viewModel = B2CCommercialUsageViewModel()
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString(widget.navigationTitle, comment: "")
                
        webView.navigationDelegate = self
        webView.isHidden = true
        
        errorImage.tintColor = .attentionOrange
        errorTitle.font = SystemFont.semibold.of(textStyle: .title3)
        errorTitle.textColor = .deepGray
        errorDescription.font = SystemFont.regular.of(textStyle: .footnote)
        errorDescription.textColor = .deepGray
        errorView.isHidden = true

        if accountDetail?.isResidential == false {
            showCommercialView()
        }
        
        fetchJWT()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !(parent is UsageViewController) {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    
    private func showCommercialView() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 32, bottom: 0, right: 32)
        flowLayout.estimatedItemSize = CGSize(width: 1, height: 50)
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        
        tabCollectionView.collectionViewLayout = flowLayout
        tabCollectionView.backgroundColor = .white
        tabCollectionView.showsVerticalScrollIndicator = false
        tabCollectionView.showsHorizontalScrollIndicator = false
        tabCollectionView.register(UINib(nibName: TabCollectionViewCell.className, bundle: nil),
                                forCellWithReuseIdentifier: TabCollectionViewCell.className)
        
        tabCollectionView.isHidden = false
        separatorView.isHidden = false
        
        self.widget = .usage
        viewModel.selectedIndex.asDriver()
            .drive(onNext: { [weak self] selectedIndex in
                guard let self = self else { return }
                
                self.widget = self.viewModel.selectedWidget()
                self.loadWebView()
            })
            .disposed(by: disposeBag)
        
        bindTabs()
    }
    
    private func bindTabs() {
        tabCollectionView.rx.itemSelected
            .map(\.item)
            .bind(to: viewModel.selectedIndex)
            .disposed(by: disposeBag)
        
        viewModel.tabs
            .bind(to: tabCollectionView.rx.items(cellIdentifier: TabCollectionViewCell.className,
                                                 cellType: TabCollectionViewCell.self))
            { [weak self] (row, tab, cell) in
                guard let self = self else { return }
                let isSelected = self.viewModel.selectedIndex.asDriver()
                    .distinctUntilChanged()
                    .map { $0 == row }
                
                cell.configure(title: tab.navigationTitle, isSelected: isSelected)
            }
            .disposed(by: disposeBag)
        
        viewModel.selectedIndex.asDriver()
            .drive(onNext: { [weak self] selectedIndex in
                self?.tabCollectionView.scrollToItem(at: IndexPath(item: selectedIndex, section: 0),
                                                     at: .centeredHorizontally,
                                                     animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func fetchJWT() {
        let accountNumber = accountDetail?.accountNumber ?? ""
        var nonce = accountNumber
        
        if accountDetail?.isResidential == false {
            nonce = "NR-\(accountNumber)"
        }
        let request = B2CTokenRequest(scope: "https://\(Configuration.shared.b2cTenant).onmicrosoft.com/opower/opower_connect",
                                   nonce: nonce,
                                   grantType: "refresh_token",
                                   responseType: "token",
                                   refreshToken: UserSession.refreshToken)
        UsageService.fetchOpowerToken(request: request) { [weak self] result in
            switch result {
            case .success(let tokenResponse):
                guard let self = self else { return }
                self.errorView.isHidden = true
                self.accessToken = tokenResponse.token ?? ""

                self.loadWebView()
            case .failure:
                guard let self = self else { return }
                self.errorView.isHidden = false
                self.loadingIndicator.isHidden = true
            }
        }
    }
    
    func loadWebView() {
        guard let token = accessToken,
        !token.isEmpty else {
            self.fetchJWT()
            return
        }
        
        let oPowerWidgetURL = Configuration.shared.getSecureOpCoOpowerURLString(accountDetail?.opcoType ?? Configuration.shared.opco)
        if let url = URL(string: oPowerWidgetURL) {
            var request = NSURLRequest(url: url) as URLRequest
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue(token, forHTTPHeaderField: "accessToken")
            request.addValue(accountDetail?.accountNumber ?? "", forHTTPHeaderField: "accountNumber")
            request.addValue(widget.identifier, forHTTPHeaderField: "opowerWidgetId")
            request.addValue(accountDetail?.utilityCode ?? Configuration.shared.opco.rawValue, forHTTPHeaderField: "opco")
            request.addValue(accountDetail?.state ?? "MD", forHTTPHeaderField: "state")
            request.addValue("\(accountDetail?.isResidential == false)", forHTTPHeaderField: "isCommercial")
            webView.load(request)
        }
    }
}

extension B2CUsageWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.isHidden = true
        webView.isHidden = false
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        errorView.isHidden = false
        loadingIndicator.isHidden = true
        webView.isHidden = true
        Log.error("Error loading usage web view: \(error)\n\(error.localizedDescription)")
    }
}
