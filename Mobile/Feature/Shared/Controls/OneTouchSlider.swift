//
//  OneTouchSlider.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 7/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class OneTouchSlider: UIControl {
    
    let bag = DisposeBag()
    
    //MARK: - Private Variables
    private let slider = UIView()
    private let sliderFinish = UIView()
    private let sliderLabel = UILabel()
    private var sliderWidthConstraint: NSLayoutConstraint!
    private var sliderFinishWidthConstraint: NSLayoutConstraint!
    private var shouldSlide: Bool = false
    private let imageView = UIImageView(image: #imageLiteral(resourceName: "ic_caret"))
    private let accessibilityButton = UIButton(type: .system)
    
    //MARK: - Public Variables
    private(set) var progress: CGFloat = 0.0
    
    let sliderWidth: CGFloat = 40
    let sliderText = NSLocalizedString("Slide to pay today", comment: "")
    let accessibilityText = NSLocalizedString("Pay full bill now", comment: "")
    let commitToSwipe: CGFloat = 0.95 //swipe percentage point at which we commit to the swipe and call success
    
    private let sliderValueChangedSubject = PublishSubject<CGFloat>()
    private let didFinishSwipeSubject = PublishSubject<Void>()
    private let didCancelSwipeSubject = PublishSubject<Void>()
    
    private(set) lazy var sliderValueChanged: Driver<CGFloat> = self.sliderValueChangedSubject.asDriver(onErrorDriveWith: .empty())
    private(set) lazy var didFinishSwipe: Driver<Void> = self.didFinishSwipeSubject.asDriver(onErrorDriveWith: .empty())
    private(set) lazy var didCancelSwipe: Driver<Void> = self.didCancelSwipeSubject.asDriver(onErrorDriveWith: .empty())

    //MARK: - UIControl
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSlider()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSlider()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = layer.frame.height / 2
        accessibilityButton.layer.cornerRadius = layer.frame.height / 2
        sliderFinish.layer.cornerRadius = sliderFinish.layer.frame.height / 2
        slider.layer.cornerRadius = slider.layer.frame.height / 2
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 300, height: 50)
    }
    
    override var isEnabled: Bool {
        didSet {
            switch (isEnabled, StormModeStatus.shared.isOn) {
            case (true, false):
                alpha = 1
                sliderFinish.alpha = 1
                sliderFinish.backgroundColor = Environment.shared.opco == .bge ? .primaryColorDark: .primaryColorADA
                backgroundColor = .primaryColor
                imageView.image = #imageLiteral(resourceName: "ic_caret")
                sliderLabel.textColor = .white
            case (false, false):
                alpha = 1
                sliderFinish.alpha = 0.5
                sliderFinish.backgroundColor = .middleGray
                backgroundColor = .accentGray
                imageView.image = #imageLiteral(resourceName: "ic_caret_disabled")
                sliderLabel.textColor = .white
            case (true, true):
                alpha = 1
                sliderFinish.alpha = 1
                sliderFinish.backgroundColor = .accentGray
                backgroundColor = .white
                imageView.image = #imageLiteral(resourceName: "ic_caret")
                sliderLabel.textColor = .actionBlue
            case (false, true):
                alpha = 0.4
                sliderFinish.alpha = 1
                sliderFinish.backgroundColor = .accentGray
                backgroundColor = .white
                imageView.image = #imageLiteral(resourceName: "ic_caret_disabled")
                sliderLabel.textColor = .middleGray
            }
            
            accessibilityButton.isEnabled = isEnabled
        }
    }
    
    //MARK: - Private Methods
    
    private func setupSlider() {
        //Apply the custom slider styling
        layer.masksToBounds = true
        backgroundColor = .primaryColor
        widthAnchor.constraint(lessThanOrEqualToConstant: 300).isActive = true
        
        //Add the slider label and set the constraints that will keep it centered
        sliderLabel.translatesAutoresizingMaskIntoConstraints = false
        sliderLabel.textAlignment = .center
        sliderLabel.font = OpenSans.semibold.of(textStyle: .callout)
        sliderLabel.setLineHeight(lineHeight: 16)
        sliderLabel.textColor = StormModeStatus.shared.isOn ? .actionBlue : .white
        sliderLabel.text = sliderText
        sliderLabel.isAccessibilityElement = false
        addSubview(sliderLabel)
        sliderLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        sliderLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        //Create SliderFinishView
        sliderFinish.translatesAutoresizingMaskIntoConstraints = false
        sliderFinish.backgroundColor = Environment.shared.opco == .bge ? .primaryColorDark: .primaryColorADA
        sliderFinish.layer.masksToBounds = true
        addSubview(sliderFinish)
        sliderFinish.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        let sliderFinishBottomConstraint = sliderFinish.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5)
        sliderFinishBottomConstraint.priority = UILayoutPriority(rawValue: 999)
        sliderFinishBottomConstraint.isActive = true
        sliderFinish.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5).isActive = true
        sliderFinishWidthConstraint = sliderFinish.widthAnchor.constraint(equalToConstant: sliderWidth)
        sliderFinishWidthConstraint.isActive = true
        
        //Create Slider
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.backgroundColor = .white
        slider.layer.masksToBounds = true
        slider.addShadow(color: .black, opacity: 0.3, offset: CGSize(width: 0, height: 2), radius: 3)
        addSubview(slider)
        slider.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        let sliderBottomConstraint =  slider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5)
        sliderBottomConstraint.priority = UILayoutPriority(rawValue: 999)
        sliderBottomConstraint.isActive = true
        slider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5).isActive = true
        sliderWidthConstraint = slider.widthAnchor.constraint(equalToConstant: sliderWidth)
        sliderWidthConstraint.priority = UILayoutPriority(rawValue: 999)
        sliderWidthConstraint.isActive = true
        slider.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -5).isActive = true
        
        //ImageView for caret
        imageView.translatesAutoresizingMaskIntoConstraints = false
        slider.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.centerYAnchor.constraint(equalTo: slider.centerYAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: slider.trailingAnchor, constant: -15).isActive = true
        imageView.setContentHuggingPriority(UILayoutPriority(rawValue: 999), for: .horizontal)
        imageView.setContentHuggingPriority(UILayoutPriority(rawValue: 999), for: .vertical)
        
        //Add pan gesture to slide the slider view
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panGesture(_:)))
        addGestureRecognizer(pan)
        
        //Accessibility button
        accessibilityButton.backgroundColor = .clear
        accessibilityButton.isAccessibilityElement = true
        accessibilityButton.accessibilityLabel = accessibilityText
        accessibilityLabel = accessibilityText
        accessibilityButton.rx.tap.asDriver().drive(didFinishSwipeSubject).disposed(by: bag)
        
        addSubview(accessibilityButton)
        
        accessibilityButton.translatesAutoresizingMaskIntoConstraints = false
        
        accessibilityButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
        accessibilityButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        accessibilityButton.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        accessibilityButton.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        accessibilityButton.isHidden = !UIAccessibility.isVoiceOverRunning && !UIAccessibility.isSwitchControlRunning
        isAccessibilityElement = !UIAccessibility.isVoiceOverRunning && !UIAccessibility.isSwitchControlRunning
        
        Observable.merge(NotificationCenter.default.rx.notification(UIAccessibility.switchControlStatusDidChangeNotification, object: nil),
                         NotificationCenter.default.rx.notification(UIAccessibility.voiceOverStatusDidChangeNotification, object: nil))
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] _ in
                self?.accessibilityButton.isHidden = !UIAccessibility.isVoiceOverRunning && !UIAccessibility.isSwitchControlRunning
                self?.isAccessibilityElement = !UIAccessibility.isVoiceOverRunning && !UIAccessibility.isSwitchControlRunning
            })
            .disposed(by: bag)
    }
    
    //MARK: - Public Methods
    func reset(animated: Bool) {
        progress = 0
        sliderWidthConstraint.constant = sliderWidth
        setNeedsUpdateConstraints()
        UIView.animate(withDuration: 0.45,
                       delay: 0.0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0,
                       animations: {
                        self.layoutIfNeeded()
        })
    }
    
    @objc func panGesture(_ recognizer:UIPanGestureRecognizer) {
        let x = recognizer.location(in: self).x
        let padding: CGFloat = 20.0
        switch (recognizer.state) {
        case .began:
            //Only slide if the gestures starts within the slide frame
            shouldSlide = x > (sliderWidthConstraint.constant - sliderWidth) && x < sliderWidthConstraint.constant + padding
            if shouldSlide {
                sliderLabel.fadeView(fadeAmount: 0.0, animationDuration: 0.2)
            }
        case .changed:
            guard shouldSlide && x > sliderWidth && x <= bounds.size.width + padding else { return }
            sliderWidthConstraint.constant = x
            progress = min(x/bounds.size.width, 1)
            sliderValueChangedSubject.onNext(progress)
        case .ended:fallthrough
        case .cancelled:
            sliderLabel.fadeView(fadeAmount: 1.0) 
            guard shouldSlide else { return }
            shouldSlide = false
            
            progress = x/bounds.size.width
            let success: Bool
            let finalX: CGFloat
            
            //If we are past commit point and moving the the right direction
            if progress > commitToSwipe && recognizer.velocity(in: self).x > -1.0 {
                success = true
                finalX = bounds.size.width - 10
            } else {
                success = false
                finalX = sliderWidth
                progress = 0.0
            }
            
            sliderWidthConstraint.constant = finalX
            setNeedsUpdateConstraints()
            
            UIView.animate(withDuration: 0.45,
                           delay: 0.0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: progress,
                           animations: {
                            self.layoutIfNeeded()
            }, completion: { finished in
                if success {
                    self.didFinishSwipeSubject.onNext(())
                } else {
                    self.didCancelSwipeSubject.onNext(())
                }
            })
        default: break
        }
    }
}

