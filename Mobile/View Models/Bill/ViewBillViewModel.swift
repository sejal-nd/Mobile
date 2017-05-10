//
//  ViewBillViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 5/9/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class ViewBillViewModel {
    
    private let disposeBag = DisposeBag()
    
    private var billService: BillService
    
    var billDate: Date!
    
    var pdfData: Data?

    init(billService: BillService) {
        self.billService = billService
    }
    
    func downloadBillPDF(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        billService.fetchBillPdf(account: AccountsStore.sharedInstance.currentAccount, billDate: billDate)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { billDataString in
                if let pdfData = Data(base64Encoded: billDataString, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters) {
                    self.pdfData = pdfData
                    onSuccess()
                } else {
                    onError("Could not parse PDF Data")
                }
            }, onError: { errMessage in
                onError(errMessage.localizedDescription)
            })
            .addDisposableTo(disposeBag)
    }
}
