//
//  MoreViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/17/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

class MoreViewController: UIViewController, UINavigationBarDelegate {
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.delegate = self
        navigationController?.navigationBar.barTintColor = .primaryColor
        
        let titleDict: [String: Any] = [NSForegroundColorAttributeName: UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = titleDict
        navigationController?.navigationBar.barStyle = .black
        
        setNeedsStatusBarAppearanceUpdate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onLogOutPress(_ sender: Any) {
        let confirmAlert = UIAlertController(title: "Sign Out", message: "Are you sure you want to sign out?", preferredStyle: .alert)
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        confirmAlert.addAction(UIAlertAction(title: "Sign Out", style: .default, handler: logout))
        present(confirmAlert, animated: true, completion: nil)
    }
    
    func logout(action: UIAlertAction) {
        let authService = ServiceFactory.createAuthenticationService()
        authService.logout().subscribe(onNext: { (success) in
            let loginStoryboard = UIStoryboard(name: "Login", bundle: nil)
            let rootVC = loginStoryboard.instantiateInitialViewController()
            UIApplication.shared.keyWindow?.rootViewController = rootVC
        }, onError: { (error) in
            
        }, onCompleted: {
            
        }).addDisposableTo(disposeBag)
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
