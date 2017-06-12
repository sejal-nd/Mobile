    //
//  SecurityQuestionListViewController.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ToastSwiftFramework

class SecurityQuestionListViewController: UITableViewController {
    
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
        
        self.tableView.register(UINib(nibName: "RadioSelectionTableViewCell", bundle: nil), forCellReuseIdentifier: "RadioSelectionCell")
        self.tableView.estimatedRowHeight = 51
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return viewableQuestions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RadioSelectionCell", for: indexPath) as! RadioSelectionTableViewCell

        let question = viewableQuestions[indexPath.row]
        
        // Configure the cell...
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
        
        _ = navigationController?.popViewController(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
