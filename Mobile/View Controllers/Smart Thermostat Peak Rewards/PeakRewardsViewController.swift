//
//  PeakRewardsViewController.swift
//  Mobile
//
//  Created by Sam Francis on 11/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class PeakRewardsViewController: UIViewController {
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var mainErrorLabel: UILabel!
    @IBOutlet weak var mainLoadingIndicator: LoadingIndicator!
    
    @IBOutlet weak var deviceButton: DisclosureButton!
    
    @IBOutlet weak var programCardStack: UIStackView!
    
    @IBOutlet weak var segmentedControl: SegmentedControl!
    
    @IBOutlet weak var scheduleContentStack: UIStackView!
    @IBOutlet weak var scheduleErrorView: UIView!
    @IBOutlet weak var scheduleLoadingView: UIView!
    let gradientLayer = CAGradientLayer()
    
    var accountDetail: AccountDetail!
    
    let disposeBag = DisposeBag()
    
    private lazy var viewModel: PeakRewardsViewModel = PeakRewardsViewModel(peakRewardsService: ServiceFactory.createPeakRewardsService(), accountDetail: self.accountDetail)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleViews()
        bindViews()
    }
    
    func styleViews() {
        gradientLayer.frame = gradientView.bounds
        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor(red: 244/255, green: 245/255, blue: 246/255, alpha: 1).cgColor,
            UIColor(red: 239/255, green: 241/255, blue: 243/255, alpha: 1).cgColor
        ]
        gradientView.layer.addSublayer(gradientLayer)
        
        segmentedControl.items = [NSLocalizedString("F°", comment: ""), NSLocalizedString("C°", comment: "")]
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientView.frame = gradientView.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        gradientLayer.frame = gradientView.bounds
    }
    
    func bindViews() {
        viewModel.showMainLoadingState.asDriver().not().drive(mainLoadingIndicator.rx.isHidden).disposed(by: disposeBag)
        viewModel.showMainErrorState.asDriver().not().drive(mainErrorLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.showMainContent.asDriver().not().drive(scrollView.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.showScheduleLoadingState.asDriver().not().drive(scheduleLoadingView.rx.isHidden).disposed(by: disposeBag)
        viewModel.showScheduleErrorState.asDriver().not().drive(scheduleErrorView.rx.isHidden).disposed(by: disposeBag)
        viewModel.showScheduleContent.asDriver().not().drive(scheduleContentStack.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.peakRewardsPrograms
            .drive(onNext: { [weak self] programs in
                guard let `self` = self else { return }
                
                for (index, programCard) in self.programCardStack.arrangedSubviews.enumerated() {
                    guard index != 0 else { continue } // Don't remove the header label from the stack
                    self.programCardStack.removeArrangedSubview(programCard)
                }
                
                programs
                    .map(PeakRewardsProgramCard.init)
                    .forEach(self.programCardStack.addArrangedSubview)
            })
            .disposed(by: disposeBag)
//        segmentedControl.selectedIndex.asDriver()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}
