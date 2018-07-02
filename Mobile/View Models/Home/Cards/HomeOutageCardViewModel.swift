//
//  HomeOutageCardViewModel.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/2/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

class HomeOutageCardViewModel {
    
    private let bag = DisposeBag()
    
    private(set) lazy var powerStatusImage: Driver<UIImage> = {
       return UIImage()
    }()
    
    private(set) lazy var powerStatus: Driver<String> = {
        return "ON"
    }()
    
    private(set) lazy var restorationTime: Driver<String> = {
        return Date().fullMonthDayAndYearString
    }()
    
}
