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
    
    let viewModel: CommercialUsageViewModel
    let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    
    let disposeBag = DisposeBag()
    
    init(with viewModel: CommercialUsageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func loadView() {
        super.loadView()
        buildLayout()
    }
    
    private func buildLayout() {
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let tabCollectionView = UIScrollView()
        tabCollectionView.backgroundColor = .green
        
        let separatorView = UIView()
        separatorView.backgroundColor = .accentGray
        
        webView.scrollView.isScrollEnabled = false
        webView.load(URLRequest(url: viewModel.url))
        
        let stackView = UIStackView(arrangedSubviews: [tabCollectionView, separatorView, webView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.axis = .vertical
        stackView.spacing = 0
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            tabCollectionView.heightAnchor.constraint(equalToConstant: 50),
            separatorView.heightAnchor.constraint(equalToConstant: 1),
            webView.heightAnchor.constraint(equalToConstant: 800),
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        
    }
    
    @available(*, unavailable)
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("this init has not been implemented")
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension CommercialUsageViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeEditEmptyCell.className, for: indexPath)
        
        return cell
    }
    
}
