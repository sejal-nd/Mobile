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
    @IBOutlet weak var stopDateStackView: UIStackView!
    @IBOutlet weak var pendingDisconnectStackView: UIStackView!
    @IBOutlet weak var finaledStackView: UIStackView!
    @IBOutlet weak var pendingDisconnectView: MovePendingDisconnectView!
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
    let viewModel = ScheduleMoveServiceViewModel()
    var hasChangedData = false
    var isFirstLoad = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
       intialUIBiding()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if viewModel.isUnauth {
            FirebaseUtility.logScreenView(.unauthMoveSelectStopDateView(className: self.className))
        } else {
            FirebaseUtility.logScreenView(.moveSelectStopDateView(className: self.className))
        }
        if isFirstLoad {
            isFirstLoad = false
            fetchAccounts()
        }
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func intialUIBiding() {

        let backButtonIconName = viewModel.isUnauth ? "ic_back" : "ic_close"
        let backButtonAccesibilityLabelText = viewModel.isUnauth ? "Close" : "Back"
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(image: UIImage(named: backButtonIconName), style: UIBarButtonItem.Style.plain, target: self, action: #selector(ScheduleMoveServiceViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton
        newBackButton.accessibilityLabel = backButtonAccesibilityLabelText
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
        
        if viewModel.isUnauth {
            changeAccountButton.isHidden = viewModel.isUnauth
        } else {
            changeAccountButton.isHidden = !(accounts.count > 1 || isMultiPremise)
        }
        
        stopDateToolTipButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                let alertViewController = InfoAlertController(title: NSLocalizedString("Stop Service Date", comment: ""),
                                                              message: "Please select a date up to 30 days from now to stop your service, excluding holidays and Sundays.\n\nConsider your moving date to make sure you have access to your utility service during your move.")
                self.present(alertViewController, animated: true)
            }).disposed(by: disposeBag)
        
        stopDateButton.rx.touchUpInside.asDriver()
            .drive(onNext: { [weak self] in
                self?.logMoveServiceEvent(parameters: [.calendar_stop_date])
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
                if let unauthMoveData = self.viewModel.unauthMoveData, unauthMoveData.isUnauthMove {
                    guard let selectedDate = self.viewModel.selectedDate.value else { return }
                    let moveFlowData = MoveServiceFlowData(workDays: self.viewModel.workDays.value, stopServiceDate: selectedDate, currentPremise: nil, currentAccount: nil, currentAccountDetail: nil, verificationDetail: self.viewModel.accountVerificationResponse.value, selected_appartment: nil, addressLookupResponse: nil, hasCurrentServiceAddressForBill: true, unauthMoveData: unauthMoveData)
                    
                    let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
                    let newServiceAddressViewController = storyboard.instantiateViewController(withIdentifier: "NewServiceAddressViewController") as! NewServiceAddressViewController
                    newServiceAddressViewController.viewModel = NewServiceAddressViewModel(moveServiceFlowData: moveFlowData)
                    self.navigationController?.pushViewController(newServiceAddressViewController, animated: true)

                } else {
                    guard let selectedDate = self.viewModel.selectedDate.value, let currentPremise = AccountsStore.shared.currentAccount.currentPremise, let accountDetails = self.currentAccountDeatil else { return }
                    let moveFlowData = MoveServiceFlowData(workDays: self.viewModel.workDays.value, stopServiceDate: selectedDate, currentPremise: currentPremise, currentAccount: AccountsStore.shared.currentAccount, currentAccountDetail: accountDetails, verificationDetail: self.viewModel.accountVerificationResponse.value, selected_appartment: nil, addressLookupResponse: nil, hasCurrentServiceAddressForBill: true)
                    
                    let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
                    let newServiceAddressViewController = storyboard.instantiateViewController(withIdentifier: "NewServiceAddressViewController") as! NewServiceAddressViewController
                    newServiceAddressViewController.viewModel = NewServiceAddressViewModel(moveServiceFlowData: moveFlowData)
                    self.navigationController?.pushViewController(newServiceAddressViewController, animated: true)
                }
            }).disposed(by: disposeBag)
        
        // provides selected account details
        viewModel.accountDetailEvents
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] accountDetails in
                LoadingView.hide()
                self?.currentAccountDeatil = accountDetails
                self?.electricStackView.isHidden = !(accountDetails.serviceType?.contains("ELECTRIC") ?? false)
                self?.gasStackView.isHidden = !(accountDetails.serviceType?.contains("GAS") ?? false)
                self?.noneServiceProvideLabel.isHidden = (accountDetails.serviceType?.contains("GAS") ?? false || accountDetails.serviceType?.contains("ELECTRIC") ?? false)
                self?.currentAccount = AccountsStore.shared.currentAccount
                if let currPremise = self?.currentAccount?.currentPremise, let address = currPremise.addressGeneral {
                    self?.currentServiceAddressLabel.text = address.getValidISUMAddress()
                } else if let address = self?.currentAccount?.address {
                    self?.currentServiceAddressLabel.text = address.getValidISUMAddress()
                } else {
                    self?.currentServiceAddressLabel.text = "No Address Available"
                }
                self?.pendingDisconnectStackView.isHidden = !accountDetails.isPendingDisconnect
                self?.finaledStackView.isHidden = !accountDetails.isFinaled
                self?.stopDateStackView.isHidden = (accountDetails.isFinaled || accountDetails.isPendingDisconnect)
                
                if accountDetails.isFinaled {
                    self?.logMoveServiceEvent(parameters: [.finaled])
                }
                if accountDetails.isPendingDisconnect {
                    self?.logMoveServiceEvent(parameters: [.pending_disconnect])
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.unauthAccountDetails
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] unauthAccountDetails in
                LoadingView.hide()
                self?.electricStackView.isHidden = !(unauthAccountDetails.serviceType.contains("ELECTRIC") )
                self?.gasStackView.isHidden = !(unauthAccountDetails.serviceType.contains("GAS") )
                self?.noneServiceProvideLabel.isHidden = (unauthAccountDetails.serviceType.contains("GAS") || unauthAccountDetails.serviceType.contains("ELECTRIC"))
                
                var address = ""
                if !unauthAccountDetails.addressLine.isEmpty  {
                    address += "\(unauthAccountDetails.addressLine), "
                }
                if !unauthAccountDetails.city.isEmpty {
                    address += "\(unauthAccountDetails.city), "
                }
                if !unauthAccountDetails.state.isEmpty {
                    address += "\(unauthAccountDetails.state)"
                }
                if !unauthAccountDetails.zipCode.isEmpty {
                    address += " \(unauthAccountDetails.zipCode)"
                }
                
                if address.isEmpty {
                    self?.currentServiceAddressLabel.text = "No Address Available"
                } else {
                    self?.currentServiceAddressLabel.text = address
                }
                self?.pendingDisconnectStackView.isHidden = true
                self?.finaledStackView.isHidden = !unauthAccountDetails.isFinaled
                self?.stopDateStackView.isHidden = unauthAccountDetails.isFinaled
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
                    self?.selectedDateLabel.text = DateFormatter.mmDdYyyyFormatter.string(from: selectedDate)
                    self?.stopDateButton.accessibilityLabel = "Stop Date, " + "\(selectedDate.weekday),  \(selectedDate.fullMonthDayAndYearString)"
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.accountVerificationResponse
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] accountVerificationResponse in
                guard let date = accountVerificationResponse.serviceLists.first?.sAEndDate else { return }
                self?.pendingDisconnectView.updateServiceStopDate(dateString: date)
            })
            .disposed(by: disposeBag)

        viewModel.apiError.asObservable()
            .subscribe ( onNext: { [weak self] _ in
                let exitAction = UIAlertAction(title: NSLocalizedString("Exit", comment: ""), style: .default)
                { [weak self] _ in
                    guard let `self` = self else { return }
                    self.dismiss(animated: true, completion: nil)
                }
                LoadingView.hide()
                self?.presentAlert(title: NSLocalizedString(NetworkingError.generic.title, comment: ""),
                                   message: NSLocalizedString(NetworkingError.generic.description, comment: ""),
                                   style: .alert,
                                   actions: [exitAction])
            }).disposed(by: disposeBag)
    }
    
    @objc func back(sender: UIBarButtonItem) {
        // TODO: conditions to check for any change in the screen
        if hasChangedData {
            let exitAction = UIAlertAction(title: NSLocalizedString("Exit", comment: ""), style: .default)
            { [weak self] _ in
                guard let `self` = self else { return }
                self.logMoveServiceEvent(parameters: [.exit])
                self.dismiss(animated: true, completion: nil)
            }
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
            presentAlert(title: NSLocalizedString("Do you want to exit?", comment: ""),
                         message: NSLocalizedString("The information you’ve entered will not be saved.", comment: ""),
                         style: .alert,
                         actions: [cancelAction, exitAction])
        } else {
            if self.viewModel.isUnauth {
                self.navigationController?.popViewController(animated: true)
            } else {
                dismiss(animated: true, completion: nil)
            }
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
    
    private func logMoveServiceEvent(parameters: [MoveServiceParameter]) {
        FirebaseUtility.logEvent(viewModel.isUnauth ? .unauthMoveService(parameters: parameters) : .authMoveService(parameters: parameters))
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
        self.logMoveServiceEvent(parameters: [.account_changed])
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
