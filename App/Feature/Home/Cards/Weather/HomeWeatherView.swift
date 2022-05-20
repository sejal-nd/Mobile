//
//  HomeWeatherView.swift
//  Mobile
//
//  Created by Samuel Francis on 6/4/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class HomeWeatherView: UIView {
    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var weatherIconImage: UIImageView!
    
    @IBOutlet weak var temperatureTipButton: ButtonControl!
    @IBOutlet weak var temperatureTipImageView: UIImageView!
    @IBOutlet weak var temperatureTipLabel: UILabel!
    
    var bag = DisposeBag()
    
    var viewModel: HomeWeatherViewModel! {
        didSet {
            bag = DisposeBag() // Clear all pre-existing bindings
            bindViewModel()
        }
    }
    
    static func create(withViewModel viewModel: HomeWeatherViewModel) -> HomeWeatherView {
        let view = Bundle.main.loadViewFromNib() as HomeWeatherView
        view.styleViews()
        view.viewModel = viewModel
        return view
    }
    
    func styleViews() {
        backgroundColor = .clear
        greetingLabel.isAccessibilityElement = true
        temperatureLabel.isAccessibilityElement = true
        weatherIconImage.isAccessibilityElement = true
        accessibilityElements = [greetingLabel, temperatureLabel, weatherIconImage, temperatureTipButton] as [UIView]
    }
    
    func bindViewModel() {
        temperatureTipButton.rx.touchUpInside.asDriver().drive(onNext: {
            FirebaseUtility.logEvent(.home(parameters: [.weather_tip]))
        })
        .disposed(by: bag)
        
        viewModel.showWeatherDetails.not().drive(temperatureLabel.rx.isHidden).disposed(by: bag)
        viewModel.showWeatherDetails.not().drive(weatherIconImage.rx.isHidden).disposed(by: bag)
        viewModel.showTemperatureTip.not().drive(temperatureTipButton.rx.isHidden).disposed(by: bag)
        
        viewModel.showWeatherDetails.drive(temperatureLabel.rx.isAccessibilityElement).disposed(by: bag)
        viewModel.showWeatherDetails.drive(weatherIconImage.rx.isAccessibilityElement).disposed(by: bag)
        
        viewModel.greeting.drive(greetingLabel.rx.text).disposed(by: bag)
        viewModel.weatherTemp.drive(temperatureLabel.rx.text).disposed(by: bag)
        viewModel.weatherTemp.drive(onNext: { [weak self] weatherTemp in
            guard let tempString = weatherTemp else { return }
            self?.temperatureLabel.accessibilityLabel = String(format: NSLocalizedString("Current temperature %@", comment: ""), tempString)
        }).disposed(by: bag)
        viewModel.weatherIcon.drive(weatherIconImage.rx.image).disposed(by: bag)
        viewModel.weatherIconA11yLabel.drive(weatherIconImage.rx.accessibilityLabel).disposed(by: bag)
        
        viewModel.temperatureTipText.drive(temperatureTipLabel.rx.text).disposed(by: bag)
        viewModel.temperatureTipText.isNil().not().drive(temperatureTipButton.rx.isAccessibilityElement).disposed(by: bag)
        viewModel.temperatureTipText.drive(temperatureTipButton.rx.accessibilityLabel).disposed(by: bag)
        viewModel.temperatureTipImage.drive(temperatureTipImageView.rx.image).disposed(by: bag)
    }
    
    lazy var didTapTemperatureTip: Driver<(title: String, image: UIImage, body: String, modalBtnLabel: String?,  onClose: (() -> ())?)> =
        self.temperatureTipButton.rx.touchUpInside.asDriver()
            .withLatestFrom(self.viewModel.temperatureTipModalData)

}
