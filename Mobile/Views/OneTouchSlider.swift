//
//  OneTouchSlider.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 7/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

protocol oneTouchSliderDelegate: class {
    func didFinishSwipe(_ oneTouchSlider: OneTouchSlider)
    func didCancelSwipe(_ oneTouchSlider: OneTouchSlider)
    func sliderValueChanged(_ oneTouchSlider: OneTouchSlider)
}

class OneTouchSlider: UIControl {
    
    weak var delegate: oneTouchSliderDelegate?
    
    //MARK: - Private Variables
    private let slider:UIView = UIView()
    private let sliderFinish: UIView = UIView()
    private let sliderLabel: UILabel = UILabel()
    private var sliderWidthConstraint: NSLayoutConstraint!
    private var sliderFinishWidthConstraint: NSLayoutConstraint!
    private var shouldSlide: Bool = false
    private let imageView:UIImageView = UIImageView()
    
    //MARK: - Public Variables
    private(set) var progress: CGFloat = 0.0
    
    let sliderWidth: CGFloat = 40
    let sliderText = NSLocalizedString("Slide to pay now", comment: "")
    let commitToSwipe: CGFloat = 0.95 //swipe percentage point at which we commit to the swipe and call success
    
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
        sliderFinish.backgroundColor = .primaryColorADA
        sliderFinish.layer.masksToBounds = true
        addSubview(sliderFinish)
        sliderFinish.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        sliderFinish.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
        sliderFinish.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5).isActive = true
        sliderFinishWidthConstraint = sliderFinish.widthAnchor.constraint(equalToConstant: sliderWidth)
        sliderFinishWidthConstraint.isActive = true
        
        //Create Slider
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.backgroundColor = .white
        slider.layer.masksToBounds = true
        addSubview(slider)
        slider.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        slider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
        slider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5).isActive = true
        sliderWidthConstraint = slider.widthAnchor.constraint(equalToConstant: sliderWidth)
        sliderWidthConstraint.isActive = true
        
        //ImageView for caret
        imageView.translatesAutoresizingMaskIntoConstraints = false
        slider.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "ic_caret")
        imageView.centerYAnchor.constraint(equalTo: slider.centerYAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: slider.trailingAnchor, constant: -15).isActive = true
        imageView.setContentHuggingPriority(999, for: .horizontal)
        imageView.setContentHuggingPriority(999, for: .vertical)
        
        //Add pan gesture to slide the slider view
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.panGesture(_:)))
        addGestureRecognizer(pan)
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
            delegate?.sliderValueChanged(self)
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
                    self.delegate?.didFinishSwipe(self)
                } else {
                    self.delegate?.didCancelSwipe(self)
                }
            })
        default: break
        }
    }
}
