    //
//  SecurityQuestionListViewController.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import Toast_Swift

class RegistrationSecurityQuestionListViewController: UITableViewController {
    
    var viewModel: RegistrationViewModel!
    var viewableQuestions = [SecurityQuestion]()
    
    var previouslySelectedQuestion: String!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Select Question", comment: "")
        
        if viewableQuestions.count > 0 {
            viewableQuestions.removeAll()
        }
        
        for question in viewModel.securityQuestions.value {
            if question.selected {
                if question.securityQuestion == viewModel.selectedQuestion {
                    viewableQuestions.append(question)
                }
                
                continue
            }
            
            viewableQuestions.append(question)
        }
        
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
        
        cell.label.text = question.securityQuestion
        
        if question.selected {
            previouslySelectedQuestion = question.securityQuestion

            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // do stuff here to identify the question selected, and pop back out to the question/answer view controller
        let securityQuestion = viewableQuestions[indexPath.row].securityQuestion
        
        for question in viewModel.securityQuestions.value {
            if question.securityQuestion == securityQuestion {
                question.selected = true
            } else {
                if let previouslySelectedQuestion = previouslySelectedQuestion,
                    previouslySelectedQuestion == question.securityQuestion {
                    //
                    question.selected = false
                    viewModel.selectedQuestionChanged.value = true
                }
            }
        }
        
        switch(viewModel.selectedQuestionRow) {
        case 1:
            viewModel.securityQuestion1.value = securityQuestion
        case 2:
            viewModel.securityQuestion2.value = securityQuestion
        case 3:
            viewModel.securityQuestion3.value = securityQuestion
        default:
            viewModel.securityQuestion1.value = securityQuestion
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

}
