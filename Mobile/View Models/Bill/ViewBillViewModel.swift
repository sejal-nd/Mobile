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
//        billService.fetchBillPdf(account: AccountsStore.sharedInstance.currentAccount, billDate: billDate)
//            .observeOn(MainScheduler.instance)
//            .subscribe(onNext: { billDataString in
//                print(billDataString)
//            }, onError: { errMessage in
//                print(errMessage)
//            })
//            .addDisposableTo(disposeBag)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
            let data = Data(base64Encoded: "JVBERi0xLjcKCjEgMCBvYmogICUgZW50cnkgcG9pbnQKPDwKICAvVHlwZSAvQ2F0YWxvZwogIC9QYWdlcyAyIDAgUgo+PgplbmRvYmoKCjIgMCBvYmoKPDwKICAvVHlwZSAvUGFnZXMKICAvTWVkaWFCb3ggWyAwIDAgMjAwIDIwMCBdCiAgL0NvdW50IDEKICAvS2lkcyBbIDMgMCBSIF0KPj4KZW5kb2JqCgozIDAgb2JqCjw8CiAgL1R5cGUgL1BhZ2UKICAvUGFyZW50IDIgMCBSCiAgL1Jlc291cmNlcyA8PAogICAgL0ZvbnQgPDwKICAgICAgL0YxIDQgMCBSIAogICAgPj4KICA+PgogIC9Db250ZW50cyA1IDAgUgo+PgplbmRvYmoKCjQgMCBvYmoKPDwKICAvVHlwZSAvRm9udAogIC9TdWJ0eXBlIC9UeXBlMQogIC9CYXNlRm9udCAvVGltZXMtUm9tYW4KPj4KZW5kb2JqCgo1IDAgb2JqICAlIHBhZ2UgY29udGVudAo8PAogIC9MZW5ndGggNDQKPj4Kc3RyZWFtCkJUCjcwIDUwIFRECi9GMSAxMiBUZgooSGVsbG8sIHdvcmxkISkgVGoKRVQKZW5kc3RyZWFtCmVuZG9iagoKeHJlZgowIDYKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDAwMDEwIDAwMDAwIG4gCjAwMDAwMDAwNzkgMDAwMDAgbiAKMDAwMDAwMDE3MyAwMDAwMCBuIAowMDAwMDAwMzAxIDAwMDAwIG4gCjAwMDAwMDAzODAgMDAwMDAgbiAKdHJhaWxlcgo8PAogIC9TaXplIDYKICAvUm9vdCAxIDAgUgo+PgpzdGFydHhyZWYKNDkyCiUlRU9G", options: NSData.Base64DecodingOptions.ignoreUnknownCharacters)
            if let pdfData = data {
                self.pdfData = pdfData
                onSuccess()
            } else {
                onError("Could not parse PDF Data")
            }
        })
    }
}
