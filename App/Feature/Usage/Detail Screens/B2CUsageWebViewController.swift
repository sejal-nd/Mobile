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
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorImage: UIImageView!
    @IBOutlet weak var errorTitle: UILabel!
    @IBOutlet weak var errorDescription: UILabel!
    
    @IBOutlet weak var tabCollectionView: UICollectionView!
    @IBOutlet weak var separatorView: UIView!
    
    let viewModel = B2CUsageViewModel()
    let disposeBag = DisposeBag()
     
    var accountDetail: AccountDetail? {
        get {
            return viewModel.accountDetail
        }
        set {
            viewModel.accountDetail = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString(viewModel.widget.navigationTitle, comment: "")
                
        webView.navigationDelegate = self
        webView.isHidden = true
        
        errorImage.tintColor = .attentionOrange
        errorTitle.font = SystemFont.semibold.of(textStyle: .title3)
        errorTitle.textColor = .deepGray
        errorDescription.font = SystemFont.regular.of(textStyle: .footnote)
        errorDescription.textColor = .deepGray
        errorView.isHidden = true

        if viewModel.accountDetail?.isResidential == false {
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
        
        self.viewModel.widget = .usage
        viewModel.selectedCommercialIndex.asDriver()
            .drive(onNext: { [weak self] selectedIndex in
                guard let self = self else { return }
                
                self.viewModel.widget = self.viewModel.selectedCommercialWidget()
                self.loadWebView()
            })
            .disposed(by: disposeBag)
        
        bindTabs()
    }
    
    private func bindTabs() {
        tabCollectionView.rx.itemSelected
            .map(\.item)
            .bind(to: viewModel.selectedCommercialIndex)
            .disposed(by: disposeBag)
        
        Observable.just(viewModel.commercialWidgets)
            .bind(to: tabCollectionView.rx.items(cellIdentifier: TabCollectionViewCell.className,
                                                 cellType: TabCollectionViewCell.self))
            { [weak self] (row, tab, cell) in
                guard let self = self else { return }
                let isSelected = self.viewModel.selectedCommercialIndex.asDriver()
                    .distinctUntilChanged()
                    .map { $0 == row }
                
                cell.configure(title: tab.navigationTitle, isSelected: isSelected)
            }
            .disposed(by: disposeBag)
        
        viewModel.selectedCommercialIndex.asDriver()
            .drive(onNext: { [weak self] selectedIndex in
                self?.tabCollectionView.scrollToItem(at: IndexPath(item: selectedIndex, section: 0),
                                                     at: .centeredHorizontally,
                                                     animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func fetchJWT() {
        let accountNumber = viewModel.accountDetail?.accountNumber ?? ""
        var nonce = accountNumber
        
        if viewModel.accountDetail?.isResidential == false {
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
                self.viewModel.accessToken = tokenResponse.token ?? ""

                self.loadWebView()
            case .failure:
                guard let self = self else { return }
                self.errorView.isHidden = false
                self.loadingIndicator.isHidden = true
            }
        }
    }
    
    func loadWebView() {
        guard let token = viewModel.accessToken,
        !token.isEmpty else {
            self.fetchJWT()
            return
        }
        
        let oPowerWidgetURL = Configuration.shared.getSecureOpCoOpowerURLString(viewModel.accountDetail?.opcoType ?? Configuration.shared.opco)
        if let url = URL(string: oPowerWidgetURL) {
            var request = NSURLRequest(url: url) as URLRequest
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue(token, forHTTPHeaderField: "accessToken")
            request.addValue(viewModel.accountDetail?.accountNumber ?? "", forHTTPHeaderField: "accountNumber")
            request.addValue(viewModel.widget.identifier, forHTTPHeaderField: "opowerWidgetId")
            request.addValue(viewModel.accountDetail?.utilityCode ?? Configuration.shared.opco.rawValue, forHTTPHeaderField: "opco")
            request.addValue(viewModel.accountDetail?.state ?? "MD", forHTTPHeaderField: "state")
            request.addValue("\(viewModel.accountDetail?.isResidential == false)", forHTTPHeaderField: "isCommercial")
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
