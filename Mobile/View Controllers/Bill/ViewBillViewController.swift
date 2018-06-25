//
//  ViewBillViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/9/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import WebKit

class ViewBillViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var webContainerView: UIView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!

    var documentController: UIDocumentInteractionController?
    
    let viewModel = ViewBillViewModel(billService: ServiceFactory.createBillService())

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("View Bill", comment: "")
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        errorLabel.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        }
        
        fetchBillPDFData()
    }
    
    
    // MARK: - Helper
    
    private func setupWKWebView() {
        loadingIndicator.isHidden = false

        // Programtically Configure WKWebView due to a bug with using IB WKWebView before iOS 11
        let webConfiguration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero , configuration: webConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webContainerView.addSubview(webView)
        webView.topAnchor.constraint(equalTo: webContainerView.topAnchor).isActive = true
        webView.rightAnchor.constraint(equalTo: webContainerView.rightAnchor).isActive = true
        webView.leftAnchor.constraint(equalTo: webContainerView.leftAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: webContainerView.bottomAnchor).isActive = true
        
        guard let pdfData = viewModel.pdfData, let baseUrl = URL(string: "https://www.google.com") else { return }
        webView.load(pdfData, mimeType: "application/pdf", characterEncodingName: "utf-8", baseURL: baseUrl)
    }
    
    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)
        if parent == nil {
            if let navController = navigationController as? MainBaseNavigationController {
                navController.setColoredNavBar()
            }
        }
    }
    
    func fetchBillPDFData() {
        loadingIndicator.isHidden = false
        viewModel.fetchBillPDFData(onSuccess: { [weak self] in
            guard let `self` = self else { return }
            self.setupWKWebView()
        }, onError: { [weak self] errMessage in
            guard let `self` = self else { return }
            self.loadingIndicator.isHidden = true
            self.errorLabel.isHidden = false
        })
    }
    
    @objc func onSharePress() {
        if viewModel.pdfFileUrl != nil {
            presentDocumentController()
        } else {
            LoadingView.show()
            viewModel.downloadPDFToTempDirectory(onSuccess: { [weak self] in
                LoadingView.hide()
                self?.presentDocumentController()
            }, onError: { [weak self] errMessage in
                LoadingView.hide()
                let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alertVc, animated: true, completion: nil)
            })
        }

    }
    
    func presentDocumentController() {
        documentController = UIDocumentInteractionController(url: viewModel.pdfFileUrl!)
        documentController!.presentOptionsMenu(from: view.frame, in: view, animated: true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .default }
    
}

extension ViewBillViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.isHidden = true
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(self.onSharePress))
        navigationItem.rightBarButtonItem = shareButton
    }
    
}
