//
//  AddressSearchViewController.swift
//  EUMobile
//
//  Created by Mithlesh Kumar on 24/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
protocol AddressSearchDelegate: AnyObject {
    func didSelectStreetAddress(result: String)
    func didSelectAppartment(result: AppartmentResponse)
}



class AddressSearchViewController: UIViewController {
    @IBOutlet weak var streetAddressTextField: FloatLabelTextField!
    @IBOutlet weak var streetAddressTooltipButton: UIButton!
    @IBOutlet weak var tableView: UITableView!

    public var zipcode :String?
    public var searchType :SearchType = SearchType.street
    public var listAppartment : [AppartmentResponse]?
    private var filter_listAppartment = [AppartmentResponse]()


    public weak var delegate: AddressSearchDelegate?

    let viewModel = AddressSearchModel()

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBackButton()
        if searchType == .appartment {
            title = "Select Apt/Unit #"

            if let list = listAppartment {
                filter_listAppartment = list
            }

        }else {
            title = "Select Street Address"
        }
        if let code = zipcode {
            viewModel.zipcode = code
        }
        tableViewSetup()
        textFieldSetup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadTableView()
    }
    private func navigationBackButton() {
           self.navigationItem.hidesBackButton = true
           let newBackButton = UIBarButtonItem(image: UIImage(named: "ic_back"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(AddressSearchViewController.back(sender:)))
           self.navigationItem.leftBarButtonItem = newBackButton
       }
       @objc func back(sender: UIBarButtonItem) {
           self.navigationController?.popViewController(animated: true)
       }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    private func tableViewSetup() {
        tableView.isHidden = true
        tableView.tableFooterView = UIView() // Hides extra separators
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
    }
    private func textFieldSetup() {
        streetAddressTextField.textField.autocorrectionType = .no
        streetAddressTextField.textField.returnKeyType = .done
        streetAddressTextField.textField.keyboardType = .default
        streetAddressTextField.textField.textContentType = .fullStreetAddress

         if searchType == .appartment {
            streetAddressTextField.placeholder = NSLocalizedString("Apt/Unit #*", comment: "")
        }else {
            streetAddressTextField.placeholder = NSLocalizedString("Street Address*", comment: "")
        }

        streetAddressTooltipButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")

        streetAddressTextField.textField.rx.controlEvent(.editingDidEnd).asObservable()
            .filter{ self.searchType == .street}
            .debounce(.milliseconds(500), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.address = self.streetAddressTextField.textField.text!
                //API Call
                self.viewModel.searchAaddress()
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] result in
                        guard let `self` = self else {return }
                        self.viewModel.listStreetAddress = result.data
                        self.reloadTableView()
                    }).disposed(by: self.disposeBag)

            }).disposed(by: disposeBag)


        streetAddressTextField.textField.rx.controlEvent(.editingChanged).asObservable()
            .filter{ self.searchType == .appartment}
            .debounce(.milliseconds(500), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }

                if let list = self.listAppartment , let searchString =  self.streetAddressTextField.textField.text{
                    self.filter_listAppartment = list.filter({ appartment in
                        if let suite = appartment.suiteNumber , suite.localizedCaseInsensitiveContains(searchString){
                            return true
                        }
                        return false
                    })
                    self.reloadTableView()
                }

            }).disposed(by: disposeBag)

    }

    @IBAction func onStreetAddressTooltipPress() {
        let alert = InfoAlertController(title: NSLocalizedString("Can't find your address?", comment: ""),
                                        message: NSLocalizedString("Try abbreviations for:\r\nDirectional prefixes (N, S, E, W)\r\nStreet suffixes (ST, CT, PD, AVE, DR) \r\nOr just enter your street number and name.", comment: ""))

        self.navigationController?.present(alert, animated: true, completion: nil)
    }

    private func reloadTableView(){
        if (tableView.isHidden){
            tableView.isHidden = false
        }
        tableView.reloadData()
    }
}


// MARK: TableView Methods
extension AddressSearchViewController: UITableViewDelegate ,UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchType == .appartment{
            return filter_listAppartment.count
        }
        return  viewModel.listStreetAddress.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddressSearchCell", for: indexPath) as! AddressSearchCell

        if searchType == .appartment{
            let appartment = filter_listAppartment[indexPath.row]
            cell.titleLabel.text = appartment.suiteNumber
        }else {
            let streetAdd = viewModel.findStreetAddress(at: indexPath.row)
            cell.titleLabel.text = streetAdd
        }


        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searchType == .appartment{
            let appartment = filter_listAppartment[indexPath.row]
            self.delegate?.didSelectAppartment(result: appartment)
        }else {
            let streetAdd = viewModel.findStreetAddress(at: indexPath.row)
            self.delegate?.didSelectStreetAddress(result: streetAdd)
        }
        self.navigationController?.popViewController(animated: true)
    }
}


