//
//  CommercialUsageViewController.swift
//  Mobile
//
//  Created by Samuel Francis on 5/3/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import WebKit
import RxSwift
import RxCocoa

class CommercialUsageViewController: UIViewController {
    
    private let viewModel: CommercialUsageViewModel
    private lazy var webView: WKWebView = {
        let contentController = WKUserContentController()
        let source = "window.addEventListener('message', function(event){ window.webkit.messageHandlers.iosListener.postMessage(JSON.stringify(event.data)); })"
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        contentController.addUserScript(script)
        contentController.add(self, name: "iosListener")
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        let webView = WKWebView(frame: .zero, configuration: configuration).usingAutoLayout()
        return webView
    }()
    
    private lazy var webViewHeight = webView.heightAnchor.constraint(equalToConstant: 0)
    
    let tabCollectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 32, bottom: 0, right: 32)
        flowLayout.estimatedItemSize = CGSize(width: 1, height: 50)
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .white
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(UINib(nibName: TabCollectionViewCell.className, bundle: nil),
                                forCellWithReuseIdentifier: TabCollectionViewCell.className)
        return collectionView
    }()
    
    let loadingIndicatorView = UIView().usingAutoLayout()
    
    let disposeBag = DisposeBag()
    
    init(with viewModel: CommercialUsageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func loadView() {
        super.loadView()
        buildLayout()
        bindTabs()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "iosListener")
    }
    
    private func buildLayout() {
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let separatorView = UIView().usingAutoLayout()
        separatorView.backgroundColor = .accentGray
        
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = self
        
        let loadingIndicator = LoadingIndicator(frame: .zero).usingAutoLayout()
        loadingIndicatorView.addSubview(loadingIndicator)
        
        let stackView = UIStackView(arrangedSubviews: [tabCollectionView, separatorView, loadingIndicatorView, webView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.axis = .vertical
        stackView.spacing = 0
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            tabCollectionView.heightAnchor.constraint(equalToConstant: 50),
            separatorView.heightAnchor.constraint(equalToConstant: 1),
            webViewHeight,
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingIndicator.centerXAnchor.constraint(equalTo: loadingIndicatorView.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: loadingIndicatorView.topAnchor, constant: 50),
            loadingIndicator.bottomAnchor.constraint(equalTo: loadingIndicatorView.bottomAnchor)
        ])
        
        viewModel.javascript
            .drive(onNext: { [weak self] javascript in
                guard let self = self else { return }
                self.loadingIndicatorView.isHidden = false
                self.webView.isHidden = true
                self.webView.evaluateJavaScript(javascript)
            })
            .disposed(by: disposeBag)
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
                
                cell.configure(title: tab.title, isSelected: isSelected)
            }
            .disposed(by: disposeBag)
        
        viewModel.selectedIndex.asDriver()
            .drive(onNext: { [weak self] selectedIndex in
                self?.tabCollectionView.scrollToItem(at: IndexPath(item: selectedIndex, section: 0),
                                                     at: .centeredHorizontally,
                                                     animated: true)
            })
            .disposed(by: disposeBag)
        
        viewModel.htmlString
            .drive(onNext: { [weak self] htmlString in
                self?.webView.loadHTMLString(htmlString, baseURL: nil)
            })
            .disposed(by: disposeBag)
        
        viewModel.selectedIndex.asObservable()
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] selectedIndex in
                guard let self = self else { return }
                
                switch self.viewModel.tabs.value[selectedIndex] {
                case .usageTrends:
                    Analytics.log(event: .comUsageTrends)
                case .billingHistory:
                    Analytics.log(event: .comUsageBilling)
                case .weatherImpact:
                    Analytics.log(event: .comUsageWeather)
                case .operatingSchedule:
                    Analytics.log(event: .comUsageOpSchedule)
                }
            })
            .disposed(by: disposeBag)
    }
    
    @available(*, unavailable)
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("this init has not been implemented")
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        viewModel.jsTimeout?.invalidate()
        viewModel.jsTimeout = nil
    }
}

extension CommercialUsageViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.request.url?.absoluteString.contains("tenant_id") ?? false {
            viewModel.jsTimeout?.invalidate()
            viewModel.jsTimeout = nil
            
            loadingIndicatorView.isHidden = true
            webView.isHidden = false
            
            viewModel.didAuthenticate()
            
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
}

extension CommercialUsageViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let bodyString = message.body as? String,
            let data = bodyString.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
            let height = json["height"] as? CGFloat
            else {
                return
        }
        
        webViewHeight.constant = height
    }
}