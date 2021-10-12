//
//  ScheduleMoveServiceViewController.swift
//  EUMobile
//
//  Created by RAMAITHANI on 01/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import PDTSimpleCalendar

class ScheduleMoveServiceViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var currentServiceAddressLabel: UILabel!
    @IBOutlet weak var changeAccountButton: UIButton!
    @IBOutlet weak var serviceProviderStackView: UIStackView!
    @IBOutlet weak var stopDateButton: UIButton!
    @IBOutlet weak var stopDateSelectionView: UIView!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var electricStackView: UIStackView!
    @IBOutlet weak var gasStackView: UIStackView!
    @IBOutlet weak var stopDateToolTipButton: UIButton!
    @IBOutlet weak var dateStackView: UIStackView!
    @IBOutlet weak var selectedDateLabel: UILabel!
    @IBOutlet weak var stopDateLabel: UILabel!
    @IBOutlet weak var stopServiceAddressStaticLabel: UILabel!
    @IBOutlet weak var serviceProvidedStaticLabel: UILabel!
    @IBOutlet weak var serviceDisconnectStaticLabel: UILabel!

    var accounts: [Account] {
        get { return AccountsStore.shared.accounts ?? [] }
    }
    private var isMultiPremise: Bool {
        return accounts.contains { $0.isMultipremise }
    }
    var currentAccount: Account?
    var currentAccountDeatil: AccountDetail?
    var disposeBag = DisposeBag()
    let viewModel = ScheduleMoveServiceViewModel()
    var hasChangedData = false
    var isFirstLoad = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
       intialUIBiding()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if isFirstLoad {
            isFirstLoad = false
            viewModel.getAccountListSubject.onNext(())
        }
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func intialUIBiding() {
        
        addCloseButton()
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(image: UIImage(named: "ic_close"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(StopServiceViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton
        self.scrollView.isHidden = true
        
        stopServiceAddressStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        serviceProvidedStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        serviceDisconnectStaticLabel.font = SystemFont.regular.of(textStyle: .caption1)
        
        viewModel.showLoadingState
            .subscribe (onNext: { [weak self] status in
                self?.loadingIndicator.isHidden = !status
                self?.scrollView.isHidden = status
            }).disposed(by: disposeBag)

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
                calendarVC.calendar = .opCo
                calendarVC.delegate = self
                calendarVC.firstDate = Calendar.current.date(byAdding: .month, value: 0, to: Calendar.current.startOfDay(for: .now))
                calendarVC.lastDate = Calendar.current.date(byAdding: .month, value: 1, to: Calendar.current.startOfDay(for: .now))
                calendarVC.scroll(toSelectedDate: true)
                calendarVC.weekdayHeaderEnabled = true
                calendarVC.weekdayTextType = PDTSimpleCalendarViewWeekdayTextType.veryShort

                if let selectedDate = self.viewModel.selectedDate.value {
                    calendarVC.selectedDate = Calendar.opCo.startOfDay(for: selectedDate)
                }

                let navigationController = LargeTitleNavigationController(rootViewController: calendarVC)
                navigationController.setNavigationBarHidden(false, animated: false)
                calendarVC.navigationItem.title = "Select Stop Date"
                calendarVC.addCloseButton()
                calendarVC.navigationItem.largeTitleDisplayMode = .automatic
                navigationController.modalPresentationStyle = .fullScreen
                self.navigationController?.present(navigationController, animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        changeAccountButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                guard self.accounts.count > 1 || self.isMultiPremise,
                      let vc = UIStoryboard(name: "AccountSheet", bundle: .main).instantiateInitialViewController() as? AccountSheetViewController else { return }
                vc.delegate = self
                vc.hasCalledStopService = true
                vc.modalPresentationStyle = .overCurrentContext
                self.present(vc, animated: false, completion: nil)
            }).disposed(by: disposeBag)
        
        continueButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                
                guard let `self` = self else { return }
                guard let selectedDate = self.viewModel.selectedDate.value, let currentPremise = AccountsStore.shared.currentAccount.currentPremise, let accountDetails = self.currentAccountDeatil else { return }
                let moveFlowData = MoveServiceFlowData(workDays: self.viewModel.workDays.value, stopServiceDate: selectedDate, currentPremise: currentPremise, currentAccount: AccountsStore.shared.currentAccount, currentAccountDetail: accountDetails, verificationDetail: nil, addressLookupResponse: nil)
                
                let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
                let newServiceAddressViewController = storyboard.instantiateViewController(withIdentifier: "NewServiceAddressViewController") as! NewServiceAddressViewController
                newServiceAddressViewController.viewModel = NewServiceAddressViewModel(moveServiceFlowData: moveFlowData)
                self.navigationController?.pushViewController(newServiceAddressViewController, animated: true)

            }).disposed(by: disposeBag)
        
        // provides selected account details
        viewModel.accountDetailEvents
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] accountDetails in
                LoadingView.hide()
                self?.currentAccountDeatil = accountDetails
                self?.electricStackView.isHidden = !(accountDetails.serviceType?.contains("ELECTRIC") ?? false)
                self?.gasStackView.isHidden = !(accountDetails.serviceType?.contains("GAS") ?? false)
                self?.currentAccount = AccountsStore.shared.currentAccount
                if let currPremise = self?.currentAccount?.currentPremise, let address = currPremise.addressGeneral {
                    self?.currentServiceAddressLabel.text = address
                } else if let address = self?.currentAccount?.address {
                    self?.currentServiceAddressLabel.text = address
                } else {
                    self?.currentServiceAddressLabel.text = ""
                }

            })
            .disposed(by: disposeBag)
        
        viewModel.selectedDate
            .subscribe(onNext: { [weak self] date in
                let hasSelectedDate = date == nil ? false : true
                self?.dateStackView.isHidden = !hasSelectedDate
                self?.stopDateLabel.isHidden = hasSelectedDate
                
                self?.continueButton.isUserInteractionEnabled = hasSelectedDate
                self?.continueButton.backgroundColor = hasSelectedDate ? UIColor(red: 0, green: 89.0/255.0, blue: 164.0/255.0, alpha: 1.0) : UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0)
                self?.continueButton.setTitleColor(hasSelectedDate ? UIColor.white : UIColor(red: 74.0/255.0, green: 74.0/255.0, blue: 74.0/255.0, alpha: 0.5), for: .normal)

                if let selectedDate = date {
                    self?.selectedDateLabel.text = DateFormatter.MMddyyyyFormatter.string(from: selectedDate)
                }
            })
            .disposed(by: disposeBag)
    }
    
    @objc func back(sender: UIBarButtonItem) {
        // TODO: conditions to check for any change in the screen
        if hasChangedData {
            let exitAction = UIAlertAction(title: NSLocalizedString("Exit", comment: ""), style: .default)
            { [weak self] _ in
                guard let `self` = self else { return }
                self.dismiss(animated: true, completion: nil)
            }
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
            presentAlert(title: NSLocalizedString("Do you want to exit?", comment: ""),
                         message: NSLocalizedString("The information you’ve entered will not be saved.", comment: ""),
                         style: .alert,
                         actions: [cancelAction, exitAction])
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
}


// MARK: - PDTSimpleCalendarViewDelegate

extension ScheduleMoveServiceViewController: PDTSimpleCalendarViewDelegate {
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, isEnabledDate date: Date!) -> Bool {
        return self.viewModel.isValidDate(date)
    }
    
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, didSelect date: Date!) {
        hasChangedData = true
        self.viewModel.selectedDate.accept(date)
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - AccountSelectDelegate
extension ScheduleMoveServiceViewController: AccountSelectDelegate {
    
    internal func didSelectAccount(_ account: Account, premiseIndexPath: IndexPath?) {
        hasChangedData = true
        let selectedAccountIndex = accounts.firstIndex(of: account)
        
        // Set Selected Account
        AccountsStore.shared.currentIndex = selectedAccountIndex
        
        // Set Selected Premise
        if let selectedAccountIndex = selectedAccountIndex,
            let premiseIndexPath = premiseIndexPath {
            AccountsStore.shared.accounts[selectedAccountIndex].currentPremise = AccountsStore.shared.currentAccount.premises[premiseIndexPath.row]
        }
        viewModel.getAccountDetailSubject.onNext(())
        viewModel.selectedDate.accept(nil)
    }
}
