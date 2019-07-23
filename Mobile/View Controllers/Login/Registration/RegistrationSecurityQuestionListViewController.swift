//
//  SecurityQuestionListViewController.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class RegistrationSecurityQuestionListViewController: UITableViewController {
    
    // Passed from RegistrationSecuriyQuestionsViewController
    var viewModel: RegistrationViewModel!
    var questionNumber: Int!
    
    var viewableQuestions: [String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addCloseButton()

        title = NSLocalizedString("Select Question", comment: "")

        let questions = viewModel.securityQuestions!
        viewableQuestions = questions.filter({ question -> Bool in
            if questionNumber == 1 {
                return question != viewModel.securityQuestion2.value && question != viewModel.securityQuestion3.value
            } else if questionNumber == 2 {
                return question != viewModel.securityQuestion1.value && question != viewModel.securityQuestion3.value
            } else if questionNumber == 3 {
                return question != viewModel.securityQuestion1.value && question != viewModel.securityQuestion2.value
            }
            return false
        })
        
        tableView.register(UINib(nibName: "RadioSelectionTableViewCell", bundle: nil), forCellReuseIdentifier: "RadioSelectionCell")
        tableView.estimatedRowHeight = 51
    }

    // MARK: - TableView Delegate/DataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewableQuestions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RadioSelectionCell", for: indexPath) as! RadioSelectionTableViewCell

        let question = viewableQuestions[indexPath.row]
        
        cell.label.text = question
        
        if (questionNumber == 1 && viewModel.securityQuestion1.value == question) ||
            (questionNumber == 2 && viewModel.securityQuestion2.value == question) ||
            (questionNumber == 3 && viewModel.securityQuestion3.value == question) {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let question = viewableQuestions[indexPath.row]
        
        if questionNumber == 1 {
            viewModel.securityQuestion1.value = question
        } else if questionNumber == 2 {
            viewModel.securityQuestion2.value = question
        } else if questionNumber == 3 {
            viewModel.securityQuestion3.value = question
        }
        
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

}
