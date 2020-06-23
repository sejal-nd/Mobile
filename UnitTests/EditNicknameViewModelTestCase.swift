//
//  EditNicknameViewModelTestCase.swift
//  Mobile
//
//  Created by Majumdar, Amit on 18/06/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift

class EditNicknameViewModelTestCase: XCTestCase {

    let disposeBag = DisposeBag()
    var viewModel: EditNicknameViewModel!

    override func setUp() {
        viewModel = EditNicknameViewModel(accountService: MockAccountService())
    }

    override func tearDown() {
        viewModel = nil
    }
    
    func testSaveButtonEnabled() {
        // If the TextField is empty, there is no nickname set, disable the save nickname button
        viewModel.storedAccountNickName = ""
        viewModel.accountNickName.accept("")
        viewModel.saveNicknameEnabled.asObservable().single().subscribe(onNext: { enabled in
            if enabled {
                XCTFail("Save button should not be enabled because there has no text in the text field")
            }
        }).disposed(by: disposeBag)
        
        // If the TextField is filled, nickname is not changed, disable the save nickname button
        viewModel.storedAccountNickName = "ACCOUNT_NICKNAME"
        viewModel.accountNickName.accept("ACCOUNT_NICKNAME")
        viewModel.saveNicknameEnabled.asObservable().single().subscribe(onNext: { enabled in
            if enabled {
                XCTFail("Save button should not be enabled because there has been no change in nickname")
            }
        }).disposed(by: disposeBag)
        
        // If Nickname is modifed enable the button
        viewModel.storedAccountNickName = "ACCOUNT_NICKNAME"
        viewModel.accountNickName.accept("NEW_ACCOUNT_NICKNAME")
       
        viewModel.saveNicknameEnabled.asObservable().single().subscribe(onNext: { enabled in
            if !enabled {
                XCTFail("Save button should be enabled")
            }
        }).disposed(by: disposeBag)
    }

}
