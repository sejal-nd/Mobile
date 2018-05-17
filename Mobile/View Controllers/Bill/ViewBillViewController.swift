//
//  ViewBillViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/9/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class ViewBillViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!
    
    var documentController: UIDocumentInteractionController?
    
    let viewModel = ViewBillViewModel(billService: ServiceFactory.createBillService())

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("View Bill", comment: "")
        
        webView.scalesPageToFit = true // allows pinch zooming
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        errorLabel.isHidden = true
        
        webView.rx.didFinishLoad.asDriver(onErrorJustReturn: ()).drive(onNext: { [weak self] in
            guard let `self` = self else { return }
            self.loadingIndicator.isHidden = true
            self.webView.isHidden = false
            let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(self.onSharePress))
            self.navigationItem.rightBarButtonItem = shareButton
        }).disposed(by: self.disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        }
        
        fetchBillPDFData()
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
        webView.isHidden = true
        viewModel.fetchBillPDFData(onSuccess: { [weak self] in
            guard let `self` = self else { return }
            self.webView.load(self.viewModel.pdfData!, mimeType: "application/pdf", textEncodingName: "utf-8", baseURL: URL(string: "https://www.google.com")!)
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
