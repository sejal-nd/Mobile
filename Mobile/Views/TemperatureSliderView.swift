//
//  TemperatureSliderView.swift
//  Mobile
//
//  Created by Sam Francis on 11/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

enum CoolOrHeat: String {
    case cool = "Cool"
    case heat = "Heat"
}

class TemperatureSliderView: UIView {
    
    let disposeBag = DisposeBag()

    let slider = UISlider()
    let titleLabel = UILabel()
    let temperatureLabel = UILabel()
    let minLabel = UILabel()
    let maxLabel = UILabel()
    
    let coolOrHeat: CoolOrHeat
    
    let currentTemperature: BehaviorSubject<Temperature>
    
    init(currentTemperature: BehaviorSubject<Temperature>, minTemp: Temperature, maxTemp: Temperature, coolOrHeat: CoolOrHeat) {
        self.currentTemperature = currentTemperature
        self.coolOrHeat = coolOrHeat
        super.init(frame: .zero)
        clipsToBounds = true
        let localizedTitle = NSLocalizedString("%@ Temperature", comment: "")
        titleLabel.text = String(format: localizedTitle, coolOrHeat.rawValue)
        
        titleLabel.font = SystemFont.bold.of(size: 12)
        temperatureLabel.font = SystemFont.regular.of(size: 22)
        minLabel.font = SystemFont.regular.of(size: 17)
        maxLabel.font = SystemFont.regular.of(size: 17)
        
//        let gradientBackground = CAGradientLayer()
//        let gradientColors: [CGColor]
//        switch coolOrHeat {
//        case .cool:
//            gradientColors = [UIColor(red: 0/255, green: 118/255, blue: 255/255, alpha: 1).cgColor,
//                              UIColor(red: 178/255, green: 213/255, blue: 255/255, alpha: 1).cgColor]
//        case .heat:
//            gradientColors = [UIColor(red: 255/255, green:0/255, blue: 0/255, alpha: 1).cgColor,
//                              UIColor(red: 255/255, green: 225/255, blue: 23/255, alpha: 1).cgColor]
//        }
//        gradientBackground.colors = gradientColors
//        gradientBackground.startPoint = CGPoint(x: 0, y: 0.5)
//        gradientBackground.endPoint = CGPoint(x: 1, y: 0.5)
//
//        let gradientImage = UIImage.image(fromLayer: gradientBackground)
//        slider.setMinimumTrackImage(gradientImage, for: .normal)
//        slider.setMaximumTrackImage(gradientImage, for: .normal)
        
        slider.minimumValue = Float(minTemp.fahrenheit)
        slider.maximumValue = Float(maxTemp.fahrenheit)
        
        currentTemperature.asObservable()
            .distinctUntilChanged()
            .map { Float($0.fahrenheit) }
            .asDriver(onErrorDriveWith: .empty())
            .drive(slider.rx.value)
            .disposed(by: disposeBag)
        
        // Label Text
        Observable.combineLatest(currentTemperature.asObservable().distinctUntilChanged(), TemperatureScaleStore.shared.scaleObservable)
            .map { "\($0.value(forScale: $1))" }
            .asDriver(onErrorDriveWith: .empty())
            .drive(temperatureLabel.rx.text)
            .disposed(by: disposeBag)

        Observable.combineLatest(slider.rx.value.skip(1).distinctUntilChanged(),
                                 TemperatureScaleStore.shared.scaleObservable,
                                 resultSelector: Temperature.init)
            .distinctUntilChanged()
            .bind(to: currentTemperature)
            .disposed(by: disposeBag)

        TemperatureScaleStore.shared.scaleObservable.asDriver(onErrorDriveWith: .empty())
            .map(minTemp.value)
            .map { "\($0)" }
            .drive(minLabel.rx.text)
            .disposed(by: disposeBag)

        TemperatureScaleStore.shared.scaleObservable.asDriver(onErrorDriveWith: .empty())
            .map(maxTemp.value)
            .map { "\($0)" }
            .drive(maxLabel.rx.text)
            .disposed(by: disposeBag)
        
        temperatureLabel.setContentHuggingPriority(1000, for: .horizontal)
        let labelStack = UIStackView(arrangedSubviews: [titleLabel, temperatureLabel]).usingAutoLayout()
        labelStack.axis = .horizontal
        labelStack.alignment = .lastBaseline
        
        let labelStackContainer = UIView()
        labelStackContainer.addSubview(labelStack)

        labelStack.topAnchor.constraint(equalTo: labelStackContainer.topAnchor).isActive = true
        labelStack.bottomAnchor.constraint(equalTo: labelStackContainer.bottomAnchor).isActive = true
        labelStack.centerXAnchor.constraint(equalTo: labelStackContainer.centerXAnchor).isActive = true
        
        minLabel.setContentHuggingPriority(1000, for: .horizontal)
        maxLabel.setContentHuggingPriority(1000, for: .horizontal)
        let sliderStack = UIStackView(arrangedSubviews: [minLabel, slider, maxLabel])
        sliderStack.axis = .horizontal
        sliderStack.alignment = .center
        
        let mainStack = UIStackView(arrangedSubviews: [labelStackContainer, sliderStack]).usingAutoLayout()
        mainStack.axis = .vertical
        mainStack.alignment = .fill
        
        labelStack.widthAnchor.constraint(equalTo: slider.widthAnchor).isActive = true
        
        addSubview(mainStack)
        mainStack.topAnchor.constraint(equalTo: topAnchor).isActive = true
        mainStack.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        mainStack.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        mainStack.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        
    }
    
    func commonInit() {
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not Implemented")
    }
    
    override init(frame: CGRect) {
        fatalError("Not Implemented")
    }
}

extension UIImage {
    static func image(fromLayer layer: CALayer) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, layer.isOpaque, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        layer.render(in: context)
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return outputImage
    }
}
