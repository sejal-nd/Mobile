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
import HorizonCalendar

class StopServiceViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
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
    @IBOutlet weak var dateStackView: UIStackView!
    @IBOutlet weak var selectedDateLabel: UILabel!
    @IBOutlet weak var stopDateLabel: UILabel!
    @IBOutlet weak var stopServiceAddressStaticLabel: UILabel!
    @IBOutlet weak var serviceProvidedStaticLabel: UILabel!
    @IBOutlet weak var serviceDisconnectStaticLabel: UILabel!
    @IBOutlet weak var pendingDisconnectStackView: UIStackView!
    @IBOutlet weak var pendingDisconnectView: PendingDisconnectView!
    @IBOutlet weak var finaledStackView: UIStackView!
    @IBOutlet weak var stopDateStackView: UIStackView!
    @IBOutlet weak var noneServiceProvideLabel: UILabel!
    
    var accounts: [Account] {
        get { return AccountsStore.shared.accounts ?? [] }
    }
    private var isMultiPremise: Bool {
        return accounts.contains { $0.isMultipremise }
    }
    var currentAccount: Account?
    var currentAccountDeatil: AccountDetail?
    var disposeBag = DisposeBag()
    let viewModel = StopServiceViewModel()
    var hasChangedData = false
    var isFirstLoad = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
       intialUIBiding()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        FirebaseUtility.logScreenView(.stopSelectStopDateView(className: self.className))
        if isFirstLoad {
            isFirstLoad = false
            fetchAccounts()
        }
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func intialUIBiding() {
        
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(image: UIImage(named: "ic_close"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(StopServiceViewController.back(sender:)))
        newBackButton.accessibilityLabel = "Close"
        self.navigationItem.leftBarButtonItem = newBackButton
        self.scrollView.isHidden = true
        
        stopServiceAddressStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        serviceProvidedStaticLabel.font = SystemFont.regular.of(textStyle: .footnote)
        serviceDisconnectStaticLabel.font = SystemFont.regular.of(textStyle: .caption1)

        
        viewModel.showLoadingState
            .observeOn(MainScheduler.instance)
            .subscribe (onNext: { [weak self] status in
                self?.loadingIndicator.isHidden = !status
                self?.scrollView.isHidden = status
            }).disposed(by: disposeBag)

        

        billAddressSegmentControl.items = [NSLocalizedString("Yes", comment: ""), NSLocalizedString("No", comment: "")]
        stopDateSelectionView.roundCorners(.allCorners, radius: 10.0, borderColor: UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0), borderWidth: 1.0)
        continueButton.roundCorners(.allCorners, radius: 27.5, borderColor: UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0), borderWidth: 1.0)
        
        // visible if more than 1 account or account has more than one premise
        changeAccountButton.isHidden = !(accounts.count > 1 || isMultiPremise)
        
        stopDateToolTipButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                let alertViewController = InfoAlertController(title: NSLocalizedString("Stop Service Date", comment: ""),
                                                              message: "Please select a date up to 30 days from now to stop your service, excluding holidays and Sundays.  \n\nConsider your moving date to make sure you have access to your utility service during your move.")
                self.present(alertViewController, animated: true)
            }).disposed(by: disposeBag)
        
        stopDateButton.rx.touchUpInside.asDriver()
            .drive(onNext: { [weak self] in
                FirebaseUtility.logEvent(.stopService(parameters: [.calendar]))
                guard let self = self else { return }
                self.view.endEditing(true)
                
                let calendarVC = CalendarViewController()
                calendarVC.calendar = .opCo
                calendarVC.delegate = self
                calendarVC.firstDate = Calendar.current.date(byAdding: .month, value: 0, to: Calendar.current.startOfDay(for: .now))
                calendarVC.lastDate = Calendar.current.date(byAdding: .month, value: 1, to: Calendar.current.startOfDay(for: .now))
//                calendarVC.scroll(toSelectedDate: true)
//                calendarVC.weekdayHeaderEnabled = true
//                calendarVC.weekdayTextType = PDTSimpleCalendarViewWeekdayTextType.veryShort

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
                
                guard let selectedDate = self.viewModel.selectedDate.value, let currentPremise = AccountsStore.shared.currentAccount.currentPremise, let accountDetails = self.currentAccountDeatil, let verificationDetail = self.viewModel.accountVerificationResponse.value else { return }
                let stopFlowData = StopServiceFlowData(workDays: self.viewModel.workDays.value, selectedDate: selectedDate, currentPremise: currentPremise, currentAccount: AccountsStore.shared.currentAccount, currentAccountDetail: accountDetails, hasCurrentServiceAddressForBill: self.billAddressSegmentControl.selectedIndex.value == 0, verificationDetail: verificationDetail)
                
                if self.billAddressSegmentControl.selectedIndex.value == 0 {
                    let storyboard = UIStoryboard(name: "ISUMStop", bundle: nil)
                    let reviewStopServiceViewController = storyboard.instantiateViewController(withIdentifier: "ReviewStopServiceViewController") as! ReviewStopServiceViewController
                    reviewStopServiceViewController.stopFlowData = stopFlowData
                    self.navigationController?.pushViewController(reviewStopServiceViewController, animated: true)
                } else {
                    let storyboard = UIStoryboard(name: "ISUMStop", bundle: nil)
                    let finalMailingAddressViewController = storyboard.instantiateViewController(withIdentifier: "FinalMailingAddressViewController") as! FinalMailingAddressViewController
                    finalMailingAddressViewController.stopFlowData = stopFlowData
                    self.navigationController?.pushViewController(finalMailingAddressViewController, animated: true)

                }
            }).disposed(by: disposeBag)
        
        viewModel.accountVerificationResponse
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] accountVerificationResponse in
                guard let date = accountVerificationResponse.serviceLists.first?.sAEndDate else { return }
                self?.pendingDisconnectView.updateServiceStopDate(dateString: date)
            })
            .disposed(by: disposeBag)
        
        viewModel.accountDetailEvents
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] accountDetails in
                guard let self = self else { return }
                LoadingView.hide()
                self.currentAccountDeatil = accountDetails
                self.electricStackView.isHidden = !(accountDetails.serviceType?.contains("ELECTRIC") ?? false)
                self.gasStackView.isHidden = !(accountDetails.serviceType?.contains("GAS") ?? false)
                self.noneServiceProvideLabel.isHidden = (accountDetails.serviceType?.contains("GAS") ?? false || accountDetails.serviceType?.contains("ELECTRIC") ?? false)
                self.finalBillStackView.isHidden = (accountDetails.isEBillEnrollment || accountDetails.isFinaled || accountDetails.isPendingDisconnect)
                self.stopDateStackView.isHidden = (accountDetails.isFinaled || accountDetails.isPendingDisconnect)
                self.currentAccount = AccountsStore.shared.currentAccount
                if let currPremise = self.currentAccount?.currentPremise, let address = currPremise.addressGeneral {
                    self.currentServiceAddressLabel.text = address.getValidISUMAddress()
                } else if let address = self.currentAccount?.address {
                    self.currentServiceAddressLabel.text = address.getValidISUMAddress()
                } else {
                    self.currentServiceAddressLabel.text = "No Address Available"
                }
                self.pendingDisconnectStackView.isHidden = !accountDetails.isPendingDisconnect
                self.finaledStackView.isHidden = !accountDetails.isFinaled
                
                if accountDetails.isFinaled {
                    FirebaseUtility.logEvent(.stopService(parameters: [.finaled]))
                }
                if accountDetails.isPendingDisconnect {
                    FirebaseUtility.logEvent(.stopService(parameters: [.pending_disconnect]))
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.selectedDate
            .subscribe(onNext: { [weak self] date in
                var hasSelectedDate = date == nil ? false : true
                self?.dateStackView.isHidden = !hasSelectedDate
                self?.stopDateLabel.isHidden = hasSelectedDate
                
                self?.continueButton.isUserInteractionEnabled = hasSelectedDate
                self?.continueButton.backgroundColor = hasSelectedDate ? UIColor(red: 0, green: 89.0/255.0, blue: 164.0/255.0, alpha: 1.0) : UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0)
                self?.continueButton.setTitleColor(hasSelectedDate ? UIColor.white : UIColor(red: 74.0/255.0, green: 74.0/255.0, blue: 74.0/255.0, alpha: 0.5), for: .normal)

                if let selectedDate = date {
                    self?.selectedDateLabel.text = DateFormatter.mmDdYyyyFormatter.string(from: selectedDate)
                    self?.stopDateButton.accessibilityLabel = "Stop Date, " + "\(selectedDate.weekday),  \(selectedDate.fullMonthDayAndYearString)"
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
                FirebaseUtility.logEvent(.stopService(parameters: [.exit]))
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
    
    private func fetchAccounts() {
        
        viewModel.getAccounts { [weak self] result in
            switch result {
            case .success: break
            case .failure:
                let exitAction = UIAlertAction(title: NSLocalizedString("Exit", comment: ""), style: .default)
                { [weak self] _ in
                    guard let `self` = self else { return }
                    self.dismiss(animated: true, completion: nil)
                }
                FirebaseUtility.logEvent(FirebaseEvent.stopService(parameters: [.api_error]))
                self?.loadingIndicator.isHidden = true
                DispatchQueue.main.async {
                    self?.presentAlert(title: NSLocalizedString("We're experiencing technical issues ", comment: ""),
                                       message: NSLocalizedString("We can't retrieve the data you requested. Please try again later. ", comment: ""),
                                       style: .alert,
                                       actions: [exitAction])
                }
            }
        }
    }
}

extension StopServiceViewController: AccountSelectDelegate {
    
    internal func didSelectAccount(_ account: Account, premiseIndexPath: IndexPath?) {
        FirebaseUtility.logEvent(.stopService(parameters: [.account_changed]))
        hasChangedData = true
        let selectedAccountIndex = accounts.firstIndex(of: account)
        
        // Set Selected Account
        AccountsStore.shared.currentIndex = selectedAccountIndex
        
        // Set Selected Premise
        if let selectedAccountIndex = selectedAccountIndex,
            let premiseIndexPath = premiseIndexPath {
            AccountsStore.shared.accounts[selectedAccountIndex].currentPremise = AccountsStore.shared.currentAccount.premises[premiseIndexPath.row]
        }
        fetchAccounts()
        viewModel.selectedDate.accept(nil)
    }
}

// MARK: - PDTSimpleCalendarViewDelegate

extension StopServiceViewController: PDTSimpleCalendarViewDelegate {
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, isEnabledDate date: Date!) -> Bool {
        return self.viewModel.isValidDate(date)
    }
    
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, didSelect date: Date!) {
        hasChangedData = true
        self.viewModel.selectedDate.accept(date)
        controller.dismiss(animated: true, completion: nil)
    }
}

extension StopServiceViewController: CalendarViewDelegate {
    func calendarViewController(_ controller: CalendarViewController, isDateEnabled date: Date) -> Bool {
        return self.viewModel.isValidDate(date)
    }
    
    func calendarViewController(_ controller: CalendarViewController, didSelectDate date: Date) {
        hasChangedData = true
        self.viewModel.selectedDate.accept(date)
        controller.dismiss(animated: true, completion: nil)
    }
}
