//
// Created by James Landrum on 9/21/17.
// Copyright (c) 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class TutorialModalViewController: DismissableFormSheetViewController {
    @IBOutlet weak var pagerContent: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var xButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!

    let slides: [TutorialSlide]
    var slideViews = [TutorialView]()
    
    init(slides: [TutorialSlide]) {
        self.slides = slides
        super.init(nibName: "TutorialModal", bundle: nil)
        modalPresentationStyle = .formSheet // For iPad
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .primaryColor
        scrollView.delegate = self
        pageControl.pageIndicatorTintColor = .primaryColorDark
        pageControl.addTarget(self, action: #selector(onPageControlTap(sender:)), for: .valueChanged)
        
        xButton.accessibilityLabel = NSLocalizedString("Close", comment: "")
        nextButton.titleLabel?.font = SystemFont.bold.of(textStyle: .title1)
        
        slides.forEach(addViewFor)
        view.accessibilityElements = [xButton, pagerContent, pageControl, nextButton] as [UIView]
        pagerContent.accessibilityElements = [slideViews[0].titleText, slideViews[0].messageText] as [UIView]
    }
    
    func setCurrentPage(_ page: Int) {
        pageControl.currentPage = page
        let lastPage = scrollView.currentPage == pageControl.numberOfPages - 1
        nextButton.setTitle(lastPage ? NSLocalizedString("Got It", comment: "") : NSLocalizedString("Next", comment: ""), for: .normal)
        pagerContent.accessibilityElements = [slideViews[page].titleText, slideViews[page].messageText] as [UIView]
        UIAccessibility.post(notification: .screenChanged, argument: pagerContent)
    }
    
    @objc func onPageControlTap(sender: UIPageControl) {
        UIView.animate(withDuration: 0.3) {
            self.scrollView.contentOffset.x = self.scrollView.frame.width * CGFloat(sender.currentPage)
        }
        setCurrentPage(sender.currentPage)
    }
    
    @IBAction func onNext(_ sender: Any) {
        let pageCount = pageControl.numberOfPages
        let page = scrollView.currentPage
        
        if (page < pageCount - 1) {
            UIView.animate(withDuration: 0.3) {
                self.scrollView.contentOffset.x = self.scrollView.frame.width * CGFloat(page + 1)
            }
            setCurrentPage(page + 1)
        } else {
            onClose(sender)
        }
    }
    
    func addViewFor(slide: TutorialSlide) {
        let viewCopy = TutorialView(frame: scrollView.frame,
                                    title: slide.title,
                                    message: slide.message,
                                    animation: slide.animation)
        slideViews.append(viewCopy)
        pagerContent.addArrangedSubview(viewCopy)
        pageControl.numberOfPages = pagerContent.subviews.count
        viewCopy.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
    }
    
    override var prefersStatusBarHidden: Bool { return true }

    @IBAction func onClose(_ sender: Any) {
        presentingViewController?.dismiss(animated: true)
    }
    
}

struct TutorialSlide {
    let title: String
    let message: String
    let animation: String
}

extension TutorialModalViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        setCurrentPage(scrollView.currentPage)
        pageControl.currentPage = scrollView.currentPage
    }
}

extension UIScrollView {
    var currentPage: Int {
        return Int(self.contentOffset.x) / Int(self.frame.width)
    }
}

