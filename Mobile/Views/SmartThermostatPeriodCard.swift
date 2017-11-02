//
//  SmartThermostatPeriodCard.swift
//  Mobile
//
//  Created by Sam Francis on 11/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class SmartThermostatPeriodCard: UIView {
    
    let disposeBag = DisposeBag()

    convenience init(period: SmartThermostatPeriod, periodInfo: SmartThermostatPeriodInfo, temperatureScale: TemperatureScale) {
        self.init(frame: .zero)
        
        addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        layer.cornerRadius = 2
        backgroundColor = .white
        
        let image: UIImage
        switch period {
        case .wake:
            image = #imageLiteral(resourceName: "ic_thermostat_wake")
        case .leave:
            image = #imageLiteral(resourceName: "ic_thermostat_leave")
        case .return:
            image = #imageLiteral(resourceName: "ic_thermostat_return")
        case .sleep:
            image = #imageLiteral(resourceName: "ic_thermostat_sleep")
        }
        let imageView = UIImageView(image: image)
        
        let timeLabel = UILabel()
        timeLabel.text = periodInfo.startTime
        timeLabel.textColor = .blackText
        timeLabel.font = OpenSans.bold.of(size: 18)
        
        let titleLabel = UILabel()
        titleLabel.text = period.displayString
        titleLabel.textColor = .blackText
        titleLabel.font = OpenSans.bold.of(textStyle: .subheadline)
        
        
        let coolTempLabel = UILabel()
        TemperatureScaleStore.shared.scaleObservable.asDriver(onErrorJustReturn: .fahrenheit)
            .map { "\(periodInfo.coolTemp) \($0.displayString)" }
            .drive(coolTempLabel.rx.text)
            .disposed(by: disposeBag)
        coolTempLabel.textColor = .blackText
        coolTempLabel.font = OpenSans.bold.of(textStyle: .subheadline)
        
        let coolCircle = UIView()
        coolCircle.backgroundColor = .richElectricBlue
        coolCircle.translatesAutoresizingMaskIntoConstraints = false
        coolCircle.heightAnchor.constraint(equalToConstant: 14).isActive = true
        coolCircle.widthAnchor.constraint(equalTo: coolCircle.heightAnchor).isActive = true
        
        let heatCircle = UIView()
        heatCircle.backgroundColor = .burntSienna
        heatCircle.translatesAutoresizingMaskIntoConstraints = false
        heatCircle.heightAnchor.constraint(equalToConstant: 14).isActive = true
        heatCircle.widthAnchor.constraint(equalTo: heatCircle.heightAnchor).isActive = true
        
        
//        let stackView = UIStackView(arrangedSubviews: [titleLabel, coolCircle, descriptionContainer])
//        stackView.axis = .vertical
//        stackView.alignment = .fill
//        stackView.spacing = 12
//        
//        addSubview(stackView)
//        
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        stackView.topAnchor.constraint(equalTo: topAnchor, constant: 18).isActive = true
//        stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -21).isActive = true
//        stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 11).isActive = true
//        stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -11).isActive = true
    }
    
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }

}
