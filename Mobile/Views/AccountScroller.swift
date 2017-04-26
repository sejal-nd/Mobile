//
//  AccountScroller.swift
//  Mobile
//
//  Created by Marc Shilling on 3/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

protocol AccountScrollerDelegate: class {
    func accountScroller(_ accountScroller: AccountScroller, didChangeAccount account: Account)
    func accountScrollerDidTap()
}

class AccountScroller: UIView {

    weak var delegate: AccountScrollerDelegate?

    var scrollView: UIScrollView!
    var pageControl: UIPageControl!

    var accounts = [Account]()
    var singleAccountNumberLabel: UILabel?
    var singleAccountAddressLabel: UILabel?

    var pageViews = [UIView]()
    
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
        pageControl.pageIndicatorTintColor = UIColor(red: 16/255, green: 56/255, blue: 112/255, alpha: 0.5)
        pageControl.currentPageIndicatorTintColor = UIColor(red: 16/255, green: 56/255, blue: 112/255, alpha: 1)
        pageControl.addTarget(self, action: #selector(onPageControlTap(sender:)), for: .valueChanged)
        addSubview(pageControl)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        scrollView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: 57)
        pageControl.frame = CGRect(x: frame.size.width / 2 - 80, y: 57, width: 160, height: 7)

        if pageViews.count > 0 {
            for index in 0..<pageViews.count {
                let pageView = pageViews[index]
                pageView.frame = CGRect(x: CGFloat(index) * frame.size.width, y: 0, width: frame.size.width, height: 57)
            }
            
            scrollView.contentSize = CGSize(width: frame.size.width * CGFloat(pageViews.count), height: 57)
            scrollView.scrollRectToVisible(pageViews[pageControl.currentPage].frame, animated: false)
        }

    }

    func setAccounts(_ accounts: [Account]) {
        self.accounts = accounts
        var pagedAccounts = accounts

        if self.accounts.count > 1 && self.accounts.count < 3 {
            pageControl.numberOfPages = pagedAccounts.count
            pageControl.currentPage = 0
        } else {
            pagedAccounts = Array(self.accounts.prefix(5))
            pageControl.isHidden = true
        }

        pageViews.removeAll()
        if self.accounts.count < 3 {
            for account in pagedAccounts {
                let pageView = UIView(frame: .zero)
                pageViews.append(pageView)
                
                let icon = account.accountType == .Commercial ? #imageLiteral(resourceName: "ic_commercial") : #imageLiteral(resourceName: "ic_residential")
                let iconImageView = UIImageView(image: icon)
                iconImageView.frame = CGRect(x: 0, y: 4, width: 43, height: 43)
                
                let accountNumberLabel = UILabel(frame: .zero)
                accountNumberLabel.translatesAutoresizingMaskIntoConstraints = false
                accountNumberLabel.font = UIFont.systemFont(ofSize: 17)
                accountNumberLabel.textColor = UIColor.darkJungleGreen
                accountNumberLabel.text = account.accountNumber
                
                let addressLabel = UILabel(frame: .zero)
                addressLabel.translatesAutoresizingMaskIntoConstraints = false
                addressLabel.font = UIFont.systemFont(ofSize: 12)
                addressLabel.textColor = UIColor.outerSpace
                addressLabel.text = account.address
                
                let accountView = UIView(frame: .zero)
                accountView.translatesAutoresizingMaskIntoConstraints = false
                accountView.addSubview(iconImageView)
                accountView.addSubview(accountNumberLabel)
                accountView.addSubview(addressLabel)
                
                pageView.addSubview(accountView)
                scrollView.addSubview(pageView)
                
                self.addConstraints([
                    // accountNumberLabel
                    NSLayoutConstraint(item: accountNumberLabel, attribute: .top, relatedBy: .equal, toItem: accountView, attribute: .top, multiplier: 1, constant: 11),
                    NSLayoutConstraint(item: accountNumberLabel, attribute: .leading, relatedBy: .equal, toItem: accountView, attribute: .leading, multiplier: 1, constant: 51),
                    NSLayoutConstraint(item: accountNumberLabel, attribute: .trailing, relatedBy: .equal, toItem: accountView, attribute: .trailing, multiplier: 1, constant: 0),
                    NSLayoutConstraint(item: accountNumberLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20),
                    
                    // addressLabel
                    NSLayoutConstraint(item: addressLabel, attribute: .top, relatedBy: .equal, toItem: accountView, attribute: .top, multiplier: 1, constant: 32),
                    NSLayoutConstraint(item: addressLabel, attribute: .leading, relatedBy: .equal, toItem: accountView, attribute: .leading, multiplier: 1, constant: 51),
                    NSLayoutConstraint(item: addressLabel, attribute: .trailing, relatedBy: .equal, toItem: accountView, attribute: .trailing, multiplier: 1, constant: 0),
                    NSLayoutConstraint(item: addressLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 14),
                    // TODO: REMOVE THIS CONSTRAINT TO NOT LIMIT ADDRESS LENGTH:
                    NSLayoutConstraint(item: addressLabel, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 150),
                    
                    // accountView
                    NSLayoutConstraint(item: accountView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 57),
                    NSLayoutConstraint(item: accountView, attribute: .centerX, relatedBy: .equal, toItem: pageView, attribute: .centerX, multiplier: 1, constant: 0),
                    NSLayoutConstraint(item: accountView, attribute: .centerY, relatedBy: .equal, toItem: pageView, attribute: .centerY, multiplier: 1, constant: 0)
                    ])
                
            }
        } else {
            let pageView = UIView(frame: .zero)
            pageViews.append(pageView)
            let icon = pagedAccounts[0].accountType == .Commercial ? #imageLiteral(resourceName: "ic_commercial") : #imageLiteral(resourceName: "ic_residential")
            let iconImageView = UIImageView(image: icon)
            iconImageView.frame = CGRect(x: 0, y: 4, width: 43, height: 43)
            
            let caret = #imageLiteral(resourceName: "ic_caret")
            let caretImageView = UIImageView(image: caret)
            caretImageView.frame = CGRect(x: 200, y:30, width: 8, height: 13)
            
            singleAccountNumberLabel = UILabel(frame: .zero)
            singleAccountNumberLabel!.translatesAutoresizingMaskIntoConstraints = false
            singleAccountNumberLabel!.font = UIFont.systemFont(ofSize: 17)
            singleAccountNumberLabel!.textColor = UIColor.darkJungleGreen
            singleAccountNumberLabel!.text = pagedAccounts[0].accountNumber
            
            singleAccountAddressLabel = UILabel(frame: .zero)
            singleAccountAddressLabel!.translatesAutoresizingMaskIntoConstraints = false
            singleAccountAddressLabel!.font = UIFont.systemFont(ofSize: 12)
            singleAccountAddressLabel!.textColor = UIColor.outerSpace
            singleAccountAddressLabel!.text = pagedAccounts[0].address
            
            let accountView = UIView(frame: .zero)
            accountView.translatesAutoresizingMaskIntoConstraints = false
            accountView.addSubview(iconImageView)
            accountView.addSubview(caretImageView)
            accountView.addSubview(singleAccountNumberLabel!)
            accountView.addSubview(singleAccountAddressLabel!)
            
            pageView.addSubview(accountView)
            scrollView.addSubview(pageView)
            
            self.addConstraints([
                // accountNumberLabel
                NSLayoutConstraint(item: singleAccountNumberLabel!, attribute: .top, relatedBy: .equal, toItem: accountView, attribute: .top, multiplier: 1, constant: 11),
                NSLayoutConstraint(item: singleAccountNumberLabel!, attribute: .leading, relatedBy: .equal, toItem: accountView, attribute: .leading, multiplier: 1, constant: 51),
                NSLayoutConstraint(item: singleAccountNumberLabel!, attribute: .trailing, relatedBy: .equal, toItem: accountView, attribute: .trailing, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: singleAccountNumberLabel!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20),
                
                // addressLabel
                NSLayoutConstraint(item: singleAccountAddressLabel!, attribute: .top, relatedBy: .equal, toItem: accountView, attribute: .top, multiplier: 1, constant: 32),
                NSLayoutConstraint(item: singleAccountAddressLabel!, attribute: .leading, relatedBy: .equal, toItem: accountView, attribute: .leading, multiplier: 1, constant: 51),
                NSLayoutConstraint(item: singleAccountAddressLabel!, attribute: .trailing, relatedBy: .equal, toItem: accountView, attribute: .trailing, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: singleAccountAddressLabel!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 14),
                // TODO: REMOVE THIS CONSTRAINT TO NOT LIMIT ADDRESS LENGTH:
                NSLayoutConstraint(item: singleAccountAddressLabel!, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 150),
                
                // accountView
                NSLayoutConstraint(item: accountView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 57),
                NSLayoutConstraint(item: accountView, attribute: .centerX, relatedBy: .equal, toItem: pageView, attribute: .centerX, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: accountView, attribute: .centerY, relatedBy: .equal, toItem: pageView, attribute: .centerY, multiplier: 1, constant: 0)
                ])

        }
        
        // Make a button overlay the scrollview if the user has more than 5 accounts.
        if self.accounts.count > 3 {
            let pageButton = UIButton(frame: scrollView.frame)
            pageButton.addTarget(self, action: #selector(showAccountList), for: .touchUpInside)
            addSubview(pageButton)
        }
        
        setNeedsLayout()
    }
    
    func showAccountList(sender: UIButton!) {
        delegate?.accountScrollerDidTap()
    }
    
    func onPageControlTap(sender: UIPageControl) {
        scrollView.scrollRectToVisible(CGRect(x: frame.size.width * CGFloat(pageControl.currentPage), y: 0, width: frame.size.width, height: 57), animated: true)
        delegate?.accountScroller(self, didChangeAccount: accounts[pageControl.currentPage])
    }
    
    func updateSingleAccount(account: Account) {
        singleAccountNumberLabel?.text = account.accountNumber
        singleAccountAddressLabel?.text = account.address
    }
    
}

extension AccountScroller: UIScrollViewDelegate {

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)

        if currentPage != pageControl.currentPage {
            pageControl.currentPage = currentPage
            delegate?.accountScroller(self, didChangeAccount: accounts[currentPage])
        }
    }

}
