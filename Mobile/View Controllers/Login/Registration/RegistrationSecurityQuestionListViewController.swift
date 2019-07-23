//
//  SecurityQuestionListViewController.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class RegistrationSecurityQuestionListViewController: UITableViewController {
    
    var viewModel: RegistrationViewModel!
    
    var viewableQuestions: [String]!
    
    var questionNumber: Int! // Passed from RegistrationSecuriyQuestionsViewController
    
    //var previouslySelectedQuestion: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addCloseButton()

        title = NSLocalizedString("Select Question", comment: "")
        
//        if viewableQuestions.count > 0 {
//            viewableQuestions.removeAll()
//        }
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

    // MARK: - Table view data source

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
        // do stuff here to identify the question selected, and pop back out to the question/answer view controller
        let question = viewableQuestions[indexPath.row]
        
//        for question in viewModel.securityQuestions.value {
//            if question.securityQuestion == securityQuestion {
//                question.selected = true
//            } else {
//                if let previouslySelectedQuestion = previouslySelectedQuestion,
//                    previouslySelectedQuestion == question.securityQuestion {
//                    //
//                    question.selected = false
//                    viewModel.selectedQuestionChanged.value = true
//                }
//            }
//        }
        if questionNumber == 1 {
            viewModel.securityQuestion1.value = question
        } else if questionNumber == 2 {
            viewModel.securityQuestion2.value = question
        } else if questionNumber == 3 {
            viewModel.securityQuestion3.value = question
        }
        
        //navigationController?.popViewController(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

}
