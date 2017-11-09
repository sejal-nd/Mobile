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
    
    private let minMaxLabelWidth: CGFloat = 30
    private let sliderStackSpacing: CGFloat = 12
    
    let disposeBag = DisposeBag()

    let slider = UISlider().usingAutoLayout()
    let titleLabel = UILabel().usingAutoLayout()
    let temperatureLabel = UILabel().usingAutoLayout()
    let minLabel = UILabel().usingAutoLayout()
    let maxLabel = UILabel().usingAutoLayout()
    
    let coolOrHeat: CoolOrHeat
    
    let currentTemperature: BehaviorSubject<Temperature>
    
    init(currentTemperature: BehaviorSubject<Temperature>, tempRange: CountableClosedRange<Int>, scale: TemperatureScale, coolOrHeat: CoolOrHeat) {
        self.currentTemperature = currentTemperature
        self.coolOrHeat = coolOrHeat
        super.init(frame: .zero)
        
        let localizedTitle = NSLocalizedString("%@ Temperature", comment: "")
        titleLabel.text = String(format: localizedTitle, coolOrHeat.rawValue)
        
        titleLabel.font = SystemFont.bold.of(size: 12)
        temperatureLabel.font = SystemFont.regular.of(size: 22)
        minLabel.font = SystemFont.regular.of(size: 17)
        maxLabel.font = SystemFont.regular.of(size: 17)
        
        slider.minimumValue = Float(tempRange.lowerBound)
        slider.maximumValue = Float(tempRange.upperBound)
        
        currentTemperature.asObservable().take(1)
            .distinctUntilChanged()
            .map { Float($0.value(forScale: scale)) }
            .asDriver(onErrorDriveWith: .empty())
            .drive(slider.rx.value)
            .disposed(by: disposeBag)
        
        slider.rx.value.skip(1)
            .map { Temperature(value: round($0), scale: scale) }
            .distinctUntilChanged()
            .bind(to: currentTemperature)
            .disposed(by: disposeBag)
        
        // Label Text
        currentTemperature.asObservable().distinctUntilChanged()
            .map { "\($0.value(forScale: scale))\(scale.displayString)" }
            .asDriver(onErrorDriveWith: .empty())
            .drive(temperatureLabel.rx.text)
            .disposed(by: disposeBag)

        minLabel.text = String(tempRange.lowerBound)
        maxLabel.text = String(tempRange.upperBound)
        
        temperatureLabel.setContentHuggingPriority(1000, for: .horizontal)
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
        switch coolOrHeat {
        case .cool:
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
