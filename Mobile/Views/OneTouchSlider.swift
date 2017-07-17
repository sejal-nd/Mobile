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
    fileprivate let slider:UIView = UIView()
    fileprivate let sliderFinish: UIView = UIView()
    fileprivate let sliderLabel: UILabel = UILabel()
    fileprivate var sliderWidthConstraint: NSLayoutConstraint!
    fileprivate var sliderFinishWidthConstraint: NSLayoutConstraint!
    fileprivate var sliderImageWidthConstraint: NSLayoutConstraint!
    fileprivate var sliderImageHeightConstraint: NSLayoutConstraint!
    fileprivate var shouldSlide: Bool = false
    fileprivate let imageView:UIImageView = UIImageView()
    
    //MARK: - Public Variables
    fileprivate(set) var progress: Float = 0.0
    
    let sliderWidth = CGFloat(40)
    let sliderText = "Slide to pay now"
    let commitToSwipe: Float = 0.95 //swipe percentage point at which we commit to the swipe and call success
    
    //MARK: - UIControl
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupSlider()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupSlider()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = CGFloat(self.layer.frame.height / 2)
        self.sliderFinish.layer.cornerRadius = CGFloat(self.sliderFinish.layer.frame.height / 2)
        self.slider.layer.cornerRadius = CGFloat(self.slider.layer.frame.height / 2)
    }
    
    //MARK: - Private Methods
    fileprivate func addVisualConstraints(_ vertical:String, horizontal:String, view:UIView, toView:UIView) {
        let veritcalConstraints = NSLayoutConstraint.constraints(withVisualFormat: vertical, options: [], metrics: nil, views: ["view":view])
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: horizontal, options: [], metrics: nil, views: ["view":view])
        self.addConstraints(veritcalConstraints)
        self.addConstraints(horizontalConstraints)
    }
    
    fileprivate func setupSlider() {
        //Apply the custom slider styling
        self.layer.masksToBounds = true
        self.backgroundColor = .primaryColor
        
        //Add the slider label and set the constraints that will keep it centered
        self.sliderLabel.translatesAutoresizingMaskIntoConstraints = false
        self.sliderLabel.textAlignment = .center
        self.sliderLabel.font = OpenSans.semibold.of(textStyle: .headline)
        self.sliderLabel.setLineHeight(lineHeight: 16)
        self.sliderLabel.textColor = UIColor.white
        self.sliderLabel.text = self.sliderText
        self.addSubview(self.sliderLabel)
        self.addVisualConstraints("V:|[view]|", horizontal: "H:|[view]|", view: self.sliderLabel, toView: self)
        
        //Create SliderFinishView
        self.sliderFinish.translatesAutoresizingMaskIntoConstraints = false
        self.sliderFinish.backgroundColor = UIColor.primaryColorADA
        self.sliderFinish.layer.masksToBounds = true
        self.addSubview(self.sliderFinish)
        self.addVisualConstraints("V:|-5-[view]-5-|", horizontal: "H:[view]-5-|", view: self.sliderFinish, toView: self)
        self.sliderFinishWidthConstraint = NSLayoutConstraint(item: self.sliderFinish, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: self.sliderWidth)
        self.sliderFinish.addConstraint(self.sliderFinishWidthConstraint)
        
        //Create Slider
        self.slider.translatesAutoresizingMaskIntoConstraints = false
        self.slider.backgroundColor = UIColor.white
        self.slider.layer.masksToBounds = true
        self.addSubview(self.slider)
        self.addVisualConstraints("V:|-5-[view]-5-|", horizontal: "H:|-5-[view]", view: self.slider, toView: self)
        self.sliderWidthConstraint = NSLayoutConstraint(item: self.slider, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: self.sliderWidth)
        self.slider.addConstraint(self.sliderWidthConstraint)
        
        //ImageView for caret
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.slider.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.image = #imageLiteral(resourceName: "ic_caret")
        self.addVisualConstraints("V:|[view]|", horizontal: "H:[view]-15-|", view:self.imageView, toView: self.slider)
        self.sliderImageWidthConstraint = NSLayoutConstraint(item: self.imageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: CGFloat(8))
        self.sliderImageHeightConstraint = NSLayoutConstraint(item: self.imageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: CGFloat(13))
        self.imageView.addConstraint(self.sliderImageWidthConstraint)
        self.imageView.addConstraint(self.sliderImageHeightConstraint)
        
        //Add pan gesture to slide the slider view
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.panGesture(_:)))
        self.addGestureRecognizer(pan)
    }
    
    //MARK: - Public Methods
    open func reset() {
        self.progress = 0.0
        self.sliderWidthConstraint.constant = CGFloat(self.sliderWidth)
        self.setNeedsUpdateConstraints()
        self.layoutIfNeeded()
    }
    
    func panGesture(_ recognizer:UIPanGestureRecognizer) {
        let x = recognizer.location(in: self).x
        let padding: CGFloat = 20.0
        switch (recognizer.state) {
        case .began:
            //Only slide if the gestures starts within the slide frame
            self.shouldSlide = x > (self.sliderWidthConstraint.constant - CGFloat(self.sliderWidth)) && x < self.sliderWidthConstraint.constant + padding
            if shouldSlide {
                self.sliderLabel.fadeView(fadeAmount: 0.0, animationDuration: 0.2)
            }
        case .changed:
            guard self.shouldSlide && x > CGFloat(self.sliderWidth) && x <= self.bounds.size.width + padding else { return }
            self.sliderWidthConstraint.constant = x
            self.progress = Float(min(x/self.bounds.size.width, 1))
            self.delegate?.sliderValueChanged(self)
        case .ended:fallthrough
        case .cancelled:
            self.sliderLabel.fadeView(fadeAmount: 1.0) 
            guard self.shouldSlide else { return }
            self.shouldSlide = false
            
            self.progress = Float(x/self.bounds.size.width)
            let success: Bool
            let finalX: CGFloat
            
            //If we are past commit point and moving the the right direction
            if self.progress > self.commitToSwipe && recognizer.velocity(in: self).x > -1.0 {
                success = true
                finalX = self.bounds.size.width - 10
            } else {
                success = false
                finalX = CGFloat(self.sliderWidth)
                self.progress = 0.0
            }
            
            self.sliderWidthConstraint.constant = finalX
            self.setNeedsUpdateConstraints()
            
            UIView.animate(withDuration: 0.45,
                           delay: 0.0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: CGFloat(self.progress),
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
