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
    @IBOutlet weak var xButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!

    var slides = Array<TutorialSlide>()
    
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

        slides.forEach {
            addViewFor(slide: $0)
        }
    }
    
    func setCurrentPage(_ page: Int) {
        pageControl.currentPage = page
        let lastPage = scrollView.currentPage == pageControl.numberOfPages - 1
        nextButton.setTitle(lastPage ? NSLocalizedString("Got It!", comment: "") : NSLocalizedString("Next", comment: ""), for: .normal)
    }
    
    @IBAction func onNext(_ sender: Any) {
        let pageCount = pageControl.numberOfPages
        let page = scrollView.currentPage
        
        if (page < pageCount-1) {
            UIView.animate(withDuration: 0.3) {
                self.scrollView.contentOffset.x = self.scrollView.frame.width
                * CGFloat(page+1)
            }
            setCurrentPage(page+1)
        } else {
            onClose(sender)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    func addSlide(title:String,
                      text:String,
                      animation:String) {
        slides.append(TutorialSlide(title: title,
                                    message: text,
                                    animation: animation))
    }
    
    func addViewFor(slide:TutorialSlide) {
        let viewCopy = TutorialView(frame: scrollView.frame,
                                    title: slide.title,
                                    message: slide.message,
                                    animation: slide.animation)
        pagerContent.addArrangedSubview(viewCopy)
        pageControl.numberOfPages = pagerContent.subviews.count
        viewCopy.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
    }
    
    override var prefersStatusBarHidden: Bool { return true }

    @IBAction func onClose(_ sender: Any) {
        presentingViewController?.dismiss(animated: true)
    }
}

class TutorialSlide {
    let title: String
    let message: String
    let animation: String
    
    init(title:String, message:String, animation: String) {
        self.title = title
        self.message = message
        self.animation = animation
    }
}

extension TutorialModalViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        setCurrentPage(scrollView.currentPage)
        pageControl.currentPage = scrollView.currentPage
    }
}

extension UIScrollView {
    var currentPage: Int {
        get { return Int(self.contentOffset.x) / Int(self.frame.width) }
        set {}
    }
}

