//
//  ViewController.swift
//  CoreDataMnager
//
//  Created by Sergey on 11/21/18.
//  Copyright © 2018 sblinov.com. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    @IBOutlet weak var addUserButton: UIButton! {
        didSet {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: addUserButton)
        }
    }
    
    @IBAction func addUserAction(_ sender: Any) {
        
        CoreDataManager.shared.save({
            let user = User.createEntity()
            user?.bdate = Date()
            user?.name = String.random(length: 25)
            
        }) { [weak self] status in
            self?.tableView.reloadData()
        }
    }
    
    var users: [User]? {
        return User.all()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        User.deleteAll { _ in
            self.tableView.reloadData()
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? TableViewCell else { return UITableViewCell() }
        guard let item = users?[indexPath.row] else { return UITableViewCell() }
        cell.titleLabel.text = item.name
        cell.detailLabel.text = item.bdate?.toString()
        
        return cell
    }
}
