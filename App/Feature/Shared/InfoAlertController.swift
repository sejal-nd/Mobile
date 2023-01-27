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
    private var ctaButton: UIButton?
    
    private let titleString: String
    private let message: String?
    private let attributedMessage: NSAttributedString?
    private let icon: UIImage?
    private let action: InfoAlertAction?
    private let buttonType: ButtonType
    
    enum ButtonType: String {
        case primary
        case secondary
        case system
    }
    
    init(title: String, message: String, icon: UIImage? = nil, action: InfoAlertAction? = nil, buttonType: ButtonType = .primary) {
        self.titleString = title
        self.message = message
        self.attributedMessage = nil
        self.icon = icon
        self.action = action
        self.buttonType = buttonType
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }
    
    init(title: String, attributedMessage: NSAttributedString, icon: UIImage? = nil, action: InfoAlertAction? = nil) {
        self.titleString = title
        self.message = nil
        self.attributedMessage = attributedMessage
        self.icon = icon
        self.action = action
        self.buttonType = .primary
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
        xButton.accessibilityLabel = "Close"
        
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
            var ctaButton: UIButton
            
            if buttonType == .primary {
                ctaButton = PrimaryButton(frame: .zero).usingAutoLayout()
            } else if buttonType == .secondary {
                ctaButton = SecondaryButton(frame: .zero).usingAutoLayout()
            } else {
                ctaButton = UIButton(type: .system).usingAutoLayout()
            }
            
            stackView.addArrangedSubview(ctaButton)
            
            if buttonType != .system {
                constraints += [
                    ctaButton.heightAnchor.constraint(equalToConstant: 45),
                    ctaButton.widthAnchor.constraint(equalToConstant: 215)
                ]
            }
            
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
        xButton.tintColor = .actionBrand
        titleLabel.font = .headline
        titleLabel.textColor = .neutralDark
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        messageLabel.font = .footnote
        messageLabel.textColor = .neutralDark
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        
        if buttonType != .system {
            ctaButton?.titleLabel?.font = .headlineSemibold
            ctaButton?.layer.cornerRadius = 22
        } else {
            ctaButton?.setTitleColor(.actionBrand, for: .normal)
            ctaButton?.titleLabel?.font = .bodyBold
        }
    }
    
    private func populateViews() {
        titleLabel.text = titleString
        titleLabel.accessibilityLabel = titleString
        titleLabel.accessibilityTraits.insert(.header)
        
        if let message = self.message {
            messageLabel.text = message
            messageLabel.accessibilityLabel = message
        } else if let attributedMessage = self.attributedMessage {
            messageLabel.attributedText = attributedMessage
            messageLabel.accessibilityAttributedLabel = attributedMessage
        }
        
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
