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
    
    //MARK: - Private Variables
    private let slider = UIView()
    private let sliderFinish = UIView()
    private let sliderLabel = UILabel()
    private var sliderWidthConstraint: NSLayoutConstraint!
    private var sliderFinishWidthConstraint: NSLayoutConstraint!
    private var shouldSlide: Bool = false
    private let imageView = UIImageView(image: #imageLiteral(resourceName: "ic_caret"))
    
    //MARK: - Public Variables
    private(set) var progress: CGFloat = 0.0
    
    let sliderWidth: CGFloat = 40
    let sliderText = NSLocalizedString("Slide to pay now", comment: "")
    let accessibilityText = NSLocalizedString("Tap to pay", comment: "")
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
        sliderFinish.layer.cornerRadius = sliderFinish.layer.frame.height / 2
        slider.layer.cornerRadius = slider.layer.frame.height / 2
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 300, height: 50)
    }
    
    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                backgroundColor = .primaryColor
                sliderFinish.backgroundColor = Environment.sharedInstance.opco == .bge ? .primaryColorDark: .primaryColorADA
                sliderFinish.alpha = 1
                alpha = 1
                imageView.image = #imageLiteral(resourceName: "ic_caret")
            } else {
                backgroundColor = .accentGray
                sliderFinish.backgroundColor = .middleGray
                sliderFinish.alpha = 0.5
                alpha = 0.5
                imageView.image = #imageLiteral(resourceName: "ic_caret_disabled")
            }
        }
    }
    
    //MARK: - Private Methods
    
    private func setupSlider() {
        //Apply the custom slider styling
        layer.masksToBounds = true
        backgroundColor = .primaryColor
        
        //Add the slider label and set the constraints that will keep it centered
        sliderLabel.translatesAutoresizingMaskIntoConstraints = false
        sliderLabel.textAlignment = .center
        sliderLabel.font = OpenSans.semibold.of(textStyle: .headline)
        sliderLabel.setLineHeight(lineHeight: 16)
        sliderLabel.textColor = .white
        sliderLabel.text = sliderText
        addSubview(sliderLabel)
        sliderLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        sliderLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        //Create SliderFinishView
        sliderFinish.translatesAutoresizingMaskIntoConstraints = false
        sliderFinish.backgroundColor = Environment.sharedInstance.opco == .bge ? .primaryColorDark: .primaryColorADA
        sliderFinish.layer.masksToBounds = true
        addSubview(sliderFinish)
        sliderFinish.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        let sliderFinishBottomConstraint = sliderFinish.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5)
        sliderFinishBottomConstraint.priority = 999
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
        sliderBottomConstraint.priority = 999
        sliderBottomConstraint.isActive = true
        slider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5).isActive = true
        sliderWidthConstraint = slider.widthAnchor.constraint(equalToConstant: sliderWidth)
        sliderWidthConstraint.priority = 999
        sliderWidthConstraint.isActive = true
        slider.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -5).isActive = true
        
        //ImageView for caret
        imageView.translatesAutoresizingMaskIntoConstraints = false
        slider.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.centerYAnchor.constraint(equalTo: slider.centerYAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: slider.trailingAnchor, constant: -15).isActive = true
        imageView.setContentHuggingPriority(999, for: .horizontal)
        imageView.setContentHuggingPriority(999, for: .vertical)
        
        //Add pan gesture to slide the slider view
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.panGesture(_:)))
        addGestureRecognizer(pan)
        
        //Accessibility button
        if UIAccessibilityIsVoiceOverRunning() || UIAccessibilityIsSwitchControlRunning() {
            let accessibilityButton = UIButton(type: UIButtonType.system)
            accessibilityButton.backgroundColor = UIColor.clear
            accessibilityButton.isAccessibilityElement = true
            accessibilityButton.accessibilityLabel = self.accessibilityText
        
            let selector = #selector(didPressAccessibilityButton)
            accessibilityButton.addTarget(self, action: selector, for:.touchUpInside)
            
            self.addSubview(accessibilityButton)
            
            accessibilityButton.translatesAutoresizingMaskIntoConstraints = false
            
            let views = ["button": accessibilityButton, "view": self]
            
            let horizontallayoutContraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[button]-|", options: .alignAllCenterY, metrics: nil, views: views)
            let verticallayoutContraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[button]-|", options: .alignAllCenterX, metrics: nil, views: views)
            
            self.addConstraints(horizontallayoutContraints)
            self.addConstraints(verticallayoutContraints)
        }
    }
    
    //MARK: - Public Methods
    func reset() {
        progress = 0
        sliderWidthConstraint.constant = sliderWidth
        setNeedsUpdateConstraints()
        layoutIfNeeded()
    }
    
    func panGesture(_ recognizer:UIPanGestureRecognizer) {
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
                    self.didFinishSwipeSubject.onNext()
                } else {
                    self.didCancelSwipeSubject.onNext()
                }
            })
        default: break
        }
    }
    
    func didPressAccessibilityButton() {
        self.didFinishSwipeSubject.onNext()
    }
}

