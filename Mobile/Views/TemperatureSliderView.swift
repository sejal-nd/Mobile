//
//  TemperatureSliderView.swift
//  Mobile
//
//  Created by Sam Francis on 11/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class TemperatureSliderView: UIView {
    
    private let minMaxLabelWidth: CGFloat = 30
    private let sliderStackSpacing: CGFloat = 12
    
    let disposeBag = DisposeBag()

    private let slider = TemperatureSlider().usingAutoLayout()
    private let titleLabel = UILabel().usingAutoLayout()
    private let temperatureLabel = UILabel().usingAutoLayout()
    private let minLabel = UILabel().usingAutoLayout()
    private let maxLabel = UILabel().usingAutoLayout()
    
    let mode: Variable<SmartThermostatMode>
    let currentTemperature: BehaviorSubject<Temperature>
    let minTemp: Temperature
    let maxTemp: Temperature
    let scale: TemperatureScale
    
    init(currentTemperature: BehaviorSubject<Temperature>, minTemp: Temperature, maxTemp: Temperature, scale: TemperatureScale, mode: Variable<SmartThermostatMode>) {
        self.currentTemperature = currentTemperature
        self.mode = mode
        self.scale = scale
        self.minTemp = minTemp
        self.maxTemp = maxTemp
        super.init(frame: .zero)
        buildLayout()
        bindViews()
    }
    
    func buildLayout() {
        temperatureLabel.setContentHuggingPriority(.required, for: .horizontal)
        temperatureLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        let labelStack = UIStackView(arrangedSubviews: [titleLabel, temperatureLabel]).usingAutoLayout()
        labelStack.axis = .horizontal
        labelStack.alignment = .lastBaseline
        
        let labelStackContainer = UIView()
        labelStackContainer.addSubview(labelStack)
        
        labelStack.topAnchor.constraint(equalTo: labelStackContainer.topAnchor).isActive = true
        labelStack.bottomAnchor.constraint(equalTo: labelStackContainer.bottomAnchor).isActive = true
        labelStack.centerXAnchor.constraint(equalTo: labelStackContainer.centerXAnchor).isActive = true
        
        minLabel.widthAnchor.constraint(equalToConstant: minMaxLabelWidth).isActive = true
        maxLabel.widthAnchor.constraint(equalToConstant: minMaxLabelWidth).isActive = true
        
        minLabel.textAlignment = .center
        maxLabel.textAlignment = .center
        
        let sliderStack = UIStackView(arrangedSubviews: [minLabel, slider, maxLabel])
        sliderStack.axis = .horizontal
        sliderStack.alignment = .center
        sliderStack.spacing = sliderStackSpacing
        
        let mainStack = UIStackView(arrangedSubviews: [labelStackContainer, sliderStack]).usingAutoLayout()
        mainStack.axis = .vertical
        mainStack.alignment = .fill
        mainStack.spacing = 20
        
        labelStack.widthAnchor.constraint(equalTo: slider.widthAnchor).isActive = true
        
        addSubview(mainStack)
        mainStack.topAnchor.constraint(equalTo: topAnchor).isActive = true
        mainStack.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        mainStack.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        mainStack.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
    
    func bindViews() {
        let offText = mode.asDriver()
            .filter { $0 == .off }
            .mapTo(NSLocalizedString("Off", comment: ""))
        
        offText
            .drive(temperatureLabel.rx.text)
            .disposed(by: disposeBag)
        
        offText
            .drive(temperatureLabel.rx.accessibilityLabel)
            .disposed(by: disposeBag)
        
        let titleText = mode.asDriver()
            .map { mode -> String in
                switch mode {
                case .cool:
                    return NSLocalizedString("Cool Temperature", comment: "")
                case .heat:
                    return NSLocalizedString("Heat Temperature", comment: "")
                case .off:
                    return NSLocalizedString("Thermostat Mode", comment: "")
                }
        }
        
        titleText
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)
        
        slider.accessibilityLabel = NSLocalizedString("temperature control", comment: "")
        
        mode.asDriver().map { $0 != .off }.drive(slider.rx.isEnabled).disposed(by: disposeBag)
        
        Driver.combineLatest(currentTemperature.asDriver(onErrorDriveWith: .empty()), mode.asDriver())
            .map { [unowned self] temperature, mode in
                switch mode {
                case .cool, .heat:
                    return String(format: NSLocalizedString("%d degrees", comment: ""),
                                  temperature.value(forScale: self.scale))
                case .off:
                    return NSLocalizedString("Off", comment: "")
                }
            }
            .drive(slider.rx.accessibilityValue)
            .disposed(by: disposeBag)
        
        let sliderLabelTextColor = mode.asDriver()
            .map { $0 == .off ? UIColor.middleGray : UIColor.blackText  }
        
        sliderLabelTextColor.drive(minLabel.rx.textColor).disposed(by: disposeBag)
        sliderLabelTextColor.drive(maxLabel.rx.textColor).disposed(by: disposeBag)
        
        mode.asDriver()
            .skip(1)
            .filter { $0 != .off }
            .drive(onNext: { [weak self] _ in
                self?.setGradientTrackingImage()
            })
            .disposed(by: disposeBag)
        
        titleLabel.font = SystemFont.bold.of(textStyle: .caption1)
        temperatureLabel.font = OpenSans.semibold.of(textStyle: .title3)
        minLabel.font = SystemFont.regular.of(size: 17)
        maxLabel.font = SystemFont.regular.of(size: 17)
        
        slider.minimumValue = Float(minTemp.value(forScale: scale))
        slider.maximumValue = Float(maxTemp.value(forScale: scale))
        
        currentTemperature.asObservable()
            .distinctUntilChanged()
            .map { [unowned self] in Float($0.value(forScale: self.scale)) }
            .asDriver(onErrorDriveWith: .empty())
            .drive(slider.rx.value)
            .disposed(by: disposeBag)
        
        slider.rx.value.asDriver().skip(1)
            .map { [unowned self] in Temperature(value: round($0), scale: self.scale) }
            .distinctUntilChanged()
            .drive(currentTemperature)
            .disposed(by: disposeBag)
        
        let temperatureText = Observable.merge(currentTemperature.asObservable().distinctUntilChanged(),
                         mode.asObservable().filter { $0 != .off }.withLatestFrom(currentTemperature))
            .map { [unowned self] in "\($0.value(forScale: self.scale))\(self.scale.displayString)" }
            .asDriver(onErrorDriveWith: .empty())
        
        temperatureText
            .drive(temperatureLabel.rx.text)
            .disposed(by: disposeBag)
        
        temperatureText
            .map { String(format: NSLocalizedString("set to %@", comment: ""), $0)}
            .drive(temperatureLabel.rx.accessibilityLabel)
            .disposed(by: disposeBag)
        
        minLabel.text = String(minTemp.value(forScale: scale))
        minLabel.accessibilityLabel = String(format: NSLocalizedString("minimum temperature %d%@", comment: ""), minTemp.value(forScale: scale), scale.displayString)
        
        maxLabel.text = String(maxTemp.value(forScale: scale))
        maxLabel.accessibilityLabel = String(format: NSLocalizedString("maximum temperature %d%@", comment: ""), maxTemp.value(forScale: scale), scale.displayString)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setGradientTrackingImage()
    }
    
    func setGradientTrackingImage() {
        let gradientBackground = CAGradientLayer()
        var gradientFrame = frame
        gradientFrame.size.height = 5.0
        gradientFrame.size.width = frame.width - 2 * (minMaxLabelWidth + sliderStackSpacing)
        gradientBackground.frame = gradientFrame
        let gradientColors: [CGColor]
        switch mode.value {
        case .cool, .off:
            gradientColors = [UIColor(red: 0/255, green: 118/255, blue: 255/255, alpha: 1).cgColor,
                              UIColor(red: 178/255, green: 213/255, blue: 255/255, alpha: 1).cgColor]
        case .heat:
            gradientColors = [UIColor(red: 255/255, green: 225/255, blue: 23/255, alpha: 1).cgColor,
                              UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 1).cgColor]
        }
        gradientBackground.colors = gradientColors
        gradientBackground.startPoint = CGPoint(x: 0, y: 0.5)
        gradientBackground.endPoint = CGPoint(x: 1, y: 0.5)
        
        let gradientImage = UIImage.image(fromLayer: gradientBackground)
        slider.setMinimumTrackImage(gradientImage, for: .normal)
        slider.maximumTrackTintColor = UIColor(red: 164/255, green: 170/255, blue: 179/255, alpha: 1)
        slider.subviews.filter { $0 is UIImageView && $0.subviews.isEmpty }
            .forEach {
                $0.layer.cornerRadius = 1
                $0.contentMode = .left
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not Implemented")
    }
    
    override init(frame: CGRect) {
        fatalError("Not Implemented")
    }
}

fileprivate class TemperatureSlider: UISlider {
    
    override func accessibilityIncrement() {
        value += 1
        sendActions(for: .valueChanged)
    }

    override func accessibilityDecrement() {
        value -= 1
        sendActions(for: .valueChanged)
    }
}

extension UIImage {
    static func image(fromLayer layer: CALayer) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, layer.isOpaque, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
            
        }
        layer.render(in: context)
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return outputImage
    }
}
