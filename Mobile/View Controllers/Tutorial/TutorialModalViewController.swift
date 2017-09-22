//
// Created by James Landrum on 9/21/17.
// Copyright (c) 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class TutorialModalViewController: DismissableFormSheetViewController {
    @IBOutlet weak var pagerContent: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var rootView: UIView!
    @IBOutlet var templateView: UIView!
    
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        addView()
        addView()
        addView()
    }
    
    func addView() {
        let viewCopy = NSKeyedUnarchiver.unarchiveObject(with:
            NSKeyedArchiver .archivedData(withRootObject: templateView)) as! UIView;
        viewCopy.widthAnchor.constraint(equalToConstant: scrollView.frame.width).isActive = true
        pagerContent.addArrangedSubview(viewCopy)
        scrollView.contentSize = pagerContent.frame.size
    }

    @IBAction func xAction(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    @IBAction func onClose(_ sender: Any) {
        dismiss(animated: true)
    }
    
    deinit {
        dLog()
    }

}
