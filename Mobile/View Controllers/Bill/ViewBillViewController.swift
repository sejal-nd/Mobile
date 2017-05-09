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
    
    let viewModel = ViewBillViewModel(billService: ServiceFactory.createBillService())

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("View Bill", comment: "")
        
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(onSharePress))
        navigationItem.rightBarButtonItem = shareButton
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        }
        
        loadingIndicator.isHidden = false
        webView.isHidden = true
        viewModel.downloadBillPDF(onSuccess: {
            self.webView.rx.didFinishLoad.asObservable().subscribe(onNext: {
                self.loadingIndicator.isHidden = true
                self.webView.isHidden = false
            }).addDisposableTo(self.disposeBag)
            self.webView.load(self.viewModel.pdfData!, mimeType: "application/pdf", textEncodingName: "utf-8", baseURL: NSURL() as URL)
        }, onError: { err in
            self.loadingIndicator.isHidden = true
            print(err)
        })
    }
    
    func onSharePress() {
        print("share")
    }

}
