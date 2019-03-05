//
//  ViewControllerAlertable.Swift
//  BGE
//
//  Created by Joseph Erlandson on 7/6/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func presentAlert(title: String?, message: String?, style: UIAlertController.Style, actions: [UIAlertAction]) {
        var alertController = UIAlertController()
        
        // Force iPad's to only show Alert Style (Does not support Action Sheets)
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        } else {
            alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        }

        for action in actions {
            alertController.addAction(action)
        }

        present(alertController, animated: true, completion: nil)
    }
    
}
