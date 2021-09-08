//
//  StopServiceViewController.swift
//  EUMobile
//
//  Created by RAMAITHANI on 02/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import PDTSimpleCalendar

class StopServiceViewController: UIViewController {

    @IBOutlet weak var currentServiceAddressLabel: UILabel!
    @IBOutlet weak var changeAccountButton: UIButton!
    @IBOutlet weak var serviceProviderStackView: UIStackView!
    @IBOutlet weak var stopDateButton: UIButton!
    @IBOutlet weak var stopDateSelectionView: UIView!
    @IBOutlet weak var billAddressSegmentControl: SegmentedControl!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var electricStackView: UIStackView!
    @IBOutlet weak var gasStackView: UIStackView!
    @IBOutlet weak var stopDateToolTipButton: UIButton!
    @IBOutlet weak var finalBillStackView: UIStackView!

    var accounts: [Account] {
        get { return AccountsStore.shared.accounts ?? [] }
    }
    private var isMultiPremise: Bool {
        return accounts.contains { $0.isMultipremise }
    }
    var currentAccount: Account?
    var disposeBag = DisposeBag()
    let viewModel = StopServiceViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
       intialUIBiding()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        viewModel.getAccountDetailSubject.onNext(())
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func intialUIBiding() {
        
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(image: UIImage(named: "ic_back"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(StopServiceViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton
        
        billAddressSegmentControl.items = [NSLocalizedString("Yes", comment: ""), NSLocalizedString("No", comment: "")]
        stopDateSelectionView.roundCorners(.allCorners, radius: 10.0, borderColor: UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0), borderWidth: 1.0)
        continueButton.roundCorners(.allCorners, radius: 27.5, borderColor: UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0), borderWidth: 1.0)
        
        // visible if more than 1 account or account has more than one premise
        changeAccountButton.isHidden = !(accounts.count > 1 || isMultiPremise)
        
        stopDateToolTipButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                let alertViewController = InfoAlertController(title: NSLocalizedString("Stop Service Date", comment: ""),
                                                              message: "You must select an effective stop service date within 30 days from the day you submit your request, excluding holidays and Sundays.")
                self.present(alertViewController, animated: true)
            }).disposed(by: disposeBag)
        
        stopDateButton.rx.touchUpInside.asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.view.endEditing(true)
                
                let calendarVC = PDTSimpleCalendarViewController()
                calendarVC.extendedLayoutIncludesOpaqueBars = true
                calendarVC.calendar = .opCo
                calendarVC.delegate = self
                calendarVC.title = NSLocalizedString("Select Payment Date", comment: "")
                calendarVC.firstDate = Calendar.current.date(byAdding: .year, value: -10, to: Calendar.current.startOfDay(for: .now))
                calendarVC.lastDate = Calendar.current.date(byAdding: .year, value: 10, to: Calendar.current.startOfDay(for: .now))
                calendarVC.selectedDate = Calendar.opCo.startOfDay(for: .now)
                calendarVC.scroll(toSelectedDate: true)
                
                self.present(calendarVC, animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        changeAccountButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                guard self.accounts.count > 1 || self.isMultiPremise,
                      let vc = UIStoryboard(name: "AccountSheet", bundle: .main).instantiateInitialViewController() as? AccountSheetViewController else { return }
                vc.delegate = self
                vc.modalPresentationStyle = .overCurrentContext
                self.present(vc, animated: false, completion: nil)
            }).disposed(by: disposeBag)
        
        // provides selected account details
        viewModel.accountDetailEvents
            .subscribe(onNext: { [weak self] result in
                guard let accountDetails = result.element else { return }
                LoadingView.hide()
                self?.currentServiceAddressLabel.text = accountDetails.address
                self?.electricStackView.isHidden = !(accountDetails.serviceType?.contains("ELECTRIC") ?? false)
                self?.gasStackView.isHidden = !(accountDetails.serviceType?.contains("GAS") ?? false)
                self?.finalBillStackView.isHidden = accountDetails.isEBillEnrollment
            })
            .disposed(by: disposeBag)
        
        viewModel.didSelectDate
            .subscribe(onNext: { [weak self] result in
                self?.continueButton.isUserInteractionEnabled = true
                self?.continueButton.backgroundColor = UIColor(red: 0, green: 89.0/255.0, blue: 164.0/255.0, alpha: 1.0)
                self?.continueButton.setTitleColor(UIColor.white, for: .normal)
            })
            .disposed(by: disposeBag)
    }
    
    @objc func back(sender: UIBarButtonItem) {
        // TODO: conditions to check for any change in the screen
        self.navigationController?.popViewController(animated: true)
    }
}

extension StopServiceViewController: AccountSelectDelegate {
    
    internal func didSelectAccount(_ account: Account, premiseIndexPath: IndexPath?) {
        let selectedAccountIndex = accounts.firstIndex(of: account)
        
        // Set Selected Account
        AccountsStore.shared.currentIndex = selectedAccountIndex
        
        // Set Selected Premise
        if let selectedAccountIndex = selectedAccountIndex,
            let premiseIndexPath = premiseIndexPath {
            AccountsStore.shared.accounts[selectedAccountIndex].currentPremise = AccountsStore.shared.currentAccount.premises[premiseIndexPath.row]
        }
        viewModel.getAccountDetailSubject.onNext(())
    }
}

// MARK: - PDTSimpleCalendarViewDelegate

extension StopServiceViewController: PDTSimpleCalendarViewDelegate {
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, isEnabledDate date: Date!) -> Bool {
        return true
    }
    
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, didSelect date: Date!) {
        self.viewModel.didSelectDate.onNext(())
        controller.dismiss(animated: true, completion: nil)
    }
}
