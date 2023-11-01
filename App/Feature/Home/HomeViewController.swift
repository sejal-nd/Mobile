//
//  HomeViewController.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 7/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt
import Lottie
import UserNotifications
import SafariServices
import UIKit
import SwiftUI

fileprivate let editHomeSegueId = "editHomeSegue"
fileprivate let colorBackgroundViewHeight: CGFloat = 446

class HomeViewController: AccountPickerViewController {
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var colorBackgroundView: UIView!
    @IBOutlet weak var colorBackgroundHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var noNetworkConnectionView: NoNetworkConnectionView!
    @IBOutlet weak var accountDisallowView: UIView!
    @IBOutlet weak var maintenanceModeView: MaintenanceModeView!
    
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var cardStackView: UIStackView!
    
    @IBOutlet weak var personalizeButton: UIButton!
    
    var termsAndConditionsButton: UIButton!

    var discoverCardView: HomeDiscoverCardView!
    var importantUpdateView: HomeUpdateView?
    var gameOnboardingCardView: HomeGameOnboardingCardView?
    var appointmentCardView: HomeAppointmentCardView?
    var prepaidPendingCardView: HomePrepaidCardView?
    var prepaidActiveCardView: HomePrepaidCardView?
    var billCardView: HomeBillCardView?
    var usageCardView: HomeUsageCardView?
    var projectedBillCardView: HomeProjectedBillCardView?
    var outageCardView: HomeOutageCardView?
    var topPersonalizeButton: ConversationalButton?
    
    var gameCardView: HomeGameCardView?
    
    var refreshDisposable: Disposable?
    var refreshControl: UIRefreshControl?
    
    var alertLottieAnimation = LottieAnimationView(animation: .named("alert_icon"))
    
    let viewModel = HomeViewModel()
    
    override var defaultStatusBarStyle: UIStatusBarStyle { return .darkContent }
    
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.backgroundImageDriver.drive(backgroundImageView.rx.image).disposed(by: bag)
        viewModel.greetingDriver.drive(greetingLabel.rx.text).disposed(by: bag)
        viewModel.greetingDateDriver.drive(dateLabel.rx.text).disposed(by: bag)
        colorBackgroundHeightConstraint.constant = colorBackgroundViewHeight
        
        accountPicker.delegate = self
        accountPicker.parentViewController = self
                
        setRefreshControlEnabled(enabled: false)
        
        viewModel.accountDetailEvents.elements()
            .take(1)
            .subscribe(onNext: { accountDetail in
                let residentialAMIString = String(format: "%@%@", accountDetail.isResidential ? "Residential/" : "Commercial/", accountDetail.isAMIAccount ? "AMI" : "Non-AMI")
                
                let isPeakSmart = (Configuration.shared.opco == .bge && accountDetail.isSERAccount) ||
                    (Configuration.shared.opco != .bge && accountDetail.isPTSAccount)
            })
            .disposed(by: bag)
        
        viewModel.showPhoneNumberPrompt
            .subscribe(onNext: { showPhoneNumberPrompt in
                if showPhoneNumberPrompt {
                    self.showPhoneNumberAlert()
                }
            }).disposed(by: bag)
        
        viewSetup()
        styleViews()
        bindLoadingStates()
        
        NotificationCenter.default.rx.notification(.didMaintenanceModeTurnOn)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] _ in
                self?.refreshControl?.endRefreshing()
                self?.scrollView!.alwaysBounceVertical = true
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(.didMaintenanceModeTurnOff)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] _ in
                self?.viewModel.fetchData.onNext(())
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(.didSelectEnrollInAutoPay, object: nil)
        .subscribe(onNext: { [weak self] notification in
            guard let self = self else { return }
            if let accountDetail = notification.object as? AccountDetail {
                self.navigateToAutoPay(accountDetail: accountDetail)
            }
        }).disposed(by: bag)
        
        NotificationCenter.default.rx.notification(.didRecievePaymentConfirmation, object: nil)
            .subscribe(onNext: { [weak self] notification in
                guard let self = self else { return }
                self.viewModel.fetchData.onNext(())
            }).disposed(by: bag)
    }
    
    func viewSetup() {
        // Observe selected card list
        viewModel.cardPreferenceChanges
            .drive(onNext: { [weak self] (oldCards, newCards) in
                guard let self = self else { return }
                self.scrollView?.setContentOffset(.zero, animated: false)
                
                // Perform reorder if preference changed
                guard oldCards != newCards else { return }
                self.setCards(oldCards: oldCards, newCards: newCards)
                
                // Refresh if new card(s) added
                if !Set(newCards).subtracting(oldCards).isEmpty {
                    self.viewModel.fetchData.onNext(())
                }
            })
            .disposed(by: bag)

        if Configuration.shared.opco.isPHI {
            // Add a terms & conditions Button at the end of the stack for PHI ocpos
            termsAndConditionsButton = UIButton()
            termsAndConditionsButton.setTitle("Policies & Terms", for: .normal)
            termsAndConditionsButton.setTitleColor(.actionBrand, for: .normal)
            termsAndConditionsButton.titleLabel?.font = .subheadlineSemibold
            termsAndConditionsButton.rx.tap.asDriver()
                .drive(onNext: { [weak self] in
                    self?.onTermsAndPolicyPress()
                }).disposed(by: bag)
            contentStackView.insertArrangedSubview(termsAndConditionsButton, at: contentStackView.subviews.count)
        }
        
        // Top personalize button logic
        let versionString = UserDefaults.standard.string(forKey: UserDefaultKeys.homeCardCustomizeTappedVersion) ?? "0.0.0"
        let tappedVersion = Version(string: versionString) ?? Version(major: 0, minor: 0, patch: 0)
        if tappedVersion < viewModel.latestNewCardVersion {
            topPersonalizeButtonSetup()
        }
        
        // Appointment Card
        viewModel.showAppointmentCard
            .distinctUntilChanged()
            .drive(onNext: { [weak self] showAppointmentCard in
                guard let self = self else { return }
                
                guard showAppointmentCard else {
                    self.appointmentCardView?.removeFromSuperview()
                    self.appointmentCardView = nil
                    return
                }
                
                let appointmentCardView = HomeAppointmentCardView
                    .create(withViewModel: self.viewModel.appointmentCardViewModel)
                
                appointmentCardView.bottomButton.rx.touchUpInside.asObservable()
                    .withLatestFrom(Observable.combineLatest(self.viewModel.appointmentCardViewModel.appointments,
                                                             self.viewModel.accountDetailEvents.elements()))
                    .asDriver(onErrorDriveWith: .empty())
                    .drive(onNext: { [weak self] appointments, accountDetail in
                        guard let self = self else { return }
                        let appointment = appointments[0]
                        
                        let status: Appointment.Status
                        if appointments.count > 1 {
                            status = .scheduled
                        } else if let unwrappedStatus = Appointment.Status(rawValue: appointment.status) {
                            status = unwrappedStatus
                        } else {
                            status = .canceled
                        }
                        
                        switch status {
                        case .scheduled, .inProgress, .onOurWay, .enRoute:
                            self.performSegue(withIdentifier: "appointmentDetailSegue",
                                              sender: (appointments))
                        case .canceled, .complete:
                            UIApplication.shared.openPhoneNumberIfCan(self.viewModel.appointmentCardViewModel.contactNumber)
                        case .none:
                            return
                        }
                    })
                    .disposed(by: appointmentCardView.disposeBag)
                
                let index = self.topPersonalizeButton != nil ? 1 : 0
                self.contentStackView.insertArrangedSubview(appointmentCardView, at: index)
                self.appointmentCardView = appointmentCardView
            })
            .disposed(by: bag)
        
        if Configuration.shared.opco == .bge && FeatureFlagUtility.shared.bool(forKey: .isGamificationEnabled) {
            viewModel.gameUser.asDriver().drive(onNext: {
                if let gameUser = $0 {
                    self.gameCardView?.isHidden = !gameUser.onboardingComplete
                } else {
                    self.gameCardView?.removeFromSuperview()
                    self.gameCardView = nil
                }
            }).disposed(by: bag)
            
            viewModel.accountDetailEvents.elements().asObservable()
                .subscribe(onNext: {
                    self.viewModel.gameCardViewModel.accountDetail.accept($0)
                    self.viewModel.gameCardViewModel.fetchData()
                })
                .disposed(by: bag)
            
            viewModel.showGameOnboardingCard
                .distinctUntilChanged()
                .drive(onNext: { [weak self] showCard in
                    guard let self = self else { return }
                    
                    guard showCard else {
                        self.gameOnboardingCardView?.removeFromSuperview()
                        self.gameOnboardingCardView = nil
                        return
                    }
                    
                    let gameOnboardingCardView = HomeGameOnboardingCardView.create()
                    
                    gameOnboardingCardView.letsGoButton.rx.touchUpInside.asDriver()
                        .withLatestFrom(self.viewModel.accountDetailEvents.elements().asDriver(onErrorDriveWith: .empty()))
                        .drive(onNext: { [weak self] in
                            guard let self = self else { return }
                            self.navigateToGameOnboarding(accountDetail: $0)
                            FirebaseUtility.logEvent(.gamification(parameters: [.onboard_start, .onboarding_card_version(gameOnboardingCardView.version.rawValue)]))
                        }).disposed(by: self.bag)
                    
                    gameOnboardingCardView.imageButton.rx.touchUpInside.asDriver()
                        .withLatestFrom(self.viewModel.accountDetailEvents.elements().asDriver(onErrorDriveWith: .empty()))
                        .drive(onNext: { [weak self] in
                            guard let self = self else { return }
                            self.navigateToGameOnboarding(accountDetail: $0)
                            FirebaseUtility.logEvent(.gamification(parameters: [.onboard_start, .onboarding_card_version(gameOnboardingCardView.version.rawValue)]))
                        }).disposed(by: self.bag)
                    
                    let index = self.topPersonalizeButton != nil ? 1 : 0
                    self.contentStackView.insertArrangedSubview(gameOnboardingCardView, at: index)
                    self.gameOnboardingCardView = gameOnboardingCardView
                })
                .disposed(by: bag)
        }
        
        // If no update, show personalize button at the top.
        // Hide the update view.
        viewModel.importantUpdate
            .filter { $0 == nil }
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.topPersonalizeButton?.isHidden = false
                self.importantUpdateView?.removeFromSuperview()
                self.importantUpdateView = nil
            })
            .disposed(by: bag)
        
        // If update, show the update view.
        // Hide personalize button at the top.
        // For PHI the update view will come at the second position for other EU apps it will be at the top most position after account picker
        viewModel.importantUpdate
            .filter { $0 != nil }
            .drive(onNext: { [weak self] update in
                guard let self = self, let update = update else { return }
                self.topPersonalizeButton?.isHidden = true
                
                if let importantUpdateView = self.importantUpdateView {
                    importantUpdateView.configure(withUpdate: update)
                } else {
                    let importantUpdateView = HomeUpdateView.create(withUpdate: update)
                    self.contentStackView.insertArrangedSubview(importantUpdateView, at: 0)
//                    importantUpdateView.addTabletWidthConstraints(horizontalPadding: 16)
                    importantUpdateView.button.rx.touchUpInside.asDriver()
                        .drive(onNext: { [weak self] in
                            self?.navigationController?.pushViewController(OpcoUpdatesHostingController(rootView: OpcoUpdateDetailView(update: update), shouldShowLargeTitle: false), animated: true)
                        })
                        .disposed(by: importantUpdateView.disposeBag)
                    
                    self.importantUpdateView = importantUpdateView
                }
            })
            .disposed(by: bag)
        
        // Bottom personalize button setup
        personalizeButton.setTitleColor(.actionBrand, for: .normal)
        personalizeButton.titleLabel?.font = .subheadlineSemibold
        personalizeButton.isAccessibilityElement = true
        personalizeButton.accessibilityLabel = personalizeButton.currentTitle
        personalizeButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                guard let this = self else { return }
                UserDefaults.standard.set(Version.current.string, forKey: UserDefaultKeys.homeCardCustomizeTappedVersion)
                this.performSegue(withIdentifier: editHomeSegueId, sender: nil)
                
                FirebaseUtility.logEvent(.home(parameters: [.personalize_button]))
                
                guard let button = this.topPersonalizeButton else { return }
                UIView.animate(withDuration: 0.15, animations: {
                    button.isHidden = true
                }, completion: { _ in
                    this.cardStackView.removeArrangedSubview(button)
                    button.removeFromSuperview()
                    this.topPersonalizeButton = nil
                })
            })
            .disposed(by: bag)
    }
    
    func navigateToGameOnboarding(accountDetail: AccountDetail) {
        let sb = UIStoryboard(name: "Game", bundle: nil)
        if let navController = sb.instantiateViewController(withIdentifier: "GameOnboarding") as? UINavigationController,
           let vc = navController.viewControllers.first as? GameOnboardingIntroViewController {
            vc.accountDetail = accountDetail
            self.present(navController, animated: true, completion: nil)
        }
    }
    
    func navigateToAutoPay(accountDetail: AccountDetail) {
        if Configuration.shared.opco == .bge || Configuration.shared.opco.isPHI  {
            if accountDetail.isBGEasy {
                let storyboard = UIStoryboard(name: "Bill", bundle: Bundle.main)
                if let bgeEasyViewController = storyboard.instantiateViewController(withIdentifier: "BGEasy") as?  BGEasyViewController {
                    present(bgeEasyViewController, animated: true, completion: nil)
                }
            } else {
                let storyboard = UIStoryboard(name: "AutoPayBGE", bundle: Bundle.main)
                if let bgeAutoPayViewController = storyboard.instantiateViewController(withIdentifier: "BGEAutoPay") as?  BGEAutoPayViewController {
                    bgeAutoPayViewController.delegate = self
                    bgeAutoPayViewController.accountDetail = accountDetail
                    navigationController?.pushViewController(bgeAutoPayViewController, animated: true)
                }
            }
        } else {
            let storyboard = UIStoryboard(name: "AutoPay", bundle: Bundle.main)
            if let autoPayViewController = storyboard.instantiateViewController(withIdentifier: "AutoPay") as?  AutoPayViewController {
                autoPayViewController.delegate = self
                autoPayViewController.accountDetail = accountDetail
                navigationController?.pushViewController(autoPayViewController, animated: true)
            }
        }
    }
    
    private func onTermsAndPolicyPress() {
        let moreStoryboard = UIStoryboard(name: "More", bundle: Bundle.main)
        let termsAndPoliciesViewController = moreStoryboard.instantiateViewController(withIdentifier: "TermsPoliciesViewController")
        navigationController?.pushViewController(termsAndPoliciesViewController, animated: true)
    }
    
    @IBAction func tempPresentAccount(_ sender: Any) {
        guard let vc = UIStoryboard(name: "AccountSheet", bundle: .main).instantiateInitialViewController() else { return }
        vc.modalPresentationStyle = .overCurrentContext
        tabBarController?.present(vc, animated: false, completion: nil)
    }
    
    func topPersonalizeButtonSetup() {
        let topPersonalizeButton = ConversationalButton()
        
        contentStackView.insertArrangedSubview(topPersonalizeButton, at: 0)
        
        topPersonalizeButton.titleText = NSLocalizedString("Did you know you can personalize your home screen?", comment: "")
        
        topPersonalizeButton.rx.touchUpInside.asDriver()
            .drive(onNext: { [weak self, weak topPersonalizeButton] in
                guard let this = self, let button = topPersonalizeButton else { return }
                UserDefaults.standard.set(Version.current.string, forKey: UserDefaultKeys.homeCardCustomizeTappedVersion)
                this.performSegue(withIdentifier: editHomeSegueId, sender: nil)
                
                FirebaseUtility.logEvent(.home(parameters: [.personalize_banner]))
                
                UIView.animate(withDuration: 0.15, animations: {
                    button.isHidden = true
                }, completion: { _ in
                    this.cardStackView.removeArrangedSubview(button)
                    button.removeFromSuperview()
                    this.topPersonalizeButton = nil
                })
            })
            .disposed(by: bag)
        
        self.topPersonalizeButton = topPersonalizeButton
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Artificial screen event due to automatic screen tracking not counting the initial load of this screen...
        FirebaseUtility.logEvent(.home(parameters: [.view_screen]))
        FirebaseUtility.logScreenView(.homeView(className: self.className))

        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        AppRating.present()
        
        if Configuration.shared.environmentName != .aut {
            let authOptions: UNAuthorizationOptions
            if #available(iOS 12.0, *) {
                authOptions = [.badge, .alert, .sound, .providesAppNotificationSettings]
            } else {
                authOptions = [.badge, .alert, .sound]
            }
            
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: { (granted: Bool, error: Error?) in
                if !UserDefaults.standard.bool(forKey: UserDefaultKeys.isInitialPushNotificationPermissionsWorkflowCompleted) {
                    UserDefaults.standard.set(true, forKey: UserDefaultKeys.isInitialPushNotificationPermissionsWorkflowCompleted)
                }
            })
            
            UIApplication.shared.registerForRemoteNotifications()
        }
        
        if let editAction = RxNotifications.shared.profileEditAction.value {
            if editAction == "PasswordUpdate" {
                self.view.showToast("Password changed")
                RxNotifications.shared.profileEditAction.accept(nil)
            }
        } else if RxNotifications.shared.mfaBypass.value {
            self.showMFAReminder()
            RxNotifications.shared.mfaBypass.accept(false)
        } else if RxNotifications.shared.mfaJustEnabled.value {
            self.showMFAJustEnabled()
            RxNotifications.shared.mfaJustEnabled.accept(false)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        usageCardView?.superviewDidLayoutSubviews()
        billCardView?.superviewDidLayoutSubviews()
    }
    
    func styleViews() {
        view.backgroundColor = .neutralLightest
        colorBackgroundView.backgroundColor = .primaryColor
        
        // We want the colored background view to scroll with the content, but that view also
        // provides the color for the safe area/account picker background. This driver
        // makes the height grow when pulling down to refresh, and shrinks the height while
        // scrolling the content (but never shrinks it past the account picker)
        scrollView?.rx.contentOffset.asDriver()
            .distinctUntilChanged()
            .map { [weak self] offset in
                guard let self = self else { return colorBackgroundViewHeight }
                let minimumHeight = 0.0 // self.view.safeAreaInsets.top // + self.accountPicker.frame.size.height
                let heightMinusScrollOffset = colorBackgroundViewHeight - offset.y
                return max(minimumHeight, heightMinusScrollOffset)
            }
            .drive(colorBackgroundHeightConstraint.rx.constant)
            .disposed(by: bag)
    }
    
    func setCards(oldCards: [HomeCard], newCards: [HomeCard]) {
        Set(oldCards)
            .subtracting(newCards)
            .forEach { removeCardView(forCard: $0) }
        
        newCards
            .map(cardView)
            .enumerated()
            .forEach { index, view in
                cardStackView.insertArrangedSubview(view, at: index)
        }
    }
    
    func removeCardView(forCard card: HomeCard) {
        let view = cardView(forCard: card)
        cardStackView.removeArrangedSubview(view)
        view.removeFromSuperview()
        
        switch card {
        case.discover:
            discoverCardView = nil
        case .bill:
            billCardView = nil
        case .usage:
            usageCardView = nil
        case .projectedBill:
            projectedBillCardView = nil
        case .outageStatus:
            outageCardView = nil
        case .prepaidPending:
            prepaidPendingCardView = nil
        case .prepaidActive:
            prepaidActiveCardView = nil
        case .game:
            gameCardView = nil
        default:
            fatalError(card.displayString + " card view doesn't exist yet")
        }
    }
    
    func cardView(forCard card: HomeCard) -> UIView {
        switch card {
        case .discover:
            let discoverCardView: HomeDiscoverCardView
            if let discoverCard = self.discoverCardView {
                discoverCardView = discoverCard
            } else {
                discoverCardView = .create(withViewModel: viewModel.discoverCardViewModel)
                self.discoverCardView = discoverCardView
                bindDiscoverCard()
            }

            return discoverCardView
        case .bill:
            let billCardView: HomeBillCardView
            if let billCard = self.billCardView {
                billCardView = billCard
            } else {
                billCardView = .create(withViewModel: viewModel.billCardViewModel)
                self.billCardView = billCardView
                bindBillCard()
            }
            
            return billCardView
        case .usage:
            let usageCardView: HomeUsageCardView
            if let usageCard = self.usageCardView {
                usageCardView = usageCard
            } else {
                usageCardView = .create(withViewModel: viewModel.usageCardViewModel)
                self.usageCardView = usageCardView
                bindUsageCard()
            }
            
            return usageCardView
        case .projectedBill:
            let projectedBillCardView: HomeProjectedBillCardView
            if let projectedBillCard = self.projectedBillCardView {
                projectedBillCardView = projectedBillCard
            } else {
                projectedBillCardView = .create(withViewModel: viewModel.projectedBillCardViewModel)
                self.projectedBillCardView = projectedBillCardView
                bindProjectedBillCard()
            }
            return projectedBillCardView
        case .outageStatus:
            let outageCardView: HomeOutageCardView
            if let outageCard = self.outageCardView {
                outageCardView = outageCard
            } else {
                outageCardView = .create(withViewModel: viewModel.outageCardViewModel)
                self.outageCardView = outageCardView
                bindOutageCard()
            }
            
            return outageCardView
        case .prepaidPending:
            let prepaidPendingCardView: HomePrepaidCardView
            if let prepaidCard = self.prepaidPendingCardView {
                prepaidPendingCardView = prepaidCard
            } else {
                prepaidPendingCardView = .create(withViewModel: viewModel.prepaidPendingCardViewModel)
                self.prepaidPendingCardView = prepaidPendingCardView
            }
            
            return prepaidPendingCardView
        case .prepaidActive:
            let prepaidActiveCardView: HomePrepaidCardView
            if let prepaidCard = self.prepaidActiveCardView {
                prepaidActiveCardView = prepaidCard
            } else {
                prepaidActiveCardView = .create(withViewModel: viewModel.prepaidActiveCardViewModel)
                self.prepaidActiveCardView = prepaidActiveCardView
            }
            
            return prepaidActiveCardView
        case .game:
            let gameCardView: HomeGameCardView
            if let gameCard = self.gameCardView {
                gameCardView = gameCard
            } else {
                gameCardView = .create(withViewModel: viewModel.gameCardViewModel)
                gameCardView.lumiButton.rx.tap.subscribe(onNext: { _ in
                    NotificationCenter.default.post(name: .gameSwitchToGameView, object: nil)
                }).disposed(by: self.bag)
                self.gameCardView = gameCardView
            }
            
            return gameCardView
        default:
            fatalError(card.displayString + " card view doesn't exist yet")
        }
    }

    func bindDiscoverCard() {
        guard let discoverCardView = discoverCardView else { return }

//        discoverCardView.row2Button.rx.tap.asDriver().drive { [weak self] _ in
//            self?.present(viewController, animated: true, completion: nil)
//        }

        discoverCardView.helpViewController
            .drive(onNext: { [weak self] viewController in
                self?.present(viewController, animated: true, completion: nil)
            }).disposed(by: discoverCardView.disposeBag)

        discoverCardView.assistanceViewController
            .drive(onNext: { [weak self] viewController in
                self?.present(viewController, animated: true, completion: nil)
            }).disposed(by: discoverCardView.disposeBag)

        discoverCardView.energySavingsViewController
            .drive(onNext: { [weak self] viewController in
                self?.present(viewController, animated: true, completion: nil)
            }).disposed(by: discoverCardView.disposeBag)

        discoverCardView.energyWiseRewardsOfferViewController
            .drive(onNext: { [weak self] viewController in
                self?.present(viewController, animated: true, completion: nil)
            }).disposed(by: discoverCardView.disposeBag)

        discoverCardView.commercialViewController
            .drive(onNext: { [weak self] viewController in
                self?.present(viewController, animated: true, completion: nil)
            }).disposed(by: discoverCardView.disposeBag)

        discoverCardView.homeEnergyCheckupViewController
            .drive(onNext: { [weak self] viewController in
                self?.present(viewController, animated: true, completion: nil)
            }).disposed(by: discoverCardView.disposeBag)

        discoverCardView.alertPrefsViewController
            .drive(onNext: { [weak self] viewController in
                self?.navigationController?.present(viewController, animated: true)
            }).disposed(by: discoverCardView.disposeBag)

        discoverCardView.pushedViewControllers
            .drive(onNext: { [weak self] viewController in
                viewController.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(viewController, animated: true)
            }).disposed(by: discoverCardView.disposeBag)
    }
    
    func bindBillCard() {
        guard let billCardView = billCardView else { return }
        
        billCardView.oneTouchPayFinished
            .bind(to: viewModel.fetchData)
            .disposed(by: billCardView.bag)
        
        billCardView.viewBillPressed
            .drive(onNext: { [weak self] in
                self?.tabBarController?.selectedIndex = 1
            })
            .disposed(by: billCardView.bag)
        
        billCardView.modalViewControllers
            .drive(onNext: { [weak self] viewController in
                if viewController is SetDefaultPaymentMethodTutorialViewController {
                    let newNavController = LargeTitleNavigationController(rootViewController: viewController)
                    newNavController.modalPresentationStyle = .formSheet
                    self?.present(newNavController, animated: true, completion: nil)
                }  else if viewController is TapToPayReviewPaymentViewController ||
                    viewController is MakePaymentViewController {
                    self?.viewModel.makePaymentScheduledPaymentAlertInfo
                    .single()
                    .subscribe(onNext: { [weak self] alertInfo in
                            guard let self = self else { return }
                            let (titleOpt, messageOpt, _) = alertInfo
                            if let title = titleOpt, let message = messageOpt {
                                let alertVc = UIAlertController(title: title, message: message, preferredStyle: .alert)
                                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
                                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Continue", comment: ""), style: .default, handler: { _ in
                                    self.goToMakeAPaymentFlow(viewController: viewController)
                                }))
                                self.present(alertVc, animated: true, completion: nil)
                            } else {
                                self.goToMakeAPaymentFlow(viewController: viewController)
                            }
                        }).disposed(by: billCardView.bag)
                    
                } else if viewController is SFSafariViewController {
                    
                } else {
                    self?.present(viewController, animated: true, completion: nil)
                }
            })
            .disposed(by: billCardView.bag)
        
        billCardView.pushedViewControllers
            .drive(onNext: { [weak self] viewController in
                guard let self = self else { return }
                
                if let vc = viewController as? WalletViewController {
                    vc.didUpdate
                        .asDriver(onErrorDriveWith: .empty())
                        .delay(.milliseconds(500))
                        .drive(onNext: { [weak self] toastMessage in
                            self?.view.showToast(toastMessage)
                        })
                        .disposed(by: vc.disposeBag)
                } else if let vc = viewController as? AutoPayViewController {
                    vc.delegate = self
                } else if let vc = viewController as? BGEAutoPayViewController {
                    vc.delegate = self
                }
                
                viewController.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(viewController, animated: true)
            })
            .disposed(by: billCardView.bag)
    }
    
    func goToMakeAPaymentFlow(viewController: UIViewController?) {
        if let vc = viewController {
            let newNavController = LargeTitleNavigationController(rootViewController: vc)
            newNavController.modalPresentationStyle = .fullScreen
            FirebaseUtility.logEvent(.makePaymentStart)
            self.present(newNavController, animated: true, completion: nil)
        }
    }
    
    func bindUsageCard() {
        guard let usageCardView = usageCardView else { return }
        
        Driver.merge(usageCardView.viewUsageButton.rx.touchUpInside.asDriver(),
                     usageCardView.homeCardHeaderView.button.rx.touchUpInside.asDriver(),
                     usageCardView.viewCommercialUsageButton.rx.touchUpInside.asDriver())
            .withLatestFrom(viewModel.accountDetailEvents.elements().asDriver(onErrorDriveWith: .empty()))
            .drive(onNext: { [weak self] in
                let _ = String(format: "%@%@", $0.isResidential ? "Residential/" : "Commercial/", $0.isAMIAccount ? "AMI" : "Non-AMI")
                
                let _ = (Configuration.shared.opco == .bge && $0.isSERAccount) ||
                    (Configuration.shared.opco != .bge && $0.isPTSAccount)

                self?.tabBarController?.selectedIndex = 3
            })
            .disposed(by: usageCardView.disposeBag)
        
        usageCardView.viewAllSavingsButton.rx.touchUpInside.asDriver()
            .withLatestFrom(viewModel.usageCardViewModel.serResultEvents.elements().asDriver(onErrorDriveWith: .empty()))
            .drive(onNext: { [weak self] in
                self?.performSegue(withIdentifier: "totalSavingsSegue", sender: $0)
            }).disposed(by: usageCardView.disposeBag)
    }
    
    func bindProjectedBillCard() {
        guard let projectedBillCardView = projectedBillCardView else { return }
        
        viewModel.accountDetailEvents.elements().subscribe(onNext: { accountDetail in
            projectedBillCardView.isHidden = !accountDetail.isAMIAccount
        }).disposed(by: bag)

        Driver.merge(projectedBillCardView.callToActionButton.rx.touchUpInside.asDriver(),
                     projectedBillCardView.homeCardHeaderView.button.rx.touchUpInside.asDriver())
        .withLatestFrom(Driver.combineLatest(viewModel.projectedBillCardViewModel.isGas,
                                             viewModel.projectedBillCardViewModel.projectionNotAvailable))
        .drive(onNext: { [weak self] isGas, projectionNotAvailable in
            guard let tabBarCtl = self?.tabBarController as? MainTabBarController else {
                return
            }

            tabBarCtl.navigateToUsage(selectedBar: projectionNotAvailable ? .projectionNotAvailable : .projected,
                                      isGas: isGas,
                                      isPreviousBill: true)
        }).disposed(by: projectedBillCardView.disposeBag)
        
        projectedBillCardView.infoButton.rx.touchUpInside.asDriver().drive(onNext: { [weak self] in
            let alertViewController = InfoAlertController(title: NSLocalizedString("Estimated Amount", comment: ""),
                                                          message: NSLocalizedString("This is an estimate and the actual amount may vary based on your energy use, taxes, and fees.", comment: ""))
            self?.present(alertViewController, animated: true, completion: nil)
        }).disposed(by: projectedBillCardView.disposeBag)
    }
    
    func bindOutageCard() {
        guard let outageCardView = outageCardView else { return }
        
        outageCardView.reportOutageTapped
            .drive(onNext: { [weak self] outageStatus in
                self?.performSegue(withIdentifier: "reportOutageSegue", sender: outageStatus)
            })
            .disposed(by: outageCardView.bag)
        
        outageCardView.viewOutageMapTapped
            .drive(onNext: { [weak self] in
                self?.performSegue(withIdentifier: "outageMapSegue", sender: nil)
            })
            .disposed(by: outageCardView.bag)
    }
        
    @objc func setRefreshControlEnabled(enabled: Bool) {
        if enabled {
            scrollView!.alwaysBounceVertical = true
            
            guard refreshControl == nil else { return }
            
            refreshControl = UIRefreshControl()
            refreshControl!.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
            refreshControl?.tintColor = .white
            scrollView!.insertSubview(refreshControl!, at: 0)
        } else {
            if let rc = refreshControl {
                rc.endRefreshing()
                rc.removeFromSuperview()
                refreshControl = nil
            }
            scrollView!.alwaysBounceVertical = false
        }
    }
    
    @objc func onPullToRefresh() {
        viewModel.fetchData.onNext(())
        FeatureFlagUtility.shared.fetchCloudValues()
        UIAccessibility.post(notification: .screenChanged, argument: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            self.refreshControl?.endRefreshing()
        }
    }

    func bindLoadingStates() {
        viewModel.showNoNetworkConnectionState.not().drive(noNetworkConnectionView.rx.isHidden).disposed(by: bag)
        viewModel.showMaintenanceModeState.not().drive(maintenanceModeView.rx.isHidden).disposed(by: bag)
        
        Driver.combineLatest(viewModel.showNoNetworkConnectionState, viewModel.showMaintenanceModeState)
            { $0 || $1 }
            .drive(scrollView!.rx.isHidden).disposed(by: bag)
        
        /* Unlike the no network view, we can't simply hide the entire scrollView for FN-ACCT-DISALLOW
         * (because multi-account users need to be able to switch accounts). This creates some weirdness
         * because weatherView and importantUpdateView live outside of the scrollView, but this driver
         * handles all of that. */
        Driver.combineLatest(viewModel.showAccountDisallowState, viewModel.importantUpdate).drive(onNext: { [weak self] (showAcctDisallow, update) in
            self?.accountDisallowView.isHidden = !showAcctDisallow
            self?.contentStackView.isHidden = showAcctDisallow
            self?.importantUpdateView?.isHidden = showAcctDisallow
        }).disposed(by:bag)
        
        Observable.merge(maintenanceModeView.reload, noNetworkConnectionView.reload)
            .bind(to: viewModel.fetchData)
            .disposed(by: bag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.destination, sender) {
        case let (vc as AppointmentsViewController, (appointments) as ([Appointment])):
            vc.appointments = appointments
            vc.viewModel.appointments
                .skip(1) // First element just repeats the one passed in from this screen.
                .bind(to: viewModel.appointmentsUpdates)
                .disposed(by: vc.disposeBag)
        case let (vc as SERPTSViewController, accountDetail as AccountDetail):
            vc.accountDetail = accountDetail
        case let (vc as TotalSavingsViewController, eventResults as [SERResult]):
            vc.eventResults = eventResults
        case let (vc as BGEAutoPayViewController, accountDetail as AccountDetail):
             vc.delegate = self
             vc.accountDetail = accountDetail
         case let (vc as AutoPayViewController, accountDetail as AccountDetail):
             vc.delegate = self
             vc.accountDetail = accountDetail
        case let (vc as ReportOutageViewController, currentOutageStatus as OutageStatus):
            vc.viewModel.outageStatus = currentOutageStatus
            if let phone = currentOutageStatus.contactHomeNumber {
                vc.viewModel.phoneNumber.accept(phone)
            }
            
            // Show a toast only after an outage is reported from this workflow
            RxNotifications.shared.outageReported.asDriver(onErrorDriveWith: .empty())
                .drive(onNext: { [weak self] in
                    guard let this = self else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                        this.view.showToast(NSLocalizedString("Outage report received", comment: ""))
                    })
                })
                .disposed(by: vc.disposeBag)
        default:
            break
        }
    }
    
    func showPhoneNumberAlert() {
        presentAlert(title: NSLocalizedString("Update Phone Number", comment: ""),
            message: NSLocalizedString("The primary phone number we have for your account is (999) 999-9999. This can be used to verify your account. Would you like to update it?", comment: ""),
            style: .alert,
            actions: [
                UIAlertAction(title: NSLocalizedString("Update", comment: ""), style: .default) { action in
                    UIApplication.shared.openUrlIfCan(string: self.viewModel.contactPrefsWebUrl)
                },
                UIAlertAction(title: NSLocalizedString("Not Now", comment: ""), style: .cancel, handler: nil)
            ])
        
        UserDefaults.standard.setValue(Date.now, forKey: UserDefaultKeys.updatePhoneNumberReminderTimestamp)
    }
    
    func showMFAJustEnabled() {
        let twoSVEnabledAlert = InfoAlertController(title: NSLocalizedString("You are set up to use Two-Step Verification.", comment: ""),
                                                    message: NSLocalizedString("Two-Step Verification is now enabled. In the future, we'll notify you whenever someone attempts to log in to your account.", comment: ""),
                                                    icon: #imageLiteral(resourceName: "ic_confirmation_mini"))
        
        self.present(twoSVEnabledAlert, animated: true, completion: nil)
    }
    
    func showMFAReminder() {
        let action = InfoAlertAction(ctaText: NSLocalizedString("Enable Two-Step Verification", comment: "")) {
            self.tabBarController?.selectedIndex = 4
        }
        
        let alert = InfoAlertController(title: NSLocalizedString("Two-Step Verification is not enabled.", comment: ""),
                                        message: NSLocalizedString("To enable this feature or make changes, go to the more tab.", comment: ""),
                                        action: action,
                                        buttonType: .system)
        
        self.present(alert, animated: true, completion: nil)
    }
}

extension HomeViewController: AccountPickerDelegate {
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        // enable refresh control once accounts list loads
        setRefreshControlEnabled(enabled: true)
        viewModel.fetchData.onNext(())
        
        if FeatureFlagUtility.shared.bool(forKey: .isGamificationEnabled) {
            let gameAccountNumber = UserDefaults.standard.string(forKey: UserDefaultKeys.gameAccountNumber)
            let prefersGameHome = UserDefaults.standard.bool(forKey: UserDefaultKeys.prefersGameHome)
            let onboardingCompleteLocal = UserDefaults.standard.bool(forKey: UserDefaultKeys.gameOnboardingCompleteLocal)
            let optedOutLocal = UserDefaults.standard.bool(forKey: UserDefaultKeys.gameOptedOutLocal)
            
            if AccountsStore.shared.currentAccount.accountNumber == gameAccountNumber &&
                !optedOutLocal && onboardingCompleteLocal && UIDevice.current.userInterfaceIdiom != .pad {
                if prefersGameHome {
                    NotificationCenter.default.post(name: .gameSwitchToGameView, object: nil)
                }
            }
        }
    }
}

extension HomeViewController: AutoPayViewControllerDelegate {
    
    func autoPayViewController(_ autoPayViewController: UIViewController, enrolled: Bool) {
        let message = enrolled ? NSLocalizedString("Enrolled in AutoPay", comment: ""): NSLocalizedString("Unenrolled from AutoPay", comment: "")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(message)
        })
    }
    
}

extension HomeViewController: BGEAutoPayViewControllerDelegate {
    
    func BGEAutoPayViewController(_ BGEAutoPayViewController: BGEAutoPayViewController, didUpdateWithToastMessage message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(message)
        })
    }
    
}
