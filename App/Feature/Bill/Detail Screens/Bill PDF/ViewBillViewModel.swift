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
        
    var documentID: String?

    var billDate: Date!
    
    var pdfData: Data?
    var pdfFileUrl: URL?
    var isCurrent: Bool = false
    
    init() {
    }
    
    func fetchBillPDFData(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        BillService.fetchBillPdf(accountNumber: AccountsStore.shared.currentAccount.accountNumber, billDate: billDate, documentID: documentID ?? "") { [weak self] result in
            switch result {
            case .success(let billData):
                if let pdfData = Data(base64Encoded: billData.imageData, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters) {
                    self?.pdfData = pdfData
                    onSuccess()
                } else {
                    onError("Could not parse PDF Data")
                }
            case .failure(let error):
                onError(error.description)
            }
        }
    }
    
    func downloadPDFToTempDirectory(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        let fileURL = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("bill.pdf")
        do {
            try pdfData!.write(to: fileURL, options: .atomic)
        } catch {
            onError(NSLocalizedString("Failed to save the PDF file", comment: ""))
            return
        }
        
        pdfFileUrl = fileURL
        onSuccess()
    }
}
