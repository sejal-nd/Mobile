//
// Created by James Landrum on 9/21/17.
// Copyright (c) 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class TutorialModalViewController: DismissableFormSheetViewController {
    @IBOutlet weak var pagerContent: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var rootView: UIView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet var templateView: UIView!
    
    init() {
        super.init(nibName: "TutorialModal", bundle: nil)
        modalPresentationStyle = .formSheet // For iPad
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        rootView.backgroundColor = .primaryColor
        scrollView.delegate = self
        pageControl.pageIndicatorTintColor = .primaryColorDark
    }
    
    override func viewDidAppear(_ animated: Bool) {
        addSlide(title: "Set Up Default Payment Account",
                 text: "You can easily pay your bill in full from the Home " +
            "screen by setting a payment account as default.",
                 animation: "otp_step1")
        addSlide(title: "Tap On My Wallet",
                 text: "Navigate to the Bill screen and tap \"My Wallet.\" " +
            "You can also tap the \"Set a default payment account\" button " +
            "on Home.",
                 animation: "otp_step2")
        addSlide(title: "Turn On The Default Toggle",
                 text: "Create or edit a payment account and turn on the " +
                    "\"Default Payment Account\" toggle.",
                 animation: "otp_step3")
        addSlide(title: "Pay From The Home Screen!",
                 text: "You can now easily pay from the Home screen. This " +
            "type of payment cannot be canceled and will pay your account " +
            "balance in full.",
                 animation: "otp_step4")
    }

    func addSlide(title:String,
                 text:String,
                 animation:String) {
        let viewCopy = TutorialView(frame: scrollView.frame,
                                    title: title,
                                    message: text,
                                    animation: animation)
        pagerContent.addArrangedSubview(viewCopy.view)
        pageControl.numberOfPages = pagerContent.subviews.count
        viewCopy.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
    }

    @IBAction func xAction(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    @IBAction func onClose(_ sender: Any) {
        dismiss(animated: true)
    }
    
    deinit {
        dLog()
    }
}

extension TutorialModalViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        
        pageControl.currentPage = currentPage
    }
    
}

