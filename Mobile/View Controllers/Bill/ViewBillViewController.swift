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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        }
        
        fetchBillPDFData()
    }
    
    func fetchBillPDFData() {
        loadingIndicator.isHidden = false
        webView.isHidden = true
        viewModel.fetchBillPDFData(onSuccess: {
            self.webView.rx.didFinishLoad.asObservable().subscribe(onNext: {
                self.loadingIndicator.isHidden = true
                self.webView.isHidden = false
                let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(self.onSharePress))
                self.navigationItem.rightBarButtonItem = shareButton
            }).disposed(by: self.disposeBag)
            self.webView.load(self.viewModel.pdfData!, mimeType: "application/pdf", textEncodingName: "utf-8", baseURL: URL(string: "https://www.google.com")!)
        }, onError: { errMessage in
            self.loadingIndicator.isHidden = true
            self.errorLabel.isHidden = false
        })
    }
    
    func onSharePress() {
        if viewModel.pdfFileUrl != nil {
            presentDocumentController()
        } else {
            LoadingView.show()
            viewModel.downloadPDFToTempDirectory(onSuccess: {
                LoadingView.hide()
                self.presentDocumentController()
            }, onError: { errMessage in
                LoadingView.hide()
                let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self.present(alertVc, animated: true, completion: nil)
            })
        }

    }
    
    func presentDocumentController() {
        self.documentController = UIDocumentInteractionController(url: self.viewModel.pdfFileUrl!)
        self.documentController!.presentOptionsMenu(from: self.view.frame, in: self.view, animated: true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .default }
    
}
