//
//  SmartThermostatPeriodCard.swift
//  Mobile
//
//  Created by Sam Francis on 11/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class SmartThermostatPeriodCard: ButtonControl {
    
    let imageView = UIImageView()
    let timeLabel = UILabel()
    let periodNameLabel = UILabel()
    let coolTempLabel = UILabel()
    let heatTempLabel = UILabel()
    let caretImageView = UIImageView(image: #imageLiteral(resourceName: "ic_caret"))
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(period: SmartThermostatPeriod, periodInfo: Driver<SmartThermostatPeriodInfo>) {
        self.init(frame: .zero)
        configure(withPeriod: period, periodInfo: periodInfo)
    }
    
    override func commonInit() {
        super.commonInit()
        backgroundColorOnPress = .softGray
        addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        layer.cornerRadius = 10
        backgroundColor = .white
        
        // TIME/PERIOD
        timeLabel.textColor = .blackText
        timeLabel.font = OpenSans.regular.of(size: 20)
        
        periodNameLabel.textColor = .blackText
        periodNameLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        
        let timePeriodStack = UIStackView(arrangedSubviews: [timeLabel, periodNameLabel])
        timePeriodStack.axis = .vertical
        timePeriodStack.spacing = -2
        timePeriodStack.alignment = .leading
        timePeriodStack.isUserInteractionEnabled = false
        
        // TEMPERATURE
        let coolCircle = UIView()
        coolCircle.backgroundColor = .richElectricBlue
        coolCircle.translatesAutoresizingMaskIntoConstraints = false
        coolCircle.heightAnchor.constraint(equalToConstant: 14).isActive = true
        coolCircle.widthAnchor.constraint(equalTo: coolCircle.heightAnchor).isActive = true
        coolCircle.layer.cornerRadius = 7
        
        coolTempLabel.textColor = .blackText
        coolTempLabel.font = OpenSans.bold.of(textStyle: .headline)
        
        let coolStack = UIStackView(arrangedSubviews: [coolCircle, coolTempLabel])
        coolStack.axis = .horizontal
        coolStack.spacing = 8
        coolStack.alignment = .center
        coolStack.isUserInteractionEnabled = false
        
        let heatCircle = UIView()
        heatCircle.backgroundColor = .burntSienna
        heatCircle.translatesAutoresizingMaskIntoConstraints = false
        heatCircle.heightAnchor.constraint(equalToConstant: 14).isActive = true
        heatCircle.widthAnchor.constraint(equalTo: heatCircle.heightAnchor).isActive = true
        heatCircle.layer.cornerRadius = 7
        
        heatTempLabel.textColor = .blackText
        heatTempLabel.font = OpenSans.bold.of(textStyle: .headline)
        
        let heatStack = UIStackView(arrangedSubviews: [heatCircle, heatTempLabel])
        heatStack.axis = .horizontal
        heatStack.spacing = 8
        heatStack.alignment = .center
        heatStack.isUserInteractionEnabled = false
        
        let tempStack = UIStackView(arrangedSubviews: [coolStack, heatStack])
        tempStack.axis = .vertical
        tempStack.spacing = 8
        tempStack.alignment = .leading
        tempStack.isUserInteractionEnabled = false
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.widthAnchor.constraint(equalToConstant: 32).isActive = true
        
        let stackView = UIStackView(arrangedSubviews: [imageView, timePeriodStack, UIView(), tempStack, spacer, caretImageView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = -4
        stackView.isUserInteractionEnabled = false
        
        addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
        stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
    }
    
    func configure(withPeriod period: SmartThermostatPeriod, periodInfo: Driver<SmartThermostatPeriodInfo>) {
        switch period {
        case .wake:
            imageView.image = #imageLiteral(resourceName: "ic_thermostat_wake")
        case .leave:
            imageView.image = #imageLiteral(resourceName: "ic_thermostat_leave")
        case .return:
            imageView.image = #imageLiteral(resourceName: "ic_thermostat_return")
        case .sleep:
            imageView.image = #imageLiteral(resourceName: "ic_thermostat_sleep")
        }
        
        periodNameLabel.text = period.displayString
        
        periodInfo.map { $0.startTimeDisplayString }.drive(timeLabel.rx.text).disposed(by: bag)
        
        let periodInfoAndScale = Driver
            .combineLatest(periodInfo, TemperatureScaleStore.shared.scaleObservable.asDriver(onErrorJustReturn: .fahrenheit))
        
        periodInfoAndScale
            .map { "\($0.coolTemp.value(forScale: $1)) \($1.displayString)" }
            .drive(coolTempLabel.rx.text)
            .disposed(by: bag)
        
        periodInfoAndScale
            .map { "\($0.heatTemp.value(forScale: $1)) \($1.displayString)" }
            .drive(heatTempLabel.rx.text)
            .disposed(by: bag)
        
        periodInfoAndScale
            .map { periodInfo, scale in
                let localizedText = NSLocalizedString("%@ %@ schedule, cool set to %d%@, heat set to %d%@", comment: "")
                return String(format: localizedText,
                              periodInfo.startTimeDisplayString,
                              period.displayString,
                              periodInfo.coolTemp.value(forScale: scale),
                              scale.displayString,
                              periodInfo.heatTemp.value(forScale: scale),
                              scale.displayString)
            }
            .drive(rx.accessibilityLabel)
            .disposed(by: bag)
        
    }
    
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        
    }

}
