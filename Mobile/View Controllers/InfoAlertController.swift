//
//  InfoAlertController.swift
//  Mobile
//
//  Created by Samuel Francis on 5/9/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

struct InfoAlertAction {
    let ctaText: String
    let callToAction: () -> ()
    
    init(ctaText: String, callToAction: @escaping () -> () = {}) {
        self.ctaText = ctaText
        self.callToAction = callToAction
    }
}

class InfoAlertController: UIViewController {
    private let alertContainerView = UIView().usingAutoLayout()
    private let iconImageView = UIImageView().usingAutoLayout()
    private let titleLabel = UILabel().usingAutoLayout()
    private let messageLabel = UILabel().usingAutoLayout()
    private let xButton = UIButton(type: .custom).usingAutoLayout()
    private var ctaButton: PrimaryButton?
    
    private let titleString: String
    private let message: String
    private let icon: UIImage?
    private let action: InfoAlertAction?
    
    init(title: String, message: String, icon: UIImage? = nil, action: InfoAlertAction? = nil) {
        self.titleString = title
        self.message = message
        self.icon = icon
        self.action = action
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }
    
    override func loadView() {
        super.loadView()
        buildLayout()
        styleViews()
        populateViews()
        setUpActions()
    }
    
    private func buildLayout() {
        var constraints = [NSLayoutConstraint]()
        
        let stackView = UIStackView().usingAutoLayout()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 20
        
        constraints += [
            // X Button
            xButton.topAnchor.constraint(equalTo: alertContainerView.topAnchor, constant: 15),
            xButton.leadingAnchor.constraint(equalTo: alertContainerView.leadingAnchor, constant: 15),
            // Stack View
            stackView.topAnchor.constraint(equalTo: xButton.bottomAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: alertContainerView.bottomAnchor, constant: -30),
            stackView.centerXAnchor.constraint(equalTo: alertContainerView.centerXAnchor),
            stackView.leadingAnchor.constraint(equalTo: alertContainerView.leadingAnchor, constant: 20),
            // Container (tablet width constraints added later)
            alertContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        
        if let icon = icon {
            iconImageView.image = icon
            stackView.addArrangedSubview(iconImageView)
            stackView.setCustomSpacing(12, after: iconImageView)
        }
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(messageLabel)
        
        if let _ = action {
            let ctaButton = PrimaryButton(frame: .zero).usingAutoLayout()
            
            stackView.addArrangedSubview(ctaButton)
            
            constraints += [
                ctaButton.heightAnchor.constraint(equalToConstant: 45),
                ctaButton.widthAnchor.constraint(equalToConstant: 215)
            ]
            
            self.ctaButton = ctaButton
        }
        
        alertContainerView.addSubview(xButton)
        alertContainerView.addSubview(stackView)
        
        view.addSubview(alertContainerView)
        alertContainerView.addTabletWidthConstraints(horizontalPadding: 31, padMaxWidth: true)
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func styleViews() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        alertContainerView.backgroundColor = .white
        alertContainerView.layer.cornerRadius = 10
        xButton.setImage(#imageLiteral(resourceName: "ic_close"), for: .normal)
        xButton.tintColor = .actionBlue
        titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        titleLabel.textColor = .deepGray
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        messageLabel.font = SystemFont.regular.of(textStyle: .footnote)
        messageLabel.textColor = .deepGray
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        
        ctaButton?.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
        ctaButton?.layer.cornerRadius = 22
    }
    
    private func populateViews() {
        titleLabel.text = titleString
        messageLabel.text = message
        if let action = action {
            ctaButton?.setTitle(action.ctaText, for: .normal)
        }
    }
    
    private func setUpActions() {
        xButton.addTarget(self, action: #selector(dismiss(_:)), for: .touchUpInside)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismiss(_:)))
        tapRecognizer.delegate = self
        view.addGestureRecognizer(tapRecognizer)
        ctaButton?.addTarget(self, action: #selector(callToAction(_:)), for: .touchUpInside)
    }
    
    @objc private func callToAction(_ ctaButton: PrimaryButton) {
        presentingViewController?.dismiss(animated: true, completion: action?.callToAction)
    }
    
    @objc private func dismiss(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension InfoAlertController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == gestureRecognizer.view
    }
}
