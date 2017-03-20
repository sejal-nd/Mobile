//
//  AccountScroller.swift
//  Mobile
//
//  Created by Marc Shilling on 3/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

protocol AccountScrollerDelegate: class {
    func accountScrollerDidChangeAccount(accountScroller: AccountScroller, account: Account)
}

class AccountScroller: UIView, UIScrollViewDelegate {
    
    weak var delegate: AccountScrollerDelegate?

    var scrollView: UIScrollView!
    var pageControl: UIPageControl!
    
    var accounts = [Account]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func commonInit() {
        backgroundColor = .clear
        
        scrollView = UIScrollView(frame: .zero)
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        addSubview(scrollView)
        
        pageControl = UIPageControl(frame: .zero)
        pageControl.addTarget(self, action: #selector(onPageControlTap(sender:)), for: .valueChanged)
        addSubview(pageControl)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        scrollView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: 57)
        pageControl.frame = CGRect(x: frame.size.width / 2 - 50, y: 57, width: 100, height: 7)
        pageControl.pageIndicatorTintColor = UIColor(red: 16/255, green: 56/255, blue: 112/255, alpha: 0.5)
        pageControl.currentPageIndicatorTintColor = UIColor(red: 16/255, green: 56/255, blue: 112/255, alpha: 1)
    }
    
    func setAccounts(_ accounts: [Account]) {
        self.accounts = accounts
        
        if self.accounts.count > 1 {
            pageControl.numberOfPages = self.accounts.count
            pageControl.currentPage = 0
        } else {
            pageControl.isHidden = true
        }
        
        for (index, account) in self.accounts.enumerated() {
            let pageView = UIView(frame: CGRect(x: CGFloat(index) * frame.size.width, y: 0, width: frame.size.width, height: 57))
            
            let icon = account.accountType == .Commercial ? #imageLiteral(resourceName: "ic_commercial") : #imageLiteral(resourceName: "ic_residential")
            let iconImageView = UIImageView(image: icon)
            iconImageView.frame = CGRect(x: center.x - 80, y: 4, width: 43, height: 43)

            let accountNumberLabel = UILabel(frame: CGRect(x: center.x - 30, y: 11, width: 100, height: 20))
            accountNumberLabel.font = UIFont.systemFont(ofSize: 17)
            accountNumberLabel.textColor = UIColor.darkJungleGreen
            accountNumberLabel.text = account.accountNumber
            
            let addressLabelWidth = UIScreen.main.bounds.width - (center.x - 30) - 16
            let addressLabel = UILabel(frame: CGRect(x: center.x - 30, y: 32, width: addressLabelWidth, height: 14))
            addressLabel.font = UIFont.systemFont(ofSize: 12)
            addressLabel.textColor = UIColor.outerSpace
            addressLabel.text = account.address
            
            pageView.addSubview(iconImageView)
            pageView.addSubview(accountNumberLabel)
            pageView.addSubview(addressLabel)
            scrollView.addSubview(pageView)
        }
        
        scrollView.contentSize = CGSize(width: frame.size.width * CGFloat(self.accounts.count), height: 57)
    }
    
    // MARK: - ScrollView Delegate
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        
        if currentPage != pageControl.currentPage {
            pageControl.currentPage = currentPage
            delegate?.accountScrollerDidChangeAccount(accountScroller: self, account: accounts[currentPage])
        }
    }
    
    func onPageControlTap(sender: UIPageControl) {
        scrollView.scrollRectToVisible(CGRect(x: frame.size.width * CGFloat(pageControl.currentPage), y: 0, width: frame.size.width, height: 57), animated: true)
        delegate?.accountScrollerDidChangeAccount(accountScroller: self, account: accounts[pageControl.currentPage])
    }
    
    

}
